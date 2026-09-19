import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';

/// Default visible registered-cartela chips before collapsing the rest.
const kDefaultMaxVisibleRegisteredCartelas = 10;

enum CollapsibleRegisteredCartelaChipStyle {
  registrationToolbar,
  materialChip,
  pill,
}

/// Wrap of registered cartela numbers that collapses after [maxVisible].
class CollapsibleRegisteredCartelaChips extends StatefulWidget {
  const CollapsibleRegisteredCartelaChips({
    required this.numbers,
    this.maxVisible = kDefaultMaxVisibleRegisteredCartelas,
    this.style = CollapsibleRegisteredCartelaChipStyle.registrationToolbar,
    this.onNumberTap,
    this.spacing = AppSpacing.xs,
    this.runSpacing = AppSpacing.xs,
    super.key,
  });

  final List<int> numbers;
  final int maxVisible;
  final CollapsibleRegisteredCartelaChipStyle style;
  final ValueChanged<int>? onNumberTap;
  final double spacing;
  final double runSpacing;

  @override
  State<CollapsibleRegisteredCartelaChips> createState() =>
      _CollapsibleRegisteredCartelaChipsState();
}

class _CollapsibleRegisteredCartelaChipsState
    extends State<CollapsibleRegisteredCartelaChips> {
  bool _expanded = false;

  @override
  void didUpdateWidget(CollapsibleRegisteredCartelaChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expanded &&
        widget.numbers.length <= widget.maxVisible &&
        oldWidget.numbers.length > widget.maxVisible) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numbers = widget.numbers;
    if (numbers.isEmpty) {
      return const SizedBox.shrink();
    }

    final overflow = numbers.length - widget.maxVisible;
    final showCollapsed = !_expanded && overflow > 0;
    final visibleNumbers = showCollapsed
        ? numbers.take(widget.maxVisible).toList(growable: false)
        : numbers;
    final l10n = context.l10n;

    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: [
        for (final number in visibleNumbers)
          _RegisteredCartelaChip(
            number: number,
            style: widget.style,
            onTap: widget.onNumberTap == null
                ? null
                : () => widget.onNumberTap!(number),
          ),
        if (showCollapsed)
          _ToggleChip(
            style: widget.style,
            label: l10n.registeredCartelasOverflowCount(overflow),
            tooltip: l10n.registeredCartelasShowMore,
            onTap: () => setState(() => _expanded = true),
          ),
        if (_expanded && overflow > 0)
          _ToggleChip(
            style: widget.style,
            label: l10n.registeredCartelasShowLess,
            icon: Icons.expand_less_rounded,
            onTap: () => setState(() => _expanded = false),
          ),
      ],
    );
  }
}

class _RegisteredCartelaChip extends StatelessWidget {
  const _RegisteredCartelaChip({
    required this.number,
    required this.style,
    this.onTap,
  });

  final int number;
  final CollapsibleRegisteredCartelaChipStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (style) {
      CollapsibleRegisteredCartelaChipStyle.registrationToolbar =>
        Material(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              child: Text(
                '$number',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      CollapsibleRegisteredCartelaChipStyle.materialChip => Chip(
        label: Text('#$number'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      CollapsibleRegisteredCartelaChipStyle.pill => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$number',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    };
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.style,
    required this.label,
    required this.onTap,
    this.icon,
    this.tooltip,
  });

  final CollapsibleRegisteredCartelaChipStyle style;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = switch (style) {
      CollapsibleRegisteredCartelaChipStyle.registrationToolbar => Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: _ToggleLabel(label: label, icon: icon, style: style),
          ),
        ),
      ),
      CollapsibleRegisteredCartelaChipStyle.materialChip => ActionChip(
        label: _ToggleLabel(label: label, icon: icon, style: style),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: onTap,
      ),
      CollapsibleRegisteredCartelaChipStyle.pill => Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _ToggleLabel(label: label, icon: icon, style: style),
          ),
        ),
      ),
    };

    if (tooltip == null) {
      return child;
    }

    return Tooltip(message: tooltip, child: child);
  }
}

class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    required this.label,
    required this.style,
    this.icon,
  });

  final String label;
  final CollapsibleRegisteredCartelaChipStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = switch (style) {
      CollapsibleRegisteredCartelaChipStyle.registrationToolbar =>
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      CollapsibleRegisteredCartelaChipStyle.materialChip =>
        theme.textTheme.labelMedium,
      CollapsibleRegisteredCartelaChipStyle.pill =>
        theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: textStyle?.color),
          const SizedBox(width: 2),
        ],
        Text(label, style: textStyle),
      ],
    );
  }
}
