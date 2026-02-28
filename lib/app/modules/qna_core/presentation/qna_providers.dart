import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/qna_core/data/firebase_qna_datasource.dart';
import 'package:askme_humg/app/modules/qna_core/data/qna_repository_impl.dart';
import 'package:askme_humg/app/modules/qna_core/domain/i_qna_repository.dart';
import 'package:askme_humg/app/modules/qna_core/domain/qna_use_cases.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';

part 'qna_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

@riverpod
FirebaseQnaDatasource qnaDatasource(Ref ref) => FirebaseQnaDatasource(
  firestore: ref.watch(firestoreProvider),
  dio: ref.watch(apiClientProvider).dio,
);

@riverpod
IQnaRepository qnaRepository(Ref ref) =>
    QnaRepositoryImpl(ref.watch(qnaDatasourceProvider));

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

@riverpod
SubmitAnonymousQuestion submitAnonymousQuestionUseCase(Ref ref) =>
    SubmitAnonymousQuestion(ref.watch(qnaRepositoryProvider));

@riverpod
GetInboxQuestions getInboxQuestionsUseCase(Ref ref) =>
    GetInboxQuestions(ref.watch(qnaRepositoryProvider));

@riverpod
AnswerQuestion answerQuestionUseCase(Ref ref) =>
    AnswerQuestion(ref.watch(qnaRepositoryProvider));

@riverpod
DeleteQuestion deleteQuestionUseCase(Ref ref) =>
    DeleteQuestion(ref.watch(qnaRepositoryProvider));

@riverpod
GetQuestionById getQuestionByIdUseCase(Ref ref) =>
    GetQuestionById(ref.watch(qnaRepositoryProvider));

// ---------------------------------------------------------------------------
// Query providers
// ---------------------------------------------------------------------------

@riverpod
Future<Question?> questionById(Ref ref, String questionId) =>
    ref.watch(getQuestionByIdUseCaseProvider).call(questionId);

// ---------------------------------------------------------------------------
// Stream provider for inbox — real-time updates
// ---------------------------------------------------------------------------

@riverpod
Stream<List<Question>> inbox(Ref ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(getInboxQuestionsUseCaseProvider).call(uid);
}

// ---------------------------------------------------------------------------
// Notifiers for mutations
// ---------------------------------------------------------------------------

@riverpod
class SubmitQuestionNotifier extends _$SubmitQuestionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String toUserId,
    required String content,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(submitAnonymousQuestionUseCaseProvider).call(
        toUserId: toUserId,
        content: content,
      ),
    );
  }
}

@riverpod
class DeleteQuestionNotifier extends _$DeleteQuestionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> delete(String questionId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(deleteQuestionUseCaseProvider).call(questionId),
    );
  }
}

@riverpod
class AnswerNotifier extends _$AnswerNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String questionId,
    required String content,
    required bool isPublished,
  }) async {
    state = const AsyncLoading();
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      state = AsyncError(
        Exception('Not authenticated'),
        StackTrace.current,
      );
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(answerQuestionUseCaseProvider).call(
        questionId: questionId,
        userId: uid,
        content: content,
        isPublished: isPublished,
      ),
    );
  }
}
