import 'package:askme_humg/app/modules/onboarding/data/prefs_onboarding_datasource.dart';
import 'package:askme_humg/app/modules/onboarding/domain/i_onboarding_repository.dart';
import 'package:askme_humg/app/modules/onboarding/domain/onboarding.dart';

class OnboardingRepositoryImpl implements IOnboardingRepository {
  OnboardingRepositoryImpl(this._ds);
  final PrefsOnboardingDatasource _ds;

  @override
  OnboardingProgress getProgress() => _ds.getProgress();

  @override
  bool getDemoMode() => _ds.getDemoMode();

  @override
  Future<void> setCompleted(bool value) => _ds.setCompleted(value);

  @override
  Future<void> setHintSeen(OnboardingHint hint, bool value) =>
      _ds.setHintSeen(hint, value);

  @override
  Future<void> setDemoMode(bool value) => _ds.setDemoMode(value);
}

