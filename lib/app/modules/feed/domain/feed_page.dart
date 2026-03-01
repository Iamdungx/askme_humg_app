import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';

/// Cursor-based pagination result for the public feed.
/// [lastDocId] is the Firestore document ID of the last item — opaque to domain,
/// used by the data layer to construct `startAfterDocument` cursors.
class FeedPage {
  const FeedPage({required this.items, this.lastDocId});

  final List<FeedItem> items;
  final String? lastDocId;

  bool get hasMore => items.length >= 20;
}
