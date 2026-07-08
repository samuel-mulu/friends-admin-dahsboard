import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/security/app_lock_controller.dart';
import '../../../profile/presentation/providers/profile_avatar_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final lockState = ref.watch(appLockControllerProvider);
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
                  VGap.xl,
                  _SecurityStatusRow(
                    title: 'PIN',
                    value: lockState.hasPin ? 'Set' : 'Not set',
                    icon: Icons.pin_outlined,
                  ),
                  VGap.sm,
                  _SecurityStatusRow(
                    title: 'Biometric unlock',
                    value: lockState.isBiometricAvailable
                        ? (lockState.isBiometricEnabled
                              ? 'Enabled'
                              : 'Available')
                        : 'Not available',
                    icon: Icons.fingerprint,
                  ),
                  VGap.sm,
                  _SecurityStatusRow(
                    title: 'Auto-lock',
                    value: lockState.hasPin
                        ? 'After 60 minutes away'
                        : 'Disabled until a PIN is set',
                    icon: Icons.timer_outlined,
                  ),
                  if (lockState.isBiometricAvailable) ...[
                    VGap.xl,
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: lockState.isBiometricEnabled,
                      onChanged: lockState.hasPin
                          ? (enabled) => ref
                                .read(appLockControllerProvider.notifier)
                                .setBiometricEnabled(enabled)
                          : null,
                      title: const Text('Use biometric unlock'),
                      subtitle: Text(
                        lockState.hasPin
                            ? 'Use fingerprint or device biometric unlock when reopening after inactivity.'
                            : 'Set a 4-digit PIN first to enable biometric unlock.',
                      ),
                    ),
                  ],
                  VGap.xl,
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () => _showPinDialog(
                          context,
                          ref,
                          hasExistingPin: lockState.hasPin,
                          biometricAvailable: lockState.isBiometricAvailable,
                          biometricEnabled: lockState.isBiometricEnabled,
                        ),
                        child: Text(
                          lockState.hasPin ? 'Change PIN' : 'Set 4-digit PIN',
                        ),
                      ),
                      if (lockState.hasPin)
                        OutlinedButton(
                          onPressed: () => _confirmRemovePin(context, ref),
                          child: const Text('Remove PIN'),
                        ),
                    ],
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

  Future<void> _showPinDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool hasExistingPin,
    required bool biometricAvailable,
    required bool biometricEnabled,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _PinManagementDialog(
        hasExistingPin: hasExistingPin,
        biometricAvailable: biometricAvailable,
        biometricEnabled: biometricEnabled,
      ),
    );
  }

  Future<void> _confirmRemovePin(BuildContext context, WidgetRef ref) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'This device will stop asking for a local unlock after inactivity until you set a new PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove != true) {
      return;
    }

    await ref.read(appLockControllerProvider.notifier).clearPin();
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

class _SecurityStatusRow extends StatelessWidget {
  const _SecurityStatusRow({
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

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinManagementDialog extends ConsumerStatefulWidget {
  const _PinManagementDialog({
    required this.hasExistingPin,
    required this.biometricAvailable,
    required this.biometricEnabled,
  });

  final bool hasExistingPin;
  final bool biometricAvailable;
  final bool biometricEnabled;

  @override
  ConsumerState<_PinManagementDialog> createState() =>
      _PinManagementDialogState();
}

class _PinManagementDialogState extends ConsumerState<_PinManagementDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  late bool _enableBiometric;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _enableBiometric = widget.biometricEnabled;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hasExistingPin ? 'Change PIN' : 'Set 4-digit PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.hasExistingPin
                  ? 'Update your local unlock PIN for this device.'
                  : 'Create a 4-digit PIN for local unlock after inactivity.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
              ),
            ),
            if (widget.biometricAvailable) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _enableBiometric,
                onChanged: (value) {
                  setState(() {
                    _enableBiometric = value ?? false;
                  });
                },
                title: const Text('Enable biometric unlock'),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = 'PIN must be exactly 4 digits.';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'PIN entries did not match.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    final controller = ref.read(appLockControllerProvider.notifier);
    await controller.setPin(pin);
    await controller.setBiometricEnabled(_enableBiometric);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}
