import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/core/utils/formatters.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/collapsible_registered_cartela_chips.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_category_theme.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/game_category_badge.dart';

/// Standalone, reusable controls toolbar for cartela registration.
///
/// Houses search query input, reshuffle trigger, select mode toggle,
/// game category pricing/round badges, wallet balance, and registered chips.
class RegistrationCatalogControls extends StatelessWidget {
  const RegistrationCatalogControls({
    required this.registeredNumbers,
    required this.walletBalance,
    required this.bonusCartelaBalance,
    this.bigGameTicketBalance = 0,
    this.preferBigGameTicket = true,
    this.onPreferBigGameTicketChanged,
    this.isFirstTimePlayer = false,
    required this.selectModeEnabled,
    required this.maxAffordableSelections,
    required this.remainingBonusCartelas,
    required this.category,
    required this.entryFee,
    required this.fixedPrizeAmount,
    required this.maxCartelasPerPlayer,
    this.roundPrizes,
    required this.selectedCount,
    this.remainingBalance,
    required this.onSelectModeChanged,
    required this.isGuest,
    required this.searchController,
    required this.onReshuffle,
    required this.onRegisteredNumberTap,
    this.onViewChainRounds,
    super.key,
  });

  final List<int> registeredNumbers;
  final String? walletBalance;
  final int bonusCartelaBalance;
  final int bigGameTicketBalance;
  final bool preferBigGameTicket;
  final ValueChanged<bool>? onPreferBigGameTicketChanged;
  final bool isFirstTimePlayer;
  final bool selectModeEnabled;
  final int? maxAffordableSelections;
  final int? remainingBonusCartelas;
  final GameCategory category;
  final String entryFee;
  final String? fixedPrizeAmount;
  final int? maxCartelasPerPlayer;
  final List<String>? roundPrizes;
  final int selectedCount;
  final String? remainingBalance;
  final ValueChanged<bool> onSelectModeChanged;
  final bool isGuest;
  final TextEditingController searchController;
  final VoidCallback onReshuffle;
  final ValueChanged<int> onRegisteredNumberTap;
  final VoidCallback? onViewChainRounds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isBigGotd = category == GameCategory.bigGotd;
    final isBonusLike = category.isBonusLike;
    final hasFreeEntry = category.hasFreeEntry;
    final canUseBonusCartelaBalance = category.canUseBonusCartelaBalance;
    final isBigGame = category == GameCategory.bigGame;
    final isChainGame = category == GameCategory.chainGame;
    final canUseSelectMode =
        maxAffordableSelections == null || maxAffordableSelections! >= 1;
    final displayBalance = selectModeEnabled && remainingBalance != null
        ? remainingBalance!
        : walletBalance;
    final bonusLimit = maxCartelasPerPlayer ?? 5;
    final bigGameAccent = GameCategoryTheme.accentColor(
      GameCategory.bigGame,
      isDark: isDark,
    );
    final bigGameSurface = GameCategoryTheme.surfaceColor(
      GameCategory.bigGame,
      isDark: isDark,
    );
    final bigGameBorder = GameCategoryTheme.borderColor(
      GameCategory.bigGame,
      isDark: isDark,
    );
    final bigGotdAccent = isDark ? AppBranding.gold : AppBranding.goldDark;
    final bigGotdSurface = GameCategoryTheme.surfaceColor(
      GameCategory.bigGotd,
      isDark: isDark,
    );
    final bigGotdBorder = GameCategoryTheme.borderColor(
      GameCategory.bigGotd,
      isDark: isDark,
    );
    final chainAccent = GameCategoryTheme.accentColor(
      GameCategory.chainGame,
      isDark: isDark,
    );
    final chainSurface = GameCategoryTheme.surfaceColor(
      GameCategory.chainGame,
      isDark: isDark,
    );
    final chainBorder = GameCategoryTheme.borderColor(
      GameCategory.chainGame,
      isDark: isDark,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isBigGame
            ? bigGameSurface
            : isChainGame
            ? chainSurface
            : AppBranding.statPillBackground(context),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(
          color: isBigGame
              ? bigGameBorder
              : isChainGame
              ? chainBorder
              : theme.brightness == Brightness.dark
              ? theme.colorScheme.outlineVariant
              : AppBranding.panelBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isGuest &&
              canUseBonusCartelaBalance &&
              isFirstTimePlayer &&
              bonusCartelaBalance > 0) ...[
            Text(
              'Welcome! Your first $bonusCartelaBalance cartelas are free on normal games only.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            VGap.sm,
          ],
          if (isBonusLike) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: isBigGotd
                        ? bigGotdSurface
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                    border: isBigGotd ? Border.all(color: bigGotdBorder) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBigGotd ? Icons.star_rounded : Icons.redeem_rounded,
                        size: 14,
                        color: isBigGotd
                            ? bigGotdAccent
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                      HGap.xxs,
                      Text(
                        isBigGotd
                            ? l10n.gameCategoryBigGotd
                            : l10n.gameCategoryBonus,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isBigGotd
                              ? bigGotdAccent
                              : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  hasFreeEntry
                      ? l10n.gameBonusFreeEntry
                      : '${l10n.bigGameEntryFee}: ${formatMoney(entryFee)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (fixedPrizeAmount != null)
                  Text(
                    l10n.gameBonusFixedPrize(formatMoney(fixedPrizeAmount!)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  l10n.gameBonusMaxCartelas(bonusLimit),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (remainingBonusCartelas != null)
                  Text(
                    '$remainingBonusCartelas${l10n.registrationLeft}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            VGap.sm,
          ],
          if (isBigGame) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const GameCategoryBadge(
                  category: GameCategory.bigGame,
                  compact: true,
                ),
                if (fixedPrizeAmount != null)
                  Text(
                    isBigGame
                        ? '${l10n.bigGameThisRoundPrize}: ${formatMoney(fixedPrizeAmount!)}'
                        : l10n.gameBonusFixedPrize(
                            formatMoney(fixedPrizeAmount!),
                          ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            if (!isGuest &&
                bigGameTicketBalance > 0 &&
                onPreferBigGameTicketChanged != null) ...[
              VGap.sm,
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.registrationUseBigTicket),
                    icon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 16,
                    ),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.registrationPayEtb),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                  ),
                ],
                selected: {preferBigGameTicket},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onPreferBigGameTicketChanged!(selection.first);
                },
              ),
              VGap.xs,
              Text(
                l10n.registrationBigTicketBalance(bigGameTicketBalance),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            VGap.sm,
          ],
          if (isChainGame) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const GameCategoryBadge(
                  category: GameCategory.chainGame,
                  compact: true,
                ),
                Text(
                  '${l10n.bigGameEntryFee}: ${formatMoney(entryFee)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: chainAccent,
                  ),
                ),
                if (roundPrizes != null && roundPrizes!.length > 1) ...[
                  for (var i = 0; i < roundPrizes!.length; i++)
                    Text(
                      '${l10n.bigGameRoundPrize(i + 1)}: ${formatMoney(roundPrizes![i])}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (fixedPrizeAmount != null)
                    Text(
                      '${l10n.chainRoundTotalPrize}: ${formatMoney(fixedPrizeAmount!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ] else if (fixedPrizeAmount != null)
                  Text(
                    l10n.gameBonusFixedPrize(formatMoney(fixedPrizeAmount!)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (maxCartelasPerPlayer != null)
                  Text(
                    l10n.gameBonusMaxCartelas(bonusLimit),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (remainingBonusCartelas != null)
                  Text(
                    '$remainingBonusCartelas${l10n.registrationLeft}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (onViewChainRounds != null)
                  GestureDetector(
                    onTap: onViewChainRounds,
                    child: Text(
                      l10n.chainRoundViewAll,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: chainAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            VGap.sm,
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isGuest && !hasFreeEntry) ...[
                if (canUseBonusCartelaBalance && bonusCartelaBalance > 0) ...[
                  Icon(
                    Icons.redeem_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  HGap.xs,
                  Text(
                    l10n.registrationBonusBalanceLabel(bonusCartelaBalance),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  HGap.md,
                ],
                if (displayBalance != null) ...[
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: AppBranding.balanceAccent(context),
                  ),
                  HGap.xs,
                  Text(
                    formatMoney(displayBalance),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppBranding.balanceAccent(context),
                    ),
                  ),
                  HGap.md,
                ],
              ],
              FilterChip(
                label: const Text('Select'),
                selected: selectModeEnabled,
                onSelected: !canUseSelectMode && !isGuest
                    ? null
                    : onSelectModeChanged,
                showCheckmark: true,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              HGap.sm,
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: RegistrationCartelaSearchField(
                    controller: searchController,
                  ),
                ),
              ),
              RegistrationReshuffleButton(onReshuffle: onReshuffle),
            ],
          ),
          if (selectModeEnabled && maxAffordableSelections != null) ...[
            VGap.sm,
            Text(
              l10n.registrationBalanceAllowsUpTo(maxAffordableSelections!),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isBigGame
                    ? bigGameAccent
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (registeredNumbers.isNotEmpty) ...[
            VGap.md,
            CollapsibleRegisteredCartelaChips(
              numbers: registeredNumbers,
              onNumberTap: selectModeEnabled ? null : onRegisteredNumberTap,
            ),
          ],
          if (!isGuest &&
              !hasFreeEntry &&
              walletBalance != null &&
              maxAffordableSelections != null &&
              maxAffordableSelections! < 1) ...[
            VGap.sm,
            Text(
              l10n.registrationInsufficientBalance,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ],
      ),
    );
  }
}

/// Standalone search field for the registration cartela catalog.
class RegistrationCartelaSearchField extends StatelessWidget {
  const RegistrationCartelaSearchField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodySmall,
          decoration: InputDecoration(
            hintText: 'Search',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Clear',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: controller.clear,
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        );
      },
    );
  }
}

/// Standalone reshuffle button with icon and theme styling.
class RegistrationReshuffleButton extends StatelessWidget {
  const RegistrationReshuffleButton({required this.onReshuffle, super.key});

  final VoidCallback onReshuffle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'Tap to reshuffle numbers',
      child: IconButton(
        onPressed: onReshuffle,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
            ),
          ),
        ),
        icon: Icon(
          Icons.shuffle_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Standalone bulk registering progress banner.
class RegistrationBulkBanner extends StatelessWidget {
  const RegistrationBulkBanner({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppBranding.casinoPurple.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.55 : 0.12,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppBranding.gold.withValues(alpha: 0.55)
              : AppBranding.brandPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppBranding.brandAccentValue(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.bulkProgress(0, count),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppBranding.brandHighlightText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: null,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: AppBranding.brandAccentValue(context),
            ),
          ),
        ],
      ),
    );
  }
}
