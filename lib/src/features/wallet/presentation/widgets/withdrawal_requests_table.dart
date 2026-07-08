import 'package:flutter/material.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/withdrawal_model.dart';

enum WithdrawalHistoryFilter { all, pending, completed, rejected }

class WithdrawalRequestsTable extends StatefulWidget {
  const WithdrawalRequestsTable({
    required this.withdrawals,
    this.compact = false,
    this.initialFilter = WithdrawalHistoryFilter.all,
    super.key,
  });

  final List<WithdrawalModel> withdrawals;
  final bool compact;
  final WithdrawalHistoryFilter initialFilter;

  @override
  State<WithdrawalRequestsTable> createState() =>
      _WithdrawalRequestsTableState();
}

class _WithdrawalRequestsTableState extends State<WithdrawalRequestsTable>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialFilter.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pendingCount = widget.withdrawals
        .where((w) => w.status == WithdrawalStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppBranding.casinoPurple,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: AppBranding.goldAccent,
          tabs: [
            Tab(text: l10n.withdrawTabAll),
            Tab(
              child: _PendingTabLabel(
                label: l10n.withdrawTabPending,
                count: pendingCount,
              ),
            ),
            Tab(text: l10n.withdrawTabCompleted),
            Tab(text: l10n.withdrawTabRejected),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final filter = WithdrawalHistoryFilter.values[_tabController.index];
            final items = _filter(widget.withdrawals, filter);

            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _emptyMessage(l10n, filter),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return _WithdrawalDataTable(
              items: items,
              compact: widget.compact,
              statusLabel: (status) => _statusLabel(l10n, status),
            );
          },
        ),
      ],
    );
  }

  List<WithdrawalModel> _filter(
    List<WithdrawalModel> items,
    WithdrawalHistoryFilter filter,
  ) {
    return switch (filter) {
      WithdrawalHistoryFilter.all => items,
      WithdrawalHistoryFilter.pending =>
        items.where((w) => w.status == WithdrawalStatus.pending).toList(),
      WithdrawalHistoryFilter.completed => items
          .where(
            (w) =>
                w.status == WithdrawalStatus.paid ||
                w.status == WithdrawalStatus.approved,
          )
          .toList(),
      WithdrawalHistoryFilter.rejected => items
          .where(
            (w) =>
                w.status == WithdrawalStatus.rejected ||
                w.status == WithdrawalStatus.failed ||
                w.status == WithdrawalStatus.refunded,
          )
          .toList(),
    };
  }

  String _emptyMessage(dynamic l10n, WithdrawalHistoryFilter filter) {
    return switch (filter) {
      WithdrawalHistoryFilter.pending => l10n.withdrawPendingEmpty,
      WithdrawalHistoryFilter.completed => l10n.withdrawCompletedEmpty,
      WithdrawalHistoryFilter.rejected => l10n.withdrawRejectedEmpty,
      WithdrawalHistoryFilter.all => l10n.withdrawHistoryEmptyMessage,
    };
  }

  String _statusLabel(dynamic l10n, WithdrawalStatus status) {
    return switch (status) {
      WithdrawalStatus.pending => l10n.withdrawStatusPendingReview,
      WithdrawalStatus.paid || WithdrawalStatus.approved =>
        l10n.withdrawStatusApproved,
      WithdrawalStatus.rejected => l10n.withdrawStatusRejected,
      WithdrawalStatus.failed => l10n.withdrawStatusFailed,
      WithdrawalStatus.refunded => l10n.withdrawStatusRefunded,
    };
  }
}

class _PendingTabLabel extends StatelessWidget {
  const _PendingTabLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppBranding.goldAccent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppBranding.brandPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _WithdrawalDataTable extends StatelessWidget {
  const _WithdrawalDataTable({
    required this.items,
    required this.compact,
    required this.statusLabel,
  });

  final List<WithdrawalModel> items;
  final bool compact;
  final String Function(WithdrawalStatus status) statusLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: compact ? 3 : 2,
                  child: Text(
                    l10n.withdrawTableDate,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.withdrawTableAmount,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!compact)
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.withdrawTableProvider,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Expanded(
                  flex: compact ? 3 : 2,
                  child: Text(
                    l10n.withdrawTableStatus,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final withdrawal = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: compact ? 3 : 2,
                      child: Text(
                        formatDateTime(withdrawal.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${formatMoney(withdrawal.amount)} ETB',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!compact)
                      Expanded(
                        flex: 2,
                        child: Text(
                          withdrawal.provider.label,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    Expanded(
                      flex: compact ? 3 : 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _StatusPill(
                          label: statusLabel(withdrawal.status),
                          status: withdrawal.status,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.status});

  final String label;
  final WithdrawalStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = switch (status) {
      WithdrawalStatus.pending => theme.colorScheme.surfaceContainerHigh,
      WithdrawalStatus.paid || WithdrawalStatus.approved =>
        theme.colorScheme.primaryContainer,
      WithdrawalStatus.rejected => theme.colorScheme.errorContainer,
      _ => theme.colorScheme.surfaceContainerHighest,
    };
    final foreground = switch (status) {
      WithdrawalStatus.paid || WithdrawalStatus.approved =>
        theme.colorScheme.onPrimaryContainer,
      WithdrawalStatus.rejected => theme.colorScheme.onErrorContainer,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
