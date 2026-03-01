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

  /// Returns false (showing a snackbar) if the user is not logged in OR
  /// is logged in but has not completed HUMG verification.
  /// [isVerified] should be `authUser?.isHumgVerified == true`.
  bool requireVerified({
    required String? uid,
    required bool isVerified,
    required String loginMessage,
    required String verifyMessage,
  }) {
    if (uid == null) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(content: Text(loginMessage)),
      );
      return false;
    }
    if (!isVerified) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(content: Text(verifyMessage)),
      );
      return false;
    }
    return true;
  }

  /// Shorthand for [AppLocalizations.of(context)].
  AppLocalizations get l10n => AppLocalizations.of(this);
}
