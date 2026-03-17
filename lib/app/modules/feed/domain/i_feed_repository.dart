import 'package:askme_humg/app/modules/feed/domain/comment.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_page.dart';

abstract class IFeedRepository {
  Future<FeedPage> getPublicFeed({String? lastDocId});

  Future<FeedItem?> getPublishedAnswerById(String answerId);

  Future<void> toggleLike({
    required String answerId,
    required String userId,
    required bool isCurrentlyLiked,
  });

  Stream<List<Comment>> getComments(String answerId);

  Future<void> postComment({
    required String answerId,
    String? userId,
    required String content,
    required bool isAnonymous,
  });

  /// Returns the most recent [limit] published answers by a user (UC-4.1 pattern).
  Future<List<FeedItem>> getUserAnswers({
    required String userId,
    int limit = 3,
  });
}
