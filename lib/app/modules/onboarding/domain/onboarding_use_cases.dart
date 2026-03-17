import 'package:askme_humg/app/modules/onboarding/domain/i_onboarding_repository.dart';
import 'package:askme_humg/app/modules/onboarding/domain/onboarding.dart';

class GetOnboardingProgress {
  const GetOnboardingProgress(this._repo);
  final IOnboardingRepository _repo;

  OnboardingProgress call() => _repo.getProgress();
}

class SetOnboardingCompleted {
  const SetOnboardingCompleted(this._repo);
  final IOnboardingRepository _repo;

  Future<void> call(bool value) => _repo.setCompleted(value);
}

class SetHintSeen {
  const SetHintSeen(this._repo);
  final IOnboardingRepository _repo;

  Future<void> call(OnboardingHint hint, bool value) =>
      _repo.setHintSeen(hint, value);
}

class GetDemoMode {
  const GetDemoMode(this._repo);
  final IOnboardingRepository _repo;

  bool call() => _repo.getDemoMode();
}

class SetDemoMode {
  const SetDemoMode(this._repo);
  final IOnboardingRepository _repo;

  Future<void> call(bool value) => _repo.setDemoMode(value);
}

