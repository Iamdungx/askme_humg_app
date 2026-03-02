import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/modules/profile/data/firebase_profile_datasource.dart';
import 'package:askme_humg/app/modules/profile/data/profile_repository_impl.dart';
import 'package:askme_humg/app/modules/profile/domain/i_profile_repository.dart';
import 'package:askme_humg/app/modules/profile/domain/profile_use_cases.dart';
import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

part 'profile_providers.g.dart';

@riverpod
FirebaseProfileDatasource profileDatasource(Ref ref) =>
    FirebaseProfileDatasource(
      firestore: ref.watch(firestoreProvider),
    );

@riverpod
IProfileRepository profileRepository(Ref ref) =>
    ProfileRepositoryImpl(ref.watch(profileDatasourceProvider));

@riverpod
GetUserProfile getUserProfileUseCase(Ref ref) =>
    GetUserProfile(ref.watch(profileRepositoryProvider));

@riverpod
GenerateDeepLink generateDeepLinkUseCase(Ref ref) => const GenerateDeepLink();

@riverpod
UpdateProfile updateProfileUseCase(Ref ref) =>
    UpdateProfile(ref.watch(profileRepositoryProvider));

@riverpod
Future<UserProfile> userProfile(Ref ref, String userId) =>
    ref.watch(getUserProfileUseCaseProvider).call(userId);

/// Returns the last time [userId] changed their avatar, or null if never.
/// Used by EditProfileScreen to enforce the 7-day cooldown before allowing
/// the camera button to be tapped.
@riverpod
Future<DateTime?> avatarUpdatedAt(Ref ref, String userId) =>
    ref.watch(profileRepositoryProvider).getAvatarUpdatedAt(userId);
