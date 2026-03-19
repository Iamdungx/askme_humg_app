import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/modules/feed/data/comment_model.dart';
import 'package:askme_humg/app/modules/feed/data/feed_item_model.dart';
import 'package:askme_humg/app/modules/feed/data/firebase_feed_datasource.dart';
import 'package:askme_humg/app/modules/feed/domain/comment.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_page.dart';
import 'package:askme_humg/app/modules/feed/domain/i_feed_repository.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_topic.dart';

class FeedRepositoryImpl implements IFeedRepository {
  FeedRepositoryImpl(this._datasource);
  final FirebaseFeedDatasource _datasource;

  @override
  Future<FeedPage> getPublicFeed({
    String? lastDocId,
    String? topicTagId,
  }) async {
    try {
      final result = await _datasource.getPublicFeed(
        lastDocId: lastDocId,
        topicTagId: topicTagId,
      );
      return FeedPage(
        items: result.items.map((m) => m.toDomain()).toList(),
        lastDocId: result.lastDocId,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<List<FeedTopic>> getAiTopics() async {
    try {
      return await _datasource.getAiTopics();
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<FeedItem?> getPublishedAnswerById(String answerId) async {
    try {
      final model = await _datasource.getPublishedAnswerById(answerId);
      return model?.toDomain();
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> toggleLike({
    required String answerId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    try {
      await _datasource.toggleLike(
        answerId: answerId,
        userId: userId,
        isCurrentlyLiked: isCurrentlyLiked,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Stream<List<Comment>> getComments(String answerId) => _datasource
      .getComments(answerId)
      .map((models) => models.map((m) => m.toDomain()).toList())
      .handleError((Object e) {
        if (e is FirestoreException) throw FirestoreFailure(e.message);
        if (e is AppException) throw UnknownFailure(e.message);
        throw UnknownFailure(e.toString());
      });

  @override
  Future<void> postComment({
    required String answerId,
    String? userId,
    required String content,
    required bool isAnonymous,
  }) async {
    try {
      await _datasource.postComment(
        answerId: answerId,
        userId: userId,
        content: content,
        isAnonymous: isAnonymous,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<List<FeedItem>> getUserAnswers({
    required String userId,
    int limit = 3,
  }) async {
    try {
      final models = await _datasource.getUserAnswers(
        userId: userId,
        limit: limit,
      );
      return models.map((m) => m.toDomain()).toList();
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
