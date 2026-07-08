import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/avatar_preset.dart';

const kClearAvatarSelection = '__clear_avatar__';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    required this.fullName,
    this.avatarId,
    this.radius = 28,
    this.showBorder = false,
    super.key,
  });

  final String fullName;
  final String? avatarId;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final preset = avatarPresetById(avatarId);
    final theme = Theme.of(context);
    final initials = profileInitials(fullName);
    final diameter = radius * 2;

    final child = preset == null
        ? CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initials,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          )
        : Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: preset.colors,
              ),
            ),
            child: Icon(
              preset.icon,
              size: radius,
              color: Colors.white,
            ),
          );

    if (!showBorder) {
      return child;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}

Future<String?> showAvatarPickerSheet(
  BuildContext context, {
  String? selectedAvatarId,
  String previewName = 'Friends Bingo',
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AvatarPickerSheet(
      selectedAvatarId: selectedAvatarId,
      previewName: previewName,
    ),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({
    required this.selectedAvatarId,
    required this.previewName,
  });

  final String? selectedAvatarId;
  final String previewName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.jumbo,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Choose avatar',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'Optional. You can keep initials or pick one of these 10 presets.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            VGap.xl,
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pop(kClearAvatarSelection),
              child: Ink(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedAvatarId == null || selectedAvatarId!.isEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width:
                        selectedAvatarId == null || selectedAvatarId!.isEmpty
                            ? 1.6
                            : 1,
                  ),
                ),
                child: Row(
                  children: [
                    UserProfileAvatar(
                      fullName: previewName,
                      radius: 24,
                    ),
                    HGap.md,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use initials',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Fallback like SA from your name',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedAvatarId == null || selectedAvatarId!.isEmpty)
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
            VGap.xl,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kAvatarPresets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final preset = kAvatarPresets[index];
                final isSelected = preset.id == selectedAvatarId;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).pop(preset.id),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UserProfileAvatar(
                            fullName: previewName,
                            avatarId: preset.id,
                            radius: 22,
                          ),
                          VGap.xs,
                          Text(
                            preset.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
