import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

// ---------------------------------------------------------------------------
// ShowRealName — in-memory toggle (persisted to Firestore in v2)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class ShowRealNameNotifier extends _$ShowRealNameNotifier {
  @override
  bool build() => false;

  /// Initialize from user profile data (called when SettingsScreen loads).
  void init(bool value) => state = value;

  void toggle(bool value) => state = value;
}
