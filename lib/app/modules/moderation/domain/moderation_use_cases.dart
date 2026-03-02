import 'package:askme_humg/app/modules/moderation/domain/i_moderation_repository.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';

class SubmitReport {
  const SubmitReport(this._repo);
  final IModerationRepository _repo;

  Future<void> call({
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String content,
    String? parentAnswerId,
  }) =>
      _repo.submitReport(
        targetId: targetId,
        targetType: targetType,
        reportedBy: reportedBy,
        reason: reason,
        content: content,
        parentAnswerId: parentAnswerId,
      );
}

class GetPendingReports {
  const GetPendingReports(this._repo);
  final IModerationRepository _repo;

  Stream<List<Report>> call() => _repo.getPendingReports();
}

class ResolveReport {
  const ResolveReport(this._repo);
  final IModerationRepository _repo;

  Future<void> call({
    required String reportId,
    required String targetId,
    required String targetType,
    required ResolveAction action,
    String? parentAnswerId,
  }) =>
      _repo.resolveReport(
        reportId: reportId,
        targetId: targetId,
        targetType: targetType,
        action: action,
        parentAnswerId: parentAnswerId,
      );
}
