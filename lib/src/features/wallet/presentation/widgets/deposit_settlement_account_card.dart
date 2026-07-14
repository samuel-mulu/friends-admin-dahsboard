import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.onShowInstructions,
    super.key,
  });

  final List<DepositSettlementAccountItem> accounts;
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMultiAccount
                        ? l10n.depositSendToAccounts
                        : l10n.depositSendToAccount,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onShowInstructions != null)
                  TextButton.icon(
                    onPressed: onShowInstructions,
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(l10n.depositShowInstructions),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isMultiAccount)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < visibleAccounts.length; index++) ...[
                      if (index > 0)
                        VerticalDivider(
                          width: 16,
                          thickness: 1,
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      Expanded(
                        child: _AccountColumn(
                          account: visibleAccounts[index],
                          compact: true,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              _AccountColumn(account: visibleAccounts.first),
          ],
        ),
      ),
    );
  }
}

class _AccountColumn extends StatelessWidget {
  const _AccountColumn({
    required this.account,
    this.compact = false,
  });

  final DepositSettlementAccountItem account;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final settlementAccount = account.settlementAccount.trim();
    final receiverName = account.receiverName.trim();
    final accountLabel = account.accountLabel?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accountLabel != null && accountLabel.isNotEmpty) ...[
          Text(
            accountLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: SelectableText(
                settlementAccount,
                style: (compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 0.3,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.depositCopyAccount,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _copyAccount(context, settlementAccount),
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
          ],
        ),
        if (receiverName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            receiverName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: compact ? TextAlign.start : TextAlign.start,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
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
