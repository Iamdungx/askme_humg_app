import 'package:askme_humg/app/modules/feed/domain/comment.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_page.dart';
import 'package:askme_humg/app/modules/feed/domain/i_feed_repository.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_topic.dart';

class GetPublicFeed {
  const GetPublicFeed(this._repo);
  final IFeedRepository _repo;

  Future<FeedPage> call({String? lastDocId, String? topicTagId}) =>
      _repo.getPublicFeed(lastDocId: lastDocId, topicTagId: topicTagId);
}

class GetAiTopics {
  const GetAiTopics(this._repo);
  final IFeedRepository _repo;

  Future<List<FeedTopic>> call() => _repo.getAiTopics();
}

class GetPublishedAnswerById {
  const GetPublishedAnswerById(this._repo);
  final IFeedRepository _repo;

  Future<FeedItem?> call(String answerId) =>
      _repo.getPublishedAnswerById(answerId);
}

class GenerateAnswerDeepLink {
  const GenerateAnswerDeepLink();

  String call(String answerId) =>
      'https://askme-humg-app.web.app/answer/$answerId';
}

class ToggleLike {
  const ToggleLike(this._repo);
  final IFeedRepository _repo;

  Future<void> call({
    required String answerId,
    required String userId,
    required bool isCurrentlyLiked,
  }) => _repo.toggleLike(
    answerId: answerId,
    userId: userId,
    isCurrentlyLiked: isCurrentlyLiked,
  );
}

class GetComments {
  const GetComments(this._repo);
  final IFeedRepository _repo;

  Stream<List<Comment>> call(String answerId) => _repo.getComments(answerId);
}

class PostComment {
  const PostComment(this._repo);
  final IFeedRepository _repo;

  Future<void> call({
    required String answerId,
    String? userId,
    required String content,
    required bool isAnonymous,
  }) => _repo.postComment(
    answerId: answerId,
    userId: userId,
    content: content,
    isAnonymous: isAnonymous,
  );
}

class GetUserAnswers {
  const GetUserAnswers(this._repo);
  final IFeedRepository _repo;

  Future<List<FeedItem>> call({required String userId, int limit = 3}) =>
      _repo.getUserAnswers(userId: userId, limit: limit);
}
