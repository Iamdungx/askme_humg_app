import 'package:flutter/material.dart';
import 'package:askme_humg/app/modules/moderation/presentation/widgets/report_reason_sheet.dart';

/// Shows the [ReportReasonSheet] bottom sheet for any reportable content.
///
/// Handles the [showModalBottomSheet] boilerplate so call sites stay clean.
Future<void> showReportSheet(
  BuildContext context, {
  required String targetId,
  required String targetType,
  required String content,
  String? parentAnswerId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReportReasonSheet(
      targetId: targetId,
      targetType: targetType,
      content: content,
      parentAnswerId: parentAnswerId,
    ),
  );
}
