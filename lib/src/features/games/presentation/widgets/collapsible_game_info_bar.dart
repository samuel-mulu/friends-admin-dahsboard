import 'package:flutter/material.dart';

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? GameCompactInfoBar(game: widget.game)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          tooltip: _expanded ? 'Hide game stats' : 'Show game stats',
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
