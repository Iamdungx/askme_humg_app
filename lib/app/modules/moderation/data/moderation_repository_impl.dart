import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/modules/moderation/data/firebase_moderation_datasource.dart';
import 'package:askme_humg/app/modules/moderation/domain/i_moderation_repository.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';

class ModerationRepositoryImpl implements IModerationRepository {
  ModerationRepositoryImpl(this._datasource);
  final FirebaseModerationDatasource _datasource;

  @override
  Future<void> submitReport({
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String content,
    String? parentAnswerId,
  }) async {
    try {
      await _datasource.submitReport(
        targetId: targetId,
        targetType: targetType,
        reportedBy: reportedBy,
        reason: reason,
        content: content,
        parentAnswerId: parentAnswerId,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Stream<List<Report>> getPendingReports() =>
      _datasource.getPendingReports().handleError((Object e) {
        if (e is FirestoreException) throw FirestoreFailure(e.message);
        if (e is AppException) throw UnknownFailure(e.message);
        throw UnknownFailure(e.toString());
      });

  @override
  Future<void> resolveReport({
    required String reportId,
    required String targetId,
    required String targetType,
    required ResolveAction action,
    String? parentAnswerId,
  }) async {
    try {
      await _datasource.resolveReport(
        reportId: reportId,
        targetId: targetId,
        targetType: targetType,
        action: action,
        parentAnswerId: parentAnswerId,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
