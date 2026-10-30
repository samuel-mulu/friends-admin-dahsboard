import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/features/games/presentation/debug/live_cartela_scroll_debug.dart';

/// Sticky live-play cartela scroller (2-col sliver grid + optional footer).
class LiveCartelaViewport extends StatelessWidget {
  const LiveCartelaViewport({
    required this.scrollIdleListenable,
    required this.onScrollStart,
    required this.onScrollEnd,
    required this.padding,
    required this.buildCartelaSliver,
    this.footer,
    super.key,
  });

  final ValueNotifier<bool> scrollIdleListenable;
  final VoidCallback onScrollStart;
  final VoidCallback onScrollEnd;
  final EdgeInsets padding;
  final Widget Function(double crossAxisExtent) buildCartelaSliver;
  final Widget? footer;

  static double get defaultCacheExtent => kIsWeb ? 320 : 480;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0) {
              return false;
            }
            if (notification is ScrollStartNotification) {
              if (scrollIdleListenable.value) {
                LiveCartelaScrollDebug.scrollStart();
                onScrollStart();
                scrollIdleListenable.value = false;
              }
            } else if (notification is ScrollUpdateNotification) {
              LiveCartelaScrollDebug.scrollUpdate(
                pixels: notification.metrics.pixels,
                maxExtent: notification.metrics.maxScrollExtent,
              );
            } else if (notification is ScrollEndNotification) {
              if (!scrollIdleListenable.value) {
                scrollIdleListenable.value = true;
                onScrollEnd();
                LiveCartelaScrollDebug.scrollEnd();
              }
            }
            return false;
          },
          child: CustomScrollView(
            cacheExtent: defaultCacheExtent,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: buildCartelaSliver(
                  constraints.maxWidth - padding.horizontal,
                ),
              ),
              if (footer != null)
                SliverPadding(
                  padding: padding.copyWith(top: AppSpacing.md),
                  sliver: SliverToBoxAdapter(child: footer),
                ),
            ],
          ),
        );
      },
    );
  }
}
