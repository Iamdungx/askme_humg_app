/// UC-1.3 — OTP Datasource
///
/// Flow:
///   generateOtp()  → random 6-digit OTP → SHA-256 hash → Firestore otpRequests/{uid}
///                  → Gmail SMTP (mailer package) gửi email OTP
///   verifyOtp()    → read otpRequests/{uid} → check expiry + attempts + hash
///                  → success: update users/{uid}.isHumgVerified=true, delete doc
library;

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/config/env_reader.dart';

class OtpDatasource {
  OtpDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _otpCollection = 'otpRequests';
  static const _usersCollection = 'users';
  static const _otpLength = 6;
  static const _otpExpiryMinutes = 10;
  static const _maxAttempts = 3;

  // ---------------------------------------------------------------------------
  // Generate OTP
  // ---------------------------------------------------------------------------

  Future<void> generateOtp({
    required String email,
    required String uid,
    String? recipientName,
  }) async {
    final otp = _generateSecureOtp();
    final hash = _sha256Hash(otp);
    final expiresAt = DateTime.now().add(
      const Duration(minutes: _otpExpiryMinutes),
    );

    try {
      await _firestore.collection(_otpCollection).doc(uid).set({
        'email': email,
        'otpHash': hash,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });
    } on FirebaseException catch (e, s) {
      logger.e(
        'OtpDatasource.generateOtp Firestore write failed',
        error: e,
        stackTrace: s,
      );
      throw FirestoreException(e.message ?? 'Failed to store OTP');
    }

    try {
      await _sendEmailViaGmail(
        email: email,
        otp: otp,
        recipientName: recipientName,
      );
    } on OtpSendException {
      rethrow;
    } catch (e, s) {
      logger.e(
        'OtpDatasource.generateOtp Gmail send failed',
        error: e,
        stackTrace: s,
      );
      throw OtpSendException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Verify OTP
  // ---------------------------------------------------------------------------

  Future<void> verifyOtp({required String otp, required String uid}) async {
    final docRef = _firestore.collection(_otpCollection).doc(uid);

    late Map<String, dynamic> data;
    try {
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        throw const OtpExpiredException();
      }
      data = doc.data()!;
    } on OtpExpiredException {
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e(
        'OtpDatasource.verifyOtp Firestore read failed',
        error: e,
        stackTrace: s,
      );
      throw FirestoreException(e.message ?? 'Failed to read OTP');
    }

    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      await docRef.delete().catchError((_) {});
      throw const OtpExpiredException();
    }

    final attempts = (data['attempts'] as int?) ?? 0;
    if (attempts >= _maxAttempts) {
      throw const OtpMaxAttemptsException();
    }

    final storedHash = data['otpHash'] as String? ?? '';
    final inputHash = _sha256Hash(otp);

    if (inputHash != storedHash) {
      try {
        await docRef.update({'attempts': FieldValue.increment(1)});
      } on FirebaseException catch (e, s) {
        logger.w(
          'OtpDatasource.verifyOtp attempt increment failed',
          error: e,
          stackTrace: s,
        );
      }
      final newAttempts = attempts + 1;
      if (newAttempts >= _maxAttempts) {
        throw const OtpMaxAttemptsException();
      }
      throw const OtpInvalidException();
    }

    final email = data['email'] as String? ?? '';
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_usersCollection).doc(uid), {
        'isHumgVerified': true,
        'humgEmail': email,
      });
      batch.delete(docRef);
      await batch.commit();
    } on FirebaseException catch (e, s) {
      logger.e(
        'OtpDatasource.verifyOtp batch commit failed',
        error: e,
        stackTrace: s,
      );
      throw FirestoreException(e.message ?? 'Failed to verify OTP');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _generateSecureOtp() {
    final random = Random.secure();
    final digits = List.generate(_otpLength, (_) => random.nextInt(10));
    return digits.join();
  }

  String _sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _sendEmailViaGmail({
    required String email,
    required String otp,
    String? recipientName,
  }) async {
    final gmailUser = EnvReader.gmailUser;
    final gmailPassword = EnvReader.gmailAppPassword;

    if (gmailUser.isEmpty || gmailPassword.isEmpty) {
      throw const OtpSendException(
        'GMAIL_USER hoặc GMAIL_APP_PASSWORD chưa được cấu hình trong .env',
      );
    }

    final smtpServer = gmail(gmailUser, gmailPassword);

    final greeting = (recipientName != null && recipientName.isNotEmpty)
        ? 'Xin chào $recipientName,'
        : 'Xin chào,';

    final message = Message()
      ..from = Address(gmailUser, 'AskMe HUMG')
      ..recipients.add(email)
      ..subject = '[AskMe HUMG] Mã xác thực của bạn'
      ..text =
          '$greeting\n\n'
          'Mã xác thực 6 chữ số để liên kết email HUMG với tài khoản AskMe của bạn:\n\n'
          '  $otp\n\n'
          'Mã có hiệu lực trong 10 phút.\n\n'
          'Nếu bạn không yêu cầu mã này, hãy bỏ qua email này.\n'
          'Email tự động — vui lòng không trả lời.\n\n'
          '--- AskMe HUMG';

    try {
      final report = await send(message, smtpServer);
      logger.i(
        'OTP email sent via Gmail to $email | finished=${report.messageSendingEnd}',
      );
    } on MailerException catch (e) {
      logger.e('Gmail SMTP error: $e | problems: ${e.problems}');
      throw OtpSendException(
        'Gmail send failed: ${e.problems.map((p) => p.msg).join(', ')}',
      );
    }
  }
}
