import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_avatar_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.session?.user;
    final theme = Theme.of(context);

    if (user == null) {
      return ListView(
        padding: AppSpacing.screenPadding,
        children: const [
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Text('Profile unavailable. Please sign in again.'),
            ),
          ),
        ],
      );
    }

    final avatarId = ref.watch(profileAvatarProvider(user.id)).asData?.value;
    final walletAsync = ref.watch(myWalletProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myWalletProvider);
        ref.invalidate(profileAvatarProvider(user.id));
        await ref.read(myWalletProvider.future);
      },
      child: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                UserProfileAvatar(
                  fullName: user.fullName,
                  avatarId: avatarId,
                  radius: 40,
                  showBorder: true,
                ),
                VGap.xl,
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VGap.xs,
                Text(
                  user.phoneNumber,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                VGap.xl,
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.verified_user_outlined,
                      label: user.role.label,
                    ),
                    _InfoChip(
                      icon: Icons.bolt_outlined,
                      label: user.status.label,
                    ),
                  ],
                ),
                VGap.xl,
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _pickAvatar(context, ref, user.id, user.fullName),
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        avatarId == null ? 'Choose avatar' : 'Change avatar',
                      ),
                    ),
                    if (avatarId != null)
                      OutlinedButton(
                        onPressed: () => ref
                            .read(profileAvatarControllerProvider(user.id))
                            .setAvatar(null),
                        child: const Text('Use initials'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          VGap.xl,
          walletAsync.when(
            data: (wallet) => Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet snapshot',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    VGap.xl,
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Available',
                            value: formatMoney(wallet.balance),
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        HGap.md,
                        Expanded(
                          child: _MetricCard(
                            title: 'Locked',
                            value: formatMoney(wallet.lockedBalance),
                            icon: Icons.lock_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          VGap.xl,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  VGap.xl,
                  _ProfileDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Full name',
                    value: user.fullName,
                  ),
                  VGap.md,
                  _ProfileDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone number',
                    value: user.phoneNumber,
                  ),
                  VGap.md,
                  _ProfileDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joined',
                    value: formatDateTime(user.createdAt),
                  ),
                ],
              ),
            ),
          ),
          VGap.xl,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  VGap.sm,
                  Text(
                    'You stay signed in on this device unless you log out.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          VGap.xl,
          FilledButton.tonalIcon(
            onPressed: authState.isSubmitting
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            icon: authState.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String fullName,
  ) async {
    final currentAvatarId = ref.read(profileAvatarProvider(userId)).asData?.value;
    final result = await showAvatarPickerSheet(
      context,
      selectedAvatarId: currentAvatarId,
      previewName: fullName,
    );

    if (!context.mounted || result == null) {
      return;
    }

    await ref
        .read(profileAvatarControllerProvider(userId))
        .setAvatar(result == kClearAvatarSelection ? null : result);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          VGap.sm,
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VGap.xxs,
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        HGap.md,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              VGap.xxs,
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
