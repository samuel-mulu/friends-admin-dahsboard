import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_rule_localized_name.dart';
import '../../domain/game_rule_pattern_preview.dart';
import 'rule_pattern_preview_grid.dart';

Future<void> showGameRuleDetailDialog(
  BuildContext context, {
  required GameModel game,
}) {
  final ruleKey = game.ruleKey;
  final description =
      game.gameRule?.description ??
      GameRulePatternPreview.descriptionForRule(ruleKey) ??
      '';
  final samples = GameRulePatternPreview.samplesForRule(ruleKey);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final ruleName = game.localizedRuleName(ref);
          final theme = Theme.of(dialogContext);

          return AlertDialog(
            title: Text(dialogContext.l10n.gameRuleDetailTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ruleName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppBranding.gold,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    dialogContext.l10n.gameRulePatternSample,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: _RulePatternSamplesView(samples: samples)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  MaterialLocalizations.of(dialogContext).closeButtonLabel,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _RulePatternSamplesView extends StatefulWidget {
  const _RulePatternSamplesView({required this.samples});

  final List<GameRulePatternSample> samples;

  @override
  State<_RulePatternSamplesView> createState() =>
      _RulePatternSamplesViewState();
}

class _RulePatternSamplesViewState extends State<_RulePatternSamplesView> {
  int _sampleIndex = 0;

  bool get _hasMultipleSamples => widget.samples.length > 1;

  void _showPreviousSample() {
    setState(() {
      _sampleIndex =
          (_sampleIndex - 1 + widget.samples.length) % widget.samples.length;
    });
  }

  void _showNextSample() {
    setState(() {
      _sampleIndex = (_sampleIndex + 1) % widget.samples.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sample = widget.samples[_sampleIndex];
    final label = _hasMultipleSamples
        ? '${sample.label} of ${widget.samples.length}'
        : sample.label;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasMultipleSamples)
              IconButton.filledTonal(
                tooltip: 'Previous sample',
                onPressed: _showPreviousSample,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            if (_hasMultipleSamples) const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (_hasMultipleSamples) const SizedBox(width: 8),
            if (_hasMultipleSamples)
              IconButton.filledTonal(
                tooltip: 'Next sample',
                onPressed: _showNextSample,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
          ],
        ),
        const SizedBox(height: 8),
        RulePatternPreviewGrid(
          markedCells: sample.markedCells,
          linePatterns: sample.linePatterns,
          squarePatterns: sample.squarePatterns,
          anglePatterns: sample.anglePatterns,
        ),
      ],
    );
  }
}
