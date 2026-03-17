import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';
import 'package:askme_humg/app/modules/onboarding/data/onboarding_repository_impl.dart';
import 'package:askme_humg/app/modules/onboarding/data/prefs_onboarding_datasource.dart';
import 'package:askme_humg/app/modules/onboarding/domain/i_onboarding_repository.dart';
import 'package:askme_humg/app/modules/onboarding/domain/onboarding.dart';
import 'package:askme_humg/app/modules/onboarding/domain/onboarding_use_cases.dart';

part 'onboarding_providers.g.dart';

@riverpod
PrefsOnboardingDatasource onboardingDatasource(Ref ref) =>
    PrefsOnboardingDatasource(prefs: ref.watch(sharedPreferencesProvider));

@riverpod
IOnboardingRepository onboardingRepository(Ref ref) =>
    OnboardingRepositoryImpl(ref.watch(onboardingDatasourceProvider));

@riverpod
GetOnboardingProgress getOnboardingProgressUseCase(Ref ref) =>
    GetOnboardingProgress(ref.watch(onboardingRepositoryProvider));

@riverpod
SetOnboardingCompleted setOnboardingCompletedUseCase(Ref ref) =>
    SetOnboardingCompleted(ref.watch(onboardingRepositoryProvider));

@riverpod
SetHintSeen setHintSeenUseCase(Ref ref) =>
    SetHintSeen(ref.watch(onboardingRepositoryProvider));

@riverpod
GetDemoMode getDemoModeUseCase(Ref ref) =>
    GetDemoMode(ref.watch(onboardingRepositoryProvider));

@riverpod
SetDemoMode setDemoModeUseCase(Ref ref) =>
    SetDemoMode(ref.watch(onboardingRepositoryProvider));

@Riverpod(keepAlive: true)
class OnboardingCompletedNotifier extends _$OnboardingCompletedNotifier {
  @override
  bool build() => ref.watch(getOnboardingProgressUseCaseProvider).call().completed;

  Future<void> complete() async {
    state = true;
    await ref.read(setOnboardingCompletedUseCaseProvider).call(true);
  }
}

@Riverpod(keepAlive: true)
class DemoModeNotifier extends _$DemoModeNotifier {
  @override
  bool build() => ref.watch(getDemoModeUseCaseProvider).call();

  Future<void> set(bool value) async {
    state = value;
    await ref.read(setDemoModeUseCaseProvider).call(value);
  }
}

@riverpod
class HintSeen extends _$HintSeen {
  @override
  bool build(OnboardingHint hint) =>
      ref.watch(getOnboardingProgressUseCaseProvider).call().isHintSeen(hint);

  Future<void> markSeen() async {
    state = true;
    await ref.read(setHintSeenUseCaseProvider).call(hint, true);
  }
}

