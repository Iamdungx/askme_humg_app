import 'package:cloud_firestore/cloud_firestore.dart';
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
}
