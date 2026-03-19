import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/profile/data/user_profile_model.dart';
import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

class FirebaseProfileDatasource {
  FirebaseProfileDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  // UC-2.2: GET users/{userId} + query answers where userId==uid && isPublished==true
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw const FirestoreException('User not found');
      }

      final data = userDoc.data()!;
      final model = UserProfileModel(
        userId: userId,
        name: data['name'] as String? ?? '',
        avatar: data['avatar'] as String? ?? '',
        email: data['email'] as String? ?? '',
        isBlocked: data['isBlocked'] as bool? ?? false,
        isHumgVerified: data['isHumgVerified'] as bool? ?? false,
      );

      final answersSnapshot = await _firestore
          .collection('answers')
          .where('userId', isEqualTo: userId)
          .where('isPublished', isEqualTo: true)
          .get();

      final answerCount = answersSnapshot.docs.length;
      final totalLikes = answersSnapshot.docs.fold<int>(
        0,
        (acc, doc) => acc + (doc.data()['likeCount'] as int? ?? 0),
      );

      return model.toDomain(answerCount: answerCount, totalLikes: totalLikes);
    } on FirestoreException {
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e('Firestore getUserProfile failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    } catch (e, s) {
      logger.e('Unexpected error in getUserProfile', error: e, stackTrace: s);
      throw FirestoreException(e.toString());
    }
  }

  // BACKLOG-02: Update display name and/or avatar for the authenticated user.
  // If avatarLocalPath is provided:
  //   1. Read avatarUpdatedAt from Firestore — enforce 7-day cooldown.
  //   2. Upload to avatars/{userId}.jpg in Firebase Storage.
  //   3. Update users doc with new avatar URL + avatarUpdatedAt = now.
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? avatarLocalPath,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (avatarLocalPath != null) {
        // Enforce 7-day avatar cooldown.
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final raw = userDoc.data()?['avatarUpdatedAt'];
        if (raw != null) {
          final lastChanged = (raw as Timestamp).toDate();
          final nextAllowed = lastChanged.add(const Duration(days: 7));
          if (DateTime.now().isBefore(nextAllowed)) {
            throw AvatarCooldownException(nextAllowed);
          }
        }

        // Compress then store as base64 data URI directly in Firestore.
        // Temporary approach until Firebase Storage (Blaze plan) is available.
        final compressed = await _compressAvatar(avatarLocalPath);
        final base64Str = base64Encode(compressed);
        updates['avatar'] = 'data:image/jpeg;base64,$base64Str';
        updates['avatarUpdatedAt'] = FieldValue.serverTimestamp();
      }

      if (name != null) {
        updates['name'] = name.trim();
      }

      if (updates.isEmpty) return;

      await _firestore.collection('users').doc(userId).update(updates);
    } on AvatarCooldownException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e('updateProfile Firebase failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore update failed');
    } catch (e, s) {
      logger.e('Unexpected error in updateProfile', error: e, stackTrace: s);
      throw FirestoreException(e.toString());
    }
  }

  /// Compress avatar to JPEG ≤ 512×512 px, quality 80 — keeps file under ~100 KB.
  Future<Uint8List> _compressAvatar(String localPath) async {
    final tmpDir = await getTemporaryDirectory();
    final targetPath =
        '${tmpDir.path}/avatar_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      localPath,
      targetPath,
      minWidth: 512,
      minHeight: 512,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (result == null) {
      // Fallback: read original if compress fails
      return await File(localPath).readAsBytes();
    }
    final bytes = await result.readAsBytes();
    await File(targetPath).delete().catchError((Object _) => File(targetPath));
    return bytes;
  }

  /// Cập nhật preference thông báo (webhook OneSignal đọc từ đây khi chưa có Blaze).
  Future<void> updateNotificationPrefs({
    required String userId,
    required bool notifNewQuestion,
    required bool notifNewComment,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notifNewQuestion': notifNewQuestion,
        'notifNewComment': notifNewComment,
      });
    } on FirebaseException catch (e, s) {
      logger.e('updateNotificationPrefs failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore update failed');
    }
  }

  /// Returns the DateTime when the user last changed their avatar,
  /// or null if they have never changed it.
  Future<DateTime?> getAvatarUpdatedAt(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final raw = doc.data()?['avatarUpdatedAt'];
      if (raw == null) return null;
      return (raw as Timestamp).toDate();
    } on FirebaseException catch (e, s) {
      logger.e('getAvatarUpdatedAt failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    }
  }
}
