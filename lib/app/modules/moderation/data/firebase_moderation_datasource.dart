import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/answer_hot_score.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/moderation/data/report_model.dart';
import 'package:askme_humg/app/modules/moderation/domain/i_moderation_repository.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';

class FirebaseModerationDatasource {
  FirebaseModerationDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<bool> hasUserReportedTarget({
    required String reportedBy,
    required String targetId,
    required String targetType,
  }) async {
    try {
      final snap = await _firestore
          .collection('reports')
          .where('reportedBy', isEqualTo: reportedBy)
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } on FirebaseException catch (e, s) {
      logger.e('hasUserReportedTarget failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore error');
    }
  }

  Future<void> submitReport({
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String content,
    String? parentAnswerId,
  }) async {
    try {
      final dup = await hasUserReportedTarget(
        reportedBy: reportedBy,
        targetId: targetId,
        targetType: targetType,
      );
      if (dup) {
        throw const DuplicateReportException();
      }

      await _firestore.collection('reports').add({
        'targetId': targetId,
        'targetType': targetType,
        'reportedBy': reportedBy,
        'reason': reason,
        'content': content,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'parentAnswerId': parentAnswerId,
      });
    } on DuplicateReportException {
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e('submitReport failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore error');
    }
  }

  Stream<List<Report>> getPendingReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ReportModel.fromFirestore(doc).toDomain())
              .toList(),
        );
  }

  Future<void> resolveReport({
    required String reportId,
    required String targetId,
    required String targetType,
    required ResolveAction action,
    String? parentAnswerId,
  }) async {
    try {
      if (action == ResolveAction.dismiss) {
        await _firestore.collection('reports').doc(reportId).update({
          'status': 'resolved_dismissed',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final batch = _firestore.batch();

      batch.update(_firestore.collection('reports').doc(reportId), {
        'status': 'resolved_removed',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (targetType == 'answer') {
        batch.update(_firestore.collection('answers').doc(targetId), {
          'isPublished': false,
        });
      } else if (targetType == 'comment') {
        batch.delete(_firestore.collection('comments').doc(targetId));
        if (parentAnswerId != null) {
          final parentRef = _firestore.collection('answers').doc(parentAnswerId);
          final parentSnap = await parentRef.get();
          if (parentSnap.exists && parentSnap.data() != null) {
            final pd = parentSnap.data()!;
            final prevCc = pd['commentCount'] as int? ?? 0;
            final newCc = prevCc > 0 ? prevCc - 1 : 0;
            final lc = pd['likeCount'] as int? ?? 0;
            final createdAtTs = pd['createdAt'] as Timestamp?;
            final decUpdate = <String, dynamic>{'commentCount': newCc};
            if (createdAtTs != null) {
              decUpdate['hotScore'] = computeAnswerHotScore(
                likeCount: lc,
                commentCount: newCc,
                createdAt: createdAtTs.toDate(),
              );
            }
            batch.update(parentRef, decUpdate);
          }
        }
      }

      await batch.commit();
    } on FirebaseException catch (e, s) {
      logger.e('resolveReport failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore error');
    }
  }
}
