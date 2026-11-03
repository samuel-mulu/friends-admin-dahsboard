import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/core/widgets/friends_bingo_loader.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_viewport.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_cartela_grid_layout.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_grid_scroll_isolation.dart';

/// Layout modes supported by [RegistrationCartelaListContainer].
enum RegistrationCartelaContainerLayout {
  /// 5-column responsive grid (fast browsing).
  grid,

  /// Vertical list of row cards (detailed inspection).
  list,
}

/// A standalone, decoupled, reusable container for displaying registration cartelas.
///
/// Handles scroll isolation, smooth scrolling performance, loading, empty, and
/// error states, and dynamically switches between grid and list layouts.
class RegistrationCartelaListContainer extends StatelessWidget {
  const RegistrationCartelaListContainer({
    required this.cartelas,
    required this.itemBuilder,
    this.layout = RegistrationCartelaContainerLayout.grid,
    this.isLoading = false,
    this.errorMessage,
    this.emptyTitle = 'No matches',
    this.emptyMessage = 'Try another number.',
    this.header,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.scrollPhysics = const AlwaysScrollableScrollPhysics(),
    super.key,
  });

  /// The list of cartela models to display.
  final List<CartelaModel> cartelas;

  /// Builder for rendering each individual cartela item.
  final Widget Function(BuildContext context, CartelaModel cartela, int index)
      itemBuilder;

  /// Presentation layout mode (grid vs list).
  final RegistrationCartelaContainerLayout layout;

  /// Whether data is currently loading/reshuffling.
  final bool isLoading;

  /// Optional error message to display when fetch fails.
  final String? errorMessage;

  /// Title for empty matches state.
  final String emptyTitle;

  /// Message for empty matches state.
  final String emptyMessage;

  /// Optional header widget placed above the scrollable cartela content.
  final Widget? header;

  /// Optional footer widget placed below the scrollable cartela content.
  final Widget? footer;

  /// Padding surrounding the cartela items.
  final EdgeInsetsGeometry padding;

  /// Scroll physics.
  final ScrollPhysics scrollPhysics;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: FriendsBingoLoader.inline(compact: true),
      );
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Center(
        child: _InfoCard(
          title: 'Could not load cartelas',
          message: errorMessage!,
          isError: true,
        ),
      );
    }

    if (cartelas.isEmpty) {
      return Center(
        child: _InfoCard(
          title: emptyTitle,
          message: emptyMessage,
          isError: false,
        ),
      );
    }

    return RegistrationGridScrollIsolation(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            scrollCacheExtent: ScrollCacheExtent.pixels(
              LiveCartelaViewport.defaultCacheExtent,
            ),
            physics: scrollPhysics,
            slivers: [
              if (header != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: header,
                  ),
                ),
              SliverPadding(
                padding: padding,
                sliver: switch (layout) {
                  RegistrationCartelaContainerLayout.grid =>
                    _buildGridSliver(constraints),
                  RegistrationCartelaContainerLayout.list =>
                    _buildListSliver(),
                },
              ),
              if (footer != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: footer,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGridSliver(BoxConstraints constraints) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: RegistrationCartelaGridLayout.crossAxisCount,
        mainAxisSpacing: RegistrationCartelaGridLayout.mainAxisSpacing,
        crossAxisSpacing: RegistrationCartelaGridLayout.crossAxisSpacing,
        childAspectRatio: RegistrationCartelaGridLayout.childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final cartela = cartelas[index];
          return itemBuilder(context, cartela, index);
        },
        childCount: cartelas.length,
      ),
    );
  }

  Widget _buildListSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final cartela = cartelas[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: itemBuilder(context, cartela, index),
          );
        },
        childCount: cartelas.length,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.message,
    required this.isError,
  });

  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isError
              ? colorScheme.errorContainer.withValues(alpha: 0.2)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isError
                ? colorScheme.error.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.search_off,
              size: 32,
              color: isError ? colorScheme.error : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isError ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
