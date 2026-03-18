class QuestionTrackingStatus {
  const QuestionTrackingStatus({
    required this.status,
    required this.createdAt,
    required this.answeredAt,
    required this.isPublished,
    required this.answerId,
  });

  final String status;
  final DateTime? createdAt;
  final DateTime? answeredAt;
  final bool isPublished;
  final String? answerId;
}
