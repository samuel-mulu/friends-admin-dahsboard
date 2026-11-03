import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_color.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/cartela_mark_color_provider.dart';

/// Reusable dropdown menu allowing players to select their cartela dauber ink color.
class CartelaMarkColorDropdown extends ConsumerWidget {
  const CartelaMarkColorDropdown({
    required this.iconColor,
    super.key,
  });

  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(cartelaMarkColorProvider);
    final selectedPalette = CartelaMarkColorPalette.forColor(selected);

    return PopupMenuButton<CartelaMarkColor>(
      tooltip: l10n.cartelaMarkColorMenu,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (color) =>
          ref.read(cartelaMarkColorProvider.notifier).setColor(color),
      itemBuilder: (context) {
        return CartelaMarkColor.values
            .map((color) {
              final palette = CartelaMarkColorPalette.forColor(color);
              final label = switch (color) {
                CartelaMarkColor.green => l10n.cartelaMarkColorGreen,
                CartelaMarkColor.red => l10n.cartelaMarkColorRed,
                CartelaMarkColor.yellow => l10n.cartelaMarkColorYellow,
                CartelaMarkColor.blue => l10n.cartelaMarkColorBlue,
              };

              return PopupMenuItem<CartelaMarkColor>(
                value: color,
                height: 36,
                child: Row(
                  children: [
                    CartelaMarkColorSwatch(
                      color: palette.swatch,
                      selected: color == selected,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: color == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (color == selected)
                      Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartelaMarkColorSwatch(
              color: selectedPalette.swatch,
              selected: true,
              size: 13,
            ),
            const SizedBox(width: 1),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 17,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular colored swatch displaying the active/selectable daub color.
class CartelaMarkColorSwatch extends StatelessWidget {
  const CartelaMarkColorSwatch({
    required this.color,
    required this.selected,
    required this.size,
    super.key,
  });

  final Color color;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
            width: selected ? 1.8 : 1,
          ),
        ),
      ),
    );
  }
}
