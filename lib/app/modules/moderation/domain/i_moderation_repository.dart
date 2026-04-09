import 'package:askme_humg/app/modules/moderation/domain/report.dart';

enum ResolveAction { remove, dismiss }

abstract interface class IModerationRepository {
  /// UC-5.1 — true if this user already has any report for the same target.
  Future<bool> hasUserReportedTarget({
    required String reportedBy,
    required String targetId,
    required String targetType,
  });

  Future<void> submitReport({
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String content,
    String? parentAnswerId,
  });

  Stream<List<Report>> getPendingReports();

  Future<void> resolveReport({
    required String reportId,
    required String targetId,
    required String targetType,
    required ResolveAction action,
    String? parentAnswerId,
  });
}
