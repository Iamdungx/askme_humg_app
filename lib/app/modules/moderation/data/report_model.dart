import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';

part 'report_model.freezed.dart';

@freezed
abstract class ReportModel with _$ReportModel {
  const factory ReportModel({
    required String reportId,
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String status,
    required DateTime createdAt,
    @Default('') String content,
    DateTime? resolvedAt,
    String? parentAnswerId,
  }) = _ReportModel;

  factory ReportModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAtTs = data['createdAt'] as Timestamp?;
    final resolvedAtTs = data['resolvedAt'] as Timestamp?;

    return ReportModel(
      reportId: doc.id,
      targetId: data['targetId'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      reportedBy: data['reportedBy'] as String? ?? '',
      reason: data['reason'] as String? ?? 'other',
      status: data['status'] as String? ?? 'pending',
      createdAt: createdAtTs?.toDate() ?? DateTime.now(),
      content: data['content'] as String? ?? '',
      resolvedAt: resolvedAtTs?.toDate(),
      parentAnswerId: data['parentAnswerId'] as String?,
    );
  }
}

extension ReportModelX on ReportModel {
  Report toDomain() => Report(
        reportId: reportId,
        targetId: targetId,
        targetType: targetType,
        reportedBy: reportedBy,
        reason: reason,
        status: status,
        createdAt: createdAt,
        content: content,
        resolvedAt: resolvedAt,
        parentAnswerId: parentAnswerId,
      );
}
