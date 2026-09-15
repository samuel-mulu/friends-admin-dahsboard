import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/chain_round_plan_model.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_rule_localized_name.dart';
import 'bonus_game_info_strip.dart';
import 'big_game_info_strip.dart';
import 'chain_game_info_strip.dart';
import 'chain_game_rounds_dialog.dart';
import 'game_rule_detail_dialog.dart';

enum GameCompactInfoBarLayout { live, registrationOpen }

class GameCompactInfoBar extends ConsumerWidget {
  const GameCompactInfoBar({
    required this.game,
    this.showRule = true,
    this.layout = GameCompactInfoBarLayout.live,
    this.embedded = false,
    this.myRegisteredCartelasCount,
    super.key,
  });

  final GameModel game;
  final bool showRule;
  final GameCompactInfoBarLayout layout;
  final bool embedded;
  final int? myRegisteredCartelasCount;

  String _displayPrizeAmount(GameModel game) {
    if (game.isBigGame || game.isChainGame) {
      return game.effectiveRoundPrizeAmount ??
          game.prizeAmount;
    }
    return game.prizeAmount;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizedRuleName = game.localizedRuleName(ref);
    final prizeAmount = _displayPrizeAmount(game);

    final regCount = myRegisteredCartelasCount ?? 0;

    if (layout == GameCompactInfoBarLayout.registrationOpen) {
      return _RegistrationOpenInfoBar(
        game: game,
        ruleDisplayName: localizedRuleName,
        theme: theme,
        isDark: isDark,
        embedded: embedded,
        myRegisteredCartelasCount: regCount,
        prizeAmount: prizeAmount,
      );
    }

    final row = Row(
      children: [
        if (showRule) ...[
          Expanded(
            flex: 6,
            child: _RuleStatChip(
              game: game,
              ruleDisplayName: localizedRuleName,
              label: context.l10n.gameNowPlaying,
              isDark: isDark,
              theme: theme,
            ),
          ),
          _CompactDivider(theme: theme),
        ],
        Expanded(
          flex: 3,
          child: _CompactInfoChip(
            label: l10n.gameInfoPrize,
            value: formatMoney(prizeAmount),
            theme: theme,
            isDark: isDark,
            highlighted: true,
            valueStyle: AppBranding.wordmarkBrandAccent(context, size: 16),
          ),
        ),
        _CompactDivider(theme: theme),
        Expanded(
          flex: 2,
          child: _CompactInfoChip(
            label: l10n.gameInfoReg,
            value: '$regCount',
            theme: theme,
          ),
        ),
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        if (game.isBonusLike) ...[
          const SizedBox(height: 8),
          BonusGameInfoStrip(game: game),
        ] else if (game.isBigGame) ...[
          const SizedBox(height: 8),
          BigGameInfoStrip(game: game),
        ] else if (game.isChainGame) ...[
          const SizedBox(height: 8),
          _ChainGameRegistrationRounds(game: game),
        ],
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppBranding.statPillBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBranding.panelBorder(context)),
      ),
      child: content,
    );
  }
}

class _RegistrationOpenInfoBar extends StatelessWidget {
  const _RegistrationOpenInfoBar({
    required this.game,
    required this.ruleDisplayName,
    required this.theme,
    required this.isDark,
    required this.myRegisteredCartelasCount,
    required this.prizeAmount,
    this.embedded = false,
  });

  final GameModel game;
  final String ruleDisplayName;
  final ThemeData theme;
  final bool isDark;
  final int myRegisteredCartelasCount;
  final String prizeAmount;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          flex: 5,
          child: _RuleStatChip(
            game: game,
            ruleDisplayName: ruleDisplayName,
            label: context.l10n.gameInfoGame,
            theme: theme,
            isDark: isDark,
          ),
        ),
        _CompactDivider(theme: theme),
        Expanded(
          flex: 3,
          child: _CompactInfoChip(
            label: context.l10n.gameInfoEntry,
            value: game.hasFreeEntry ? 'FREE' : formatMoney(game.entryFee),
            theme: theme,
            valueColor: theme.colorScheme.onSurface,
          ),
        ),
        _CompactDivider(theme: theme),
        Expanded(
          flex: 3,
          child: _CompactInfoChip(
            label: context.l10n.gameInfoPrize,
            value: formatMoney(prizeAmount),
            theme: theme,
            isDark: isDark,
            highlighted: true,
            valueStyle: AppBranding.wordmarkBrandAccent(context, size: 16),
          ),
        ),
        _CompactDivider(theme: theme),
        Expanded(
          flex: 2,
          child: _CompactInfoChip(
            label: context.l10n.gameInfoReg,
            value: '$myRegisteredCartelasCount',
            theme: theme,
          ),
        ),
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        if (game.isBonusLike) ...[
          const SizedBox(height: 8),
          BonusGameInfoStrip(game: game),
        ] else if (game.isBigGame) ...[
          const SizedBox(height: 8),
          BigGameInfoStrip(game: game),
        ] else if (game.isChainGame) ...[
          const SizedBox(height: 8),
          _ChainGameRegistrationRounds(game: game),
        ],
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppBranding.statPillBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBranding.panelBorder(context)),
      ),
      child: content,
    );
  }
}

class _RuleStatChip extends StatelessWidget {
  const _RuleStatChip({
    required this.game,
    required this.ruleDisplayName,
    required this.label,
    required this.isDark,
    required this.theme,
  });

  final GameModel game;
  final String ruleDisplayName;
  final String label;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showGameRuleDetailDialog(context, game: game),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? null : AppBranding.brandChipBackground(context),
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      AppBranding.casinoPurple.withValues(alpha: 0.75),
                      AppBranding.casinoPurpleDeep.withValues(alpha: 0.55),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppBranding.brandChipBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppBranding.brandChipLabel(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : AppBranding.brandPurple.withValues(alpha: 0.72),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                ruleDisplayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppBranding.wordmarkBrandAccent(context, size: 15).copyWith(
                  color: AppBranding.brandHighlightText(context),
                  height: 1.05,
                  shadows: isDark
                      ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactInfoChip extends StatelessWidget {
  const _CompactInfoChip({
    required this.label,
    required this.value,
    required this.theme,
    this.isDark = false,
    this.highlighted = false,
    this.valueColor,
    this.valueStyle,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final bool isDark;
  final bool highlighted;
  final Color? valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedValueStyle = (valueStyle ?? theme.textTheme.labelMedium)
        ?.copyWith(
          fontWeight: FontWeight.w900,
          color:
              valueColor ??
              (highlighted
                  ? AppBranding.brandAccentValue(context)
                  : theme.colorScheme.onSurface),
          letterSpacing: 0.2,
          shadows: highlighted && isDark
              ? [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: highlighted
                ? AppBranding.brandChipLabel(context)
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: highlighted ? 1.1 : 0.6,
            fontSize: 9,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: resolvedValueStyle,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ],
    );

    if (!highlighted) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? null : AppBranding.brandChipBackground(context),
        gradient: isDark
            ? LinearGradient(
                colors: [
                  AppBranding.casinoPurple.withValues(alpha: 0.75),
                  AppBranding.casinoPurpleDeep.withValues(alpha: 0.55),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppBranding.brandChipBorder(context)),
      ),
      child: content,
    );
  }
}

class _CompactDivider extends StatelessWidget {
  const _CompactDivider({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppBranding.panelBorder(context).withValues(alpha: 0.65),
    );
  }
}

class _ChainGameRegistrationRounds extends StatelessWidget {
  const _ChainGameRegistrationRounds({required this.game});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final prizes = game.roundPrizes ?? const <String>[];
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return InkWell(
      onTap: prizes.isEmpty
          ? null
          : () {
              showChainGameRoundsDialog(
                context: context,
                plan: ChainRoundPlan.fromGame(game),
              );
            },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prizes.length > 1)
            ChainRoundPrizeChips(roundPrizes: prizes)
          else if (game.fixedPrizeAmount != null)
            Text(
              l10n.gameBonusFixedPrize(formatMoney(game.fixedPrizeAmount!)),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (game.maxCartelasPerPlayer != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.gameBonusMaxCartelas(game.maxCartelasPerPlayer!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (prizes.length > 1) ...[
            const SizedBox(height: 2),
            Text(
              l10n.chainRoundViewAll,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
