import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/modules/auth/data/auth_repository_impl.dart';
import 'package:askme_humg/app/modules/auth/data/firebase_auth_datasource.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_use_cases.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/domain/i_auth_repository.dart';

part 'auth_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

@riverpod
FirebaseAuthDatasource firebaseAuthDatasource(Ref ref) =>
    FirebaseAuthDatasource(
      firebaseAuth: ref.watch(firebaseAuthProvider),
      firestore: ref.watch(firestoreProvider),
    );

@riverpod
IAuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider));

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

@riverpod
SignInWithGoogle signInWithGoogle(Ref ref) =>
    SignInWithGoogle(ref.watch(authRepositoryProvider));

@riverpod
SignOut signOut(Ref ref) => SignOut(ref.watch(authRepositoryProvider));

// ---------------------------------------------------------------------------
// Auth state stream — watched by router guard
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
Stream<AuthUser?> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges;

// ---------------------------------------------------------------------------
// AuthNotifier — handles sign-in / sign-out actions
// ---------------------------------------------------------------------------

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> signIn() async {
    state = const AsyncLoading();
    final useCase = ref.read(signInWithGoogleProvider);
    final next = await AsyncValue.guard(() => useCase.call());
    if (!ref.mounted) return;
    state = next;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final useCase = ref.read(signOutProvider);
    final next = await AsyncValue.guard(() => useCase.call());
    if (!ref.mounted) return;
    state = next;
  }
}
