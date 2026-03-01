import 'package:flutter/material.dart';
import 'package:askme_humg/app/global_widgets/loading_shimmer.dart';

/// Skeleton placeholder for a single FeedItemCard while loading.
/// Use LoadingShimmer which already mirrors the FeedItemCard layout.
class FeedLoadingShimmer extends StatelessWidget {
  const FeedLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) => const LoadingShimmer();
}
