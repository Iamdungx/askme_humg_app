import 'package:askme_humg/app/modules/onboarding/domain/onboarding.dart';

abstract class IOnboardingRepository {
  OnboardingProgress getProgress();
  bool getDemoMode();
  Future<void> setCompleted(bool value);
  Future<void> setHintSeen(OnboardingHint hint, bool value);
  Future<void> setDemoMode(bool value);
}

