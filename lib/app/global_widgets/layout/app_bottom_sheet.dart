import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

/// Shows a standard bottom sheet with consistent theming (shape, drag handle,
/// safe area). Use this for non-scrollable content such as action menus or
/// share cards.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: builder,
  );
}

/// Shows a draggable/scrollable bottom sheet. Use this for tall content such
/// as comments lists.
///
/// [initialSize], [minSize], [maxSize] are fractions of the screen height.
Future<T?> showAppScrollableSheet<T>({
  required BuildContext context,
  required ScrollableWidgetBuilder builder,
  double initialSize = 0.75,
  double minSize = 0.4,
  double maxSize = 0.95,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: DraggableScrollableSheet(
        initialChildSize: initialSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        expand: false,
        builder: builder,
      ),
    ),
  );
}

/// A thin wrapper around [Column] for bottom sheet content that needs a
/// fixed-height layout (e.g. action menus). Handles [mainAxisSize] and
/// adds a standard bottom padding for safe area.
class AppBottomSheetBody extends StatelessWidget {
  const AppBottomSheetBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.lg),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
