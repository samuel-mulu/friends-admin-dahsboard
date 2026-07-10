import 'package:flutter/material.dart';

import '../theme/app_branding.dart';
import '../../features/shared/presentation/widgets/branding_splash_view.dart';

/// The single loading component for Friends Bingo.
///
/// Three context-tiered variants share one visual language so loading never
/// looks inconsistent across screens:
///
/// * [FriendsBingoLoader.fullscreen] — full-bleed branded splash (gradient +
///   floating BINGO balls). Use for route bodies / initial loads where the
///   loader owns the whole screen. Guaranteed to fill its parent, so it never
///   leaves a bare/black gap.
/// * [FriendsBingoLoader.overlay] — a blocking scrim + centered branded card
///   layered over existing content. Place it as the last child of a [Stack]
///   (it expands to fill). Use when the user genuinely cannot interact yet.
/// * [FriendsBingoLoader.inline] — a compact spinner for lists, small regions,
///   and buttons.
enum _LoaderVariant { fullscreen, overlay, inline }

class FriendsBingoLoader extends StatelessWidget {
  /// Full-bleed branded loader for route bodies / initial loads.
  const FriendsBingoLoader.fullscreen({this.message, super.key})
      : _variant = _LoaderVariant.fullscreen,
        title = null,
        showRetry = false,
        onRetry = null,
        compact = false;

  /// Blocking scrim + branded card layered over content.
  ///
  /// Return value fills its parent — add it as the last child of a [Stack].
  const FriendsBingoLoader.overlay({
    this.title,
    this.message,
    this.showRetry = false,
    this.onRetry,
    super.key,
  })  : _variant = _LoaderVariant.overlay,
        compact = false;

  /// Compact spinner for lists, small regions, and inline states.
  const FriendsBingoLoader.inline({
    this.message,
    this.compact = false,
    super.key,
  })  : _variant = _LoaderVariant.inline,
        title = null,
        showRetry = false,
        onRetry = null;

  final _LoaderVariant _variant;
  final String? title;
  final String? message;
  final bool showRetry;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    switch (_variant) {
      case _LoaderVariant.fullscreen:
        return BrandedLoadingBackdrop(message: message);
      case _LoaderVariant.overlay:
        return _OverlayLoader(
          title: title,
          message: message,
          showRetry: showRetry,
          onRetry: onRetry,
        );
      case _LoaderVariant.inline:
        return _InlineLoader(message: message, compact: compact);
    }
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader({this.message, this.compact = false});

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            child: CircularProgressIndicator(
              strokeWidth: compact ? 2.5 : 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: compact ? 10 : 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayLoader extends StatelessWidget {
  const _OverlayLoader({
    this.title,
    this.message,
    this.showRetry = false,
    this.onRetry,
  });

  final String? title;
  final String? message;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Material(
              elevation: 12,
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppBranding.gold,
                      ),
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (showRetry && onRetry != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
