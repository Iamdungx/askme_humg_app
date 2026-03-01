import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:askme_humg/l10n/app_localizations.dart';

extension BuildContextX on BuildContext {
  /// Formats [date] as a relative time string using the current locale.
  /// e.g. "3 minutes ago", "2 giờ trước"
  String timeAgo(DateTime date) => timeago.format(
        date,
        locale: Localizations.localeOf(this).languageCode,
      );

  /// Shows a snackbar and returns false if [uid] is null (user not logged in).
  /// Returns true if the user is authenticated — caller can proceed.
  bool requireAuth(String? uid, String loginMessage) {
    if (uid != null) return true;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(loginMessage)),
    );
    return false;
  }

  /// Shorthand for [AppLocalizations.of(context)].
  AppLocalizations get l10n => AppLocalizations.of(this);
}
