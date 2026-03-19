class FeedTopic {
  const FeedTopic({
    required this.id,
    required this.slug,
    required this.label,
    required this.color,
    this.category,
  });

  final String id;
  final String slug;
  final String label;
  final String color;
  final String? category;
}
