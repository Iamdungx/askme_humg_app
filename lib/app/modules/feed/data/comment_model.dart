import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/modules/feed/domain/comment.dart';

part 'comment_model.freezed.dart';

@freezed
abstract class CommentModel with _$CommentModel {
  const factory CommentModel({
    required String commentId,
    required String answerId,
    String? userId,
    required String content,
    required bool isAnonymous,
    required DateTime createdAt,
    @Default('') String authorName,
    @Default('') String authorAvatar,
  }) = _CommentModel;

  factory CommentModel.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final createdAtTs = data['createdAt'] as Timestamp?;
    if (createdAtTs == null) {
      throw FirestoreException('createdAt is null for comment ${doc.id}');
    }
    return CommentModel(
      commentId: doc.id,
      answerId: data['answerId'] as String? ?? '',
      userId: data['userId'] as String?,
      content: data['content'] as String? ?? '',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      createdAt: createdAtTs.toDate(),
      authorName: data['authorName'] as String? ?? '',
      authorAvatar: data['authorAvatar'] as String? ?? '',
    );
  }
}

extension CommentModelX on CommentModel {
  Comment toDomain() => Comment(
        commentId: commentId,
        answerId: answerId,
        userId: userId,
        content: content,
        isAnonymous: isAnonymous,
        createdAt: createdAt,
        authorName: authorName,
        authorAvatar: authorAvatar,
      );
}
