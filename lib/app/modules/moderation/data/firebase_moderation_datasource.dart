import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/moderation/data/report_model.dart';
import 'package:askme_humg/app/modules/moderation/domain/i_moderation_repository.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';

class FirebaseModerationDatasource {
  FirebaseModerationDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> submitReport({
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String content,
    String? parentAnswerId,
  }) async {
    try {
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
          batch.update(_firestore.collection('answers').doc(parentAnswerId), {
            'commentCount': FieldValue.increment(-1),
          });
        }
      }

      await batch.commit();
    } on FirebaseException catch (e, s) {
      logger.e('resolveReport failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore error');
    }
  }
}
