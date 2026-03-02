import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';

@freezed
abstract class Report with _$Report {
  const factory Report({
    required String reportId,
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
    required String status,
    required DateTime createdAt,
    @Default('') String content,
    DateTime? resolvedAt,
    String? parentAnswerId,
  }) = _Report;
}
