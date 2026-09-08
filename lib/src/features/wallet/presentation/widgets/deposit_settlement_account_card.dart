import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';

class DepositSettlementAccountItem {
  const DepositSettlementAccountItem({
    required this.settlementAccount,
    required this.receiverName,
    this.accountLabel,
  });

  final String settlementAccount;
  final String receiverName;
  final String? accountLabel;
}

class DepositSettlementAccountCard extends StatelessWidget {
  const DepositSettlementAccountCard({
    required this.accounts,
    this.providerName,
    this.helpText,
    this.onShowInstructions,
    super.key,
  });

  final List<DepositSettlementAccountItem> accounts;
  final String? providerName;
  final String? helpText;
  final VoidCallback? onShowInstructions;

  @override
  Widget build(BuildContext context) {
    final visibleAccounts = accounts
        .where((account) => account.settlementAccount.trim().isNotEmpty)
        .toList(growable: false);
    if (visibleAccounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isMultiAccount = visibleAccounts.length > 1;
    final trimmedHelp = helpText?.trim();
    final provider = providerName?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isMultiAccount
                    ? l10n.depositSendToOneOfAccounts
                    : l10n.depositSendToAccount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onShowInstructions != null)
              IconButton(
                tooltip: l10n.depositShowInstructions,
                onPressed: onShowInstructions,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.menu_book_outlined, size: 20),
              ),
          ],
        ),
        if (provider != null && provider.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.depositOnlyUseProvider(provider),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (trimmedHelp != null && trimmedHelp.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            trimmedHelp,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 10),
        for (var index = 0; index < visibleAccounts.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _CompactAccountTile(
            account: visibleAccounts[index],
            showSendHint: isMultiAccount,
          ),
        ],
      ],
    );
  }
}

class _CompactAccountTile extends StatelessWidget {
  const _CompactAccountTile({
    required this.account,
    this.showSendHint = false,
  });

  final DepositSettlementAccountItem account;
  final bool showSendHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final settlementAccount = account.settlementAccount.trim();
    final receiverName = account.receiverName.trim();
    final accountLabel = account.accountLabel?.trim();

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppBranding.casinoPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (accountLabel != null && accountLabel.isNotEmpty) ...[
                    Text(
                      accountLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    settlementAccount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppBranding.casinoPurple,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1.15,
                    ),
                  ),
                  if (receiverName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      receiverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (showSendHint) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.depositCopyThenSend,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _copyAccount(context, settlementAccount),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(l10n.depositCopyAccount),
              style: FilledButton.styleFrom(
                backgroundColor: AppBranding.casinoPurple,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: const StadiumBorder(),
                textStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyAccount(BuildContext context, String account) async {
    await Clipboard.setData(ClipboardData(text: account));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.depositAccountCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
