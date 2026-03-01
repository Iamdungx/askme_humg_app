import 'package:askme_humg/app/modules/moderation/domain/report.dart';

enum ResolveAction { remove, dismiss }

abstract interface class IModerationRepository {
  Future<void> submitReport({
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String content,
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
