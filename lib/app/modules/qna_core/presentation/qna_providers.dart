import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/qna_core/data/firebase_qna_datasource.dart';
import 'package:askme_humg/app/modules/qna_core/data/qna_repository_impl.dart';
import 'package:askme_humg/app/modules/qna_core/domain/i_qna_repository.dart';
import 'package:askme_humg/app/modules/qna_core/domain/qna_use_cases.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_submission_receipt.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_tracking_status.dart';

part 'qna_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

@riverpod
FirebaseQnaDatasource qnaDatasource(Ref ref) => FirebaseQnaDatasource(
  firestore: ref.watch(firestoreProvider),
  apiClient: ref.watch(apiClientProvider),
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
GetAnswerPublishStates getAnswerPublishStatesUseCase(Ref ref) =>
    GetAnswerPublishStates(ref.watch(qnaRepositoryProvider));

@riverpod
PublishSavedAnswer publishSavedAnswerUseCase(Ref ref) =>
    PublishSavedAnswer(ref.watch(qnaRepositoryProvider));

@riverpod
DeleteQuestion deleteQuestionUseCase(Ref ref) =>
    DeleteQuestion(ref.watch(qnaRepositoryProvider));

@riverpod
GetQuestionById getQuestionByIdUseCase(Ref ref) =>
    GetQuestionById(ref.watch(qnaRepositoryProvider));

@riverpod
GetQuestionTrackingStatus getQuestionTrackingStatusUseCase(Ref ref) =>
    GetQuestionTrackingStatus(ref.watch(qnaRepositoryProvider));

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

@riverpod
Stream<Map<String, bool>> answerPublishStates(Ref ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const <String, bool>{});
  return ref.watch(getAnswerPublishStatesUseCaseProvider).call(uid);
}

// ---------------------------------------------------------------------------
// Notifiers for mutations
// ---------------------------------------------------------------------------

@riverpod
class SubmitQuestionNotifier extends _$SubmitQuestionNotifier {
  @override
  FutureOr<QuestionSubmissionReceipt?> build() => null;

  Future<void> submit({
    required String toUserId,
    required String content,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(submitAnonymousQuestionUseCaseProvider)
          .call(toUserId: toUserId, content: content),
    );
  }
}

@riverpod
class QuestionTrackingStatusNotifier extends _$QuestionTrackingStatusNotifier {
  @override
  FutureOr<QuestionTrackingStatus?> build() => null;

  Future<void> lookup({required String trackingCode, String? clientKey}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(getQuestionTrackingStatusUseCaseProvider)
          .call(trackingCode: trackingCode, clientKey: clientKey),
    );
  }
}

@Riverpod(keepAlive: true)
class DeleteQuestionNotifier extends _$DeleteQuestionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> delete(String questionId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(deleteQuestionUseCaseProvider).call(questionId),
    );
    // Guard against provider being disposed after the inbox stream rebuilds
    // in response to the deletion (the stream fires before this await returns).
    if (ref.mounted) state = result;
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
      state = AsyncError(Exception('Not authenticated'), StackTrace.current);
      return;
    }
    state = await AsyncValue.guard(
      () => ref
          .read(answerQuestionUseCaseProvider)
          .call(
            questionId: questionId,
            userId: uid,
            content: content,
            isPublished: isPublished,
          ),
    );
  }
}

@riverpod
class PublishSavedAnswerNotifier extends _$PublishSavedAnswerNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submit({required String questionId}) async {
    state = const AsyncLoading();
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      state = AsyncError(Exception('Not authenticated'), StackTrace.current);
      return;
    }
    state = await AsyncValue.guard(
      () => ref
          .read(publishSavedAnswerUseCaseProvider)
          .call(questionId: questionId, userId: uid),
    );
  }
}
