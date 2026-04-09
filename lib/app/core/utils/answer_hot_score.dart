import 'dart:math' as math;

/// Reddit-style ranking with time decay (SRS: denormalized `hotScore` on `answers`).
///
/// Higher [engagement] (likes + weighted comments) and newer [createdAt] yield a
/// larger score. Stored in Firestore for `orderBy` (cannot compute in-query).
double computeAnswerHotScore({
  required int likeCount,
  required int commentCount,
  required DateTime createdAt,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final ageSeconds = math.max(0, clock.difference(createdAt).inSeconds);
  final ageHours = ageSeconds / 3600.0;
  const double wLike = 1.0;
  const double wComment = 2.0;
  final engagement = wLike * likeCount + wComment * commentCount;
  const double gravity = 1.8;
  const double offsetHours = 2.0;
  final denom = math.pow(ageHours + offsetHours, gravity);
  if (denom <= 0) return engagement.toDouble();
  return (engagement + 1) / denom;
}
