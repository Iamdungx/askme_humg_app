import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/modules/auth/data/auth_repository_impl.dart';
import 'package:askme_humg/app/modules/auth/data/firebase_auth_datasource.dart';
import 'package:askme_humg/app/modules/auth/data/otp_datasource.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_use_cases.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/domain/i_auth_repository.dart';

part 'auth_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

// keepAlive: datasource owns the authStateChanges stream (late final field).
// Disposing it would destroy the stream and break the router guard.
@Riverpod(keepAlive: true)
FirebaseAuthDatasource firebaseAuthDatasource(Ref ref) =>
    FirebaseAuthDatasource(
      firebaseAuth: ref.watch(firebaseAuthProvider),
      firestore: ref.watch(firestoreProvider),
    );

@riverpod
OtpDatasource otpDatasource(Ref ref) => OtpDatasource(
  firestore: ref.watch(firestoreProvider),
);

// keepAlive: authStateProvider (keepAlive) watches this — if it were
// auto-disposed, authState would lose its stream on the next rebuild.
@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  ref.watch(firebaseAuthDatasourceProvider),
  ref.watch(otpDatasourceProvider),
);

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

@riverpod
SignInWithGoogle signInWithGoogle(Ref ref) =>
    SignInWithGoogle(ref.watch(authRepositoryProvider));

@riverpod
SignOut signOut(Ref ref) => SignOut(ref.watch(authRepositoryProvider));

@riverpod
GenerateOtp generateOtpUseCase(Ref ref) =>
    GenerateOtp(ref.watch(authRepositoryProvider));

@riverpod
VerifyOtp verifyOtpUseCase(Ref ref) =>
    VerifyOtp(ref.watch(authRepositoryProvider));

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

// ---------------------------------------------------------------------------
// GenerateOtpNotifier — UC-1.3: sends OTP email
// ---------------------------------------------------------------------------

@riverpod
class GenerateOtpNotifier extends _$GenerateOtpNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> send({
    required String email,
    required String uid,
    String? recipientName,
  }) async {
    state = const AsyncLoading();
    final useCase = ref.read(generateOtpUseCaseProvider);
    final next = await AsyncValue.guard(
      () => useCase.call(email: email, uid: uid, recipientName: recipientName),
    );
    if (!ref.mounted) return;
    state = next;
  }
}

// ---------------------------------------------------------------------------
// VerifyOtpNotifier — UC-1.3: verifies OTP entered by user
// ---------------------------------------------------------------------------

@riverpod
class VerifyOtpNotifier extends _$VerifyOtpNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> verify({required String otp, required String uid}) async {
    state = const AsyncLoading();
    final useCase = ref.read(verifyOtpUseCaseProvider);
    final next = await AsyncValue.guard(
      () => useCase.call(otp: otp, uid: uid),
    );
    if (!ref.mounted) return;
    state = next;
  }
}
