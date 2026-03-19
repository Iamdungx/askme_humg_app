import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';

part 'feed_item_model.freezed.dart';

@freezed
abstract class FeedItemModel with _$FeedItemModel {
  const factory FeedItemModel({
    required String answerId,
    required String questionId,
    required String questionContent,
    required String answerContent,
    required String hostUserId,
    required String hostName,
    required String hostAvatar,
    required DateTime createdAt,
    required int likeCount,
    required List<String> likedBy,
    required int commentCount,
    required bool isPublished,
    @Default(false) bool hostIsHumgVerified,
    String? aiCategory,
    @Default(<String>[]) List<String> aiTags,
    @Default(<String>[]) List<String> aiTagIds,
    @Default(<FeedAiTagRef>[]) List<FeedAiTagRef> aiTagRefs,
  }) = _FeedItemModel;

  factory FeedItemModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAtTs = data['createdAt'] as Timestamp?;
    if (createdAtTs == null) {
      throw FirestoreException('createdAt is null for answer ${doc.id}');
    }
    return FeedItemModel(
      answerId: doc.id,
      questionId: data['questionId'] as String? ?? '',
      questionContent: data['questionContent'] as String? ?? '',
      answerContent: data['content'] as String? ?? '',
      hostUserId: data['userId'] as String? ?? '',
      hostName: data['hostName'] as String? ?? '',
      hostAvatar: data['hostAvatar'] as String? ?? '',
      createdAt: createdAtTs.toDate(),
      likeCount: data['likeCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
      commentCount: data['commentCount'] as int? ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
      hostIsHumgVerified: data['hostIsHumgVerified'] as bool? ?? false,
      aiCategory: data['aiCategory'] as String?,
      aiTags: List<String>.from(data['aiTags'] as List? ?? []),
      aiTagIds: List<String>.from(data['aiTagIds'] as List? ?? []),
      aiTagRefs: _parseAiTagRefs(data['aiTagRefs'] as List?),
    );
  }
}

List<FeedAiTagRef> _parseAiTagRefs(List? rawList) {
  if (rawList == null) return const <FeedAiTagRef>[];
  final results = <FeedAiTagRef>[];
  for (final raw in rawList) {
    if (raw is! Map) continue;
    final id = raw['id'] is String ? raw['id'] as String : '';
    final slug = raw['slug'] is String ? raw['slug'] as String : '';
    final label = raw['label'] is String ? raw['label'] as String : '';
    final color = raw['color'] is String ? raw['color'] as String : '';
    if (id.isEmpty || slug.isEmpty) continue;
    results.add(
      FeedAiTagRef(
        id: id,
        slug: slug,
        label: label.isNotEmpty ? label : slug,
        color: color,
      ),
    );
  }
  return results;
}

extension FeedItemModelX on FeedItemModel {
  FeedItem toDomain() => FeedItem(
    answerId: answerId,
    questionId: questionId,
    questionContent: questionContent,
    answerContent: answerContent,
    hostUserId: hostUserId,
    hostName: hostName,
    hostAvatar: hostAvatar,
    createdAt: createdAt,
    likeCount: likeCount,
    likedBy: likedBy,
    commentCount: commentCount,
    isPublished: isPublished,
    hostIsHumgVerified: hostIsHumgVerified,
    aiCategory: aiCategory,
    aiTags: aiTags,
    aiTagIds: aiTagIds,
    aiTagRefs: aiTagRefs,
  );
}
