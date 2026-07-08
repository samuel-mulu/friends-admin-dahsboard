import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

class WinnerCartelaNumberStrip extends StatelessWidget {
  const WinnerCartelaNumberStrip({
    required this.numbers,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
    super.key,
  });

  final List<int> numbers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: compact ? 34 : 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: numbers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final number = numbers[index];
          final selected = index == selectedIndex;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppBranding.casinoPurple
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? AppBranding.gold
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '#$number',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppBranding.gold
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
