import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/l10n.dart';

class DepositSettlementAccountCard extends StatelessWidget {
  const DepositSettlementAccountCard({
    required this.settlementAccount,
    required this.receiverName,
    this.onShowInstructions,
    super.key,
  });

  final String settlementAccount;
  final String receiverName;
  final VoidCallback? onShowInstructions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final account = settlementAccount.trim();
    if (account.isEmpty) {
      return const SizedBox.shrink();
    }

    final name = receiverName.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.depositSendToAccount,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onShowInstructions != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onShowInstructions,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(l10n.depositShowInstructions),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    account,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.depositCopyAccount,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copyAccount(context, account),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                ),
              ],
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
