import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding.freezed.dart';

enum OnboardingHint {
  feed,
  inbox,
  profile,
  settings,
}

extension OnboardingHintX on OnboardingHint {
  String get storageKey => switch (this) {
    OnboardingHint.feed => 'hint_feed_seen',
    OnboardingHint.inbox => 'hint_inbox_seen',
    OnboardingHint.profile => 'hint_profile_seen',
    OnboardingHint.settings => 'hint_settings_seen',
  };
}

@freezed
abstract class OnboardingProgress with _$OnboardingProgress {
  const factory OnboardingProgress({
    @Default(false) bool completed,
    @Default(false) bool hintFeedSeen,
    @Default(false) bool hintInboxSeen,
    @Default(false) bool hintProfileSeen,
    @Default(false) bool hintSettingsSeen,
  }) = _OnboardingProgress;
}

extension OnboardingProgressX on OnboardingProgress {
  bool isHintSeen(OnboardingHint hint) => switch (hint) {
    OnboardingHint.feed => hintFeedSeen,
    OnboardingHint.inbox => hintInboxSeen,
    OnboardingHint.profile => hintProfileSeen,
    OnboardingHint.settings => hintSettingsSeen,
  };
}

