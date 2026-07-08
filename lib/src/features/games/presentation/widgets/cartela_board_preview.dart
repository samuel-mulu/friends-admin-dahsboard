import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// Placeholder columns for instant B-I-N-G-O chrome while board numbers load.
List<List<String>> emptyCartelaBoardColumns() => [
  ['', '', '', '', ''],
  ['', '', '', '', ''],
  ['', '', 'FREE', '', ''],
  ['', '', '', '', ''],
  ['', '', '', '', ''],
];

/// Read-only B-I-N-G-O grid for cartela preview modals.
class CartelaBoardPreview extends StatelessWidget {
  const CartelaBoardPreview({
    required this.columns,
    super.key,
  });

  final List<List<String>> columns;

  @override
  Widget build(BuildContext context) {
    const headers = ['B', 'I', 'N', 'G', 'O'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppBranding.feltGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppBranding.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(headers.length, (index) {
              return Expanded(
                child: Text(
                  headers[index],
                  textAlign: TextAlign.center,
                  style: AppBranding.wordmarkGold(size: 18),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          ...List.generate(5, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(headers.length, (columnIndex) {
                  final value = columns[columnIndex].length > rowIndex
                      ? columns[columnIndex][rowIndex]
                      : '';
                  final isFree = value == 'FREE';

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isFree
                            ? AppBranding.gold
                                .withValues(alpha: isDark ? 0.25 : 0.35)
                            : AppBranding.cellBackground(context, marked: false),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFree
                              ? AppBranding.gold
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight:
                              isFree ? FontWeight.w800 : FontWeight.w600,
                          color: isFree
                              ? AppBranding.casinoPurpleDeep
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}
