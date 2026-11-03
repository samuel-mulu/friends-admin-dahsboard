import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/features/games/presentation/debug/live_cartela_scroll_debug.dart';

/// Sticky live-play cartela scroller (2-col sliver grid + optional footer).
class LiveCartelaViewport extends StatefulWidget {
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
  State<LiveCartelaViewport> createState() => _LiveCartelaViewportState();
}

class _LiveCartelaViewportState extends State<LiveCartelaViewport> {
  @override
  void didUpdateWidget(covariant LiveCartelaViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollIdleListenable != widget.scrollIdleListenable &&
        !oldWidget.scrollIdleListenable.value) {
      oldWidget.scrollIdleListenable.value = true;
    }
  }

  @override
  void dispose() {
    if (!widget.scrollIdleListenable.value) {
      widget.scrollIdleListenable.value = true;
    }
    super.dispose();
  }

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
              if (widget.scrollIdleListenable.value) {
                LiveCartelaScrollDebug.scrollStart();
                widget.onScrollStart();
                widget.scrollIdleListenable.value = false;
              }
            } else if (notification is ScrollUpdateNotification) {
              LiveCartelaScrollDebug.scrollUpdate(
                pixels: notification.metrics.pixels,
                maxExtent: notification.metrics.maxScrollExtent,
              );
            } else if (notification is ScrollEndNotification) {
              if (!widget.scrollIdleListenable.value) {
                widget.scrollIdleListenable.value = true;
                widget.onScrollEnd();
                LiveCartelaScrollDebug.scrollEnd();
              }
            }
            return false;
          },
          child: CustomScrollView(
            scrollCacheExtent: ScrollCacheExtent.pixels(LiveCartelaViewport.defaultCacheExtent),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: widget.padding,
                sliver: widget.buildCartelaSliver(
                  constraints.maxWidth - widget.padding.horizontal,
                ),
              ),
              if (widget.footer != null)
                SliverPadding(
                  padding: widget.padding.copyWith(top: AppSpacing.md),
                  sliver: SliverToBoxAdapter(child: widget.footer),
                ),
            ],
          ),
        );
      },
    );
  }
}
