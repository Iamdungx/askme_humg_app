import 'package:shared_preferences/shared_preferences.dart';
import 'package:askme_humg/app/modules/onboarding/domain/onboarding.dart';

const _kOnboardingCompletedKey = 'onboarding_completed';
const _kDemoModeKey = 'demo_mode';

class PrefsOnboardingDatasource {
  PrefsOnboardingDatasource({required SharedPreferences prefs})
    : _prefs = prefs;

  final SharedPreferences _prefs;

  OnboardingProgress getProgress() => OnboardingProgress(
    completed: _prefs.getBool(_kOnboardingCompletedKey) ?? false,
    hintFeedSeen: _prefs.getBool(OnboardingHint.feed.storageKey) ?? false,
    hintInboxSeen: _prefs.getBool(OnboardingHint.inbox.storageKey) ?? false,
    hintProfileSeen: _prefs.getBool(OnboardingHint.profile.storageKey) ?? false,
    hintSettingsSeen:
        _prefs.getBool(OnboardingHint.settings.storageKey) ?? false,
  );

  bool getDemoMode() => _prefs.getBool(_kDemoModeKey) ?? false;

  Future<void> setCompleted(bool value) =>
      _prefs.setBool(_kOnboardingCompletedKey, value);

  Future<void> setHintSeen(OnboardingHint hint, bool value) =>
      _prefs.setBool(hint.storageKey, value);

  Future<void> setDemoMode(bool value) => _prefs.setBool(_kDemoModeKey, value);
}
