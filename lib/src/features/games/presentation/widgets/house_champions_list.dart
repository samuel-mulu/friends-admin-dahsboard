import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/house_champions_model.dart';

class HouseChampionsList extends StatelessWidget {
  const HouseChampionsList({
    required this.response,
    this.compact = false,
    this.maxRows,
    super.key,
  });

  final HouseChampionsResponse response;
  final bool compact;
  final int? maxRows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entries = maxRows == null
        ? response.entries
        : response.entries.take(maxRows!).toList(growable: false);
    final topThree = entries.where((entry) => entry.rank <= 3).toList();
    final rest = entries.where((entry) => entry.rank > 3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact && _hasPeriodLabel)
          Text(
            _periodRangeLabel(l10n),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (!compact && _hasPeriodLabel) VGap.md,
        if (response.me != null) ...[
          _MeRankBanner(me: response.me!),
          VGap.md,
        ],
        if (entries.isEmpty)
          Text(
            l10n.houseChampionsEmpty,
            style: theme.textTheme.bodyLarge,
          )
        else ...[
          if (!compact && topThree.isNotEmpty) ...[
            _TopThreePodium(entries: topThree),
            VGap.lg,
          ],
          ...((!compact && rest.isNotEmpty) ? rest : entries).map(
            (entry) => _LeaderboardRow(
              entry: entry,
              compact: compact,
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasPeriodLabel =>
      response.labelStart != null || response.labelEnd != null;

  String _periodRangeLabel(dynamic l10n) {
    final start = response.labelStart;
    final end = response.labelEnd;
    if (start != null && end != null && start != end) {
      return l10n.houseChampionsPeriodRange(start, end);
    }
    if (start != null) {
      return start;
    }
    return l10n.houseChampionsPeriodAllTime;
  }
}

class _TopThreePodium extends StatelessWidget {
  const _TopThreePodium({required this.entries});

  final List<HouseChampionsEntry> entries;

  @override
  Widget build(BuildContext context) {
    final first = _entryForRank(1);
    final second = _entryForRank(2);
    final third = _entryForRank(3);

    if (first == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second != null
              ? _PodiumTile(entry: second, height: 108, tone: _PodiumTone.silver)
              : const SizedBox(height: 108),
        ),
        HGap.sm,
        Expanded(
          flex: 2,
          child: _PodiumTile(entry: first, height: 132, tone: _PodiumTone.gold),
        ),
        HGap.sm,
        Expanded(
          child: third != null
              ? _PodiumTile(entry: third, height: 96, tone: _PodiumTone.bronze)
              : const SizedBox(height: 96),
        ),
      ],
    );
  }

  HouseChampionsEntry? _entryForRank(int rank) {
    for (final entry in entries) {
      if (entry.rank == rank) {
        return entry;
      }
    }
    return null;
  }
}

enum _PodiumTone { gold, silver, bronze }

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({
    required this.entry,
    required this.height,
    required this.tone,
  });

  final HouseChampionsEntry entry;
  final double height;
  final _PodiumTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = switch (tone) {
      _PodiumTone.gold => AppBranding.goldAccent.withValues(alpha: 0.18),
      _PodiumTone.silver => theme.colorScheme.surfaceContainerHighest,
      _PodiumTone.bronze => const Color(0xFFFFE8D6),
    };

    return Container(
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _medalForRank(entry.rank) ?? '${entry.rank}',
            style: theme.textTheme.headlineSmall,
          ),
          VGap.xs,
          Text(
            entry.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          VGap.xs,
          Text(
            '${entry.cartelaWins}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String? _medalForRank(int rank) {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
  }
}

class _MeRankBanner extends StatelessWidget {
  const _MeRankBanner({required this.me});

  final HouseChampionsMe me;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        l10n.houseChampionsYourRank(me.rank, me.cartelaWins),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.compact,
  });

  final HouseChampionsEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isTopThree = entry.rank <= 3;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isTopThree
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTopThree
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                _medalForRank(entry.rank) ?? '${entry.rank}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            HGap.sm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!compact)
                    Text(
                      l10n.houseChampionsGamesWon(entry.gamesWon),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.houseChampionsWins(entry.cartelaWins),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (!compact)
                  Text(
                    '#${entry.rank}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _medalForRank(int rank) {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
  }
}
