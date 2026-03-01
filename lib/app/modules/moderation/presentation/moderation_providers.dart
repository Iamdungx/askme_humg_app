import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/moderation/data/firebase_moderation_datasource.dart';
import 'package:askme_humg/app/modules/moderation/data/moderation_repository_impl.dart';
import 'package:askme_humg/app/modules/moderation/domain/i_moderation_repository.dart';
import 'package:askme_humg/app/modules/moderation/domain/moderation_use_cases.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';

part 'moderation_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

@riverpod
FirebaseModerationDatasource moderationDatasource(Ref ref) =>
    FirebaseModerationDatasource(firestore: ref.watch(firestoreProvider));

@riverpod
IModerationRepository moderationRepository(Ref ref) =>
    ModerationRepositoryImpl(ref.watch(moderationDatasourceProvider));

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

@riverpod
SubmitReport submitReportUseCase(Ref ref) =>
    SubmitReport(ref.watch(moderationRepositoryProvider));

@riverpod
GetPendingReports getPendingReportsUseCase(Ref ref) =>
    GetPendingReports(ref.watch(moderationRepositoryProvider));

@riverpod
ResolveReport resolveReportUseCase(Ref ref) =>
    ResolveReport(ref.watch(moderationRepositoryProvider));

// ---------------------------------------------------------------------------
// Stream provider — pending reports list
// ---------------------------------------------------------------------------

@riverpod
Stream<List<Report>> pendingReports(Ref ref) =>
    ref.watch(getPendingReportsUseCaseProvider).call();

// ---------------------------------------------------------------------------
// Report notifier — UC-5.1 submit report
// ---------------------------------------------------------------------------

@riverpod
class ReportNotifier extends _$ReportNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String targetId,
    required String targetType,
    required String reason,
    required String content,
  }) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(submitReportUseCaseProvider).call(
            targetId: targetId,
            targetType: targetType,
            reportedBy: uid,
            reason: reason,
            content: content,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resolve report notifier — UC-5.2 admin moderate
// Each report card has its own notifier (parameterized) to avoid blocking
// the entire list when one card is loading.
// ---------------------------------------------------------------------------

@riverpod
class ResolveReportNotifier extends _$ResolveReportNotifier {
  @override
  FutureOr<void> build(String reportId) {}

  Future<void> resolve({
    required String targetId,
    required String targetType,
    required ResolveAction action,
    String? parentAnswerId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(resolveReportUseCaseProvider).call(
            reportId: reportId,
            targetId: targetId,
            targetType: targetType,
            action: action,
            parentAnswerId: parentAnswerId,
          ),
    );
  }
}
