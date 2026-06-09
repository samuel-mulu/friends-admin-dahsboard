import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../data/models/game_model.dart';
import 'game_compact_info_bar.dart';

class CollapsibleGameInfoBar extends StatefulWidget {
  const CollapsibleGameInfoBar({required this.game, super.key});

  final GameModel game;

  @override
  State<CollapsibleGameInfoBar> createState() => _CollapsibleGameInfoBarState();
}

class _CollapsibleGameInfoBarState extends State<CollapsibleGameInfoBar> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppBranding.statPillBackground(context),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Game stats',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!_expanded)
                    Text(
                      '${widget.game.entryFee} · ${widget.game.prizeAmount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          GameCompactInfoBar(game: widget.game),
        ],
      ],
    );
  }
}
