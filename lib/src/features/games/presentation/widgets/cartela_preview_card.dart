import 'package:flutter/material.dart';
import '../../data/models/cartela_model.dart';

class CartelaPreviewCard extends StatelessWidget {
  const CartelaPreviewCard({
    required this.cartela,
    this.isSelected = false,
    this.onTap,
    this.trailing,
    super.key,
  });

  final CartelaModel cartela;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Cartela #${cartela.number}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  ...[trailing].whereType<Widget>(),
                ],
              ),
              const SizedBox(height: 12),
              _CartelaGrid(columns: cartela.columns),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartelaGrid extends StatelessWidget {
  const _CartelaGrid({required this.columns});

  final List<List<String>> columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const headers = ['B', 'I', 'N', 'G', 'O'];

    return Column(
      children: [
        Row(
          children: List.generate(headers.length, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  headers[index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ),
        ...List.generate(5, (rowIndex) {
          return Row(
            children: List.generate(headers.length, (columnIndex) {
              final value = columns[columnIndex].length > rowIndex
                  ? columns[columnIndex][rowIndex]
                  : '';

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: value == 'FREE'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
