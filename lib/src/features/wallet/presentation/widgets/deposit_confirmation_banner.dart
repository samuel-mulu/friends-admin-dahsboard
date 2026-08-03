import 'package:flutter/material.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../models/deposit_confirmation_state.dart';

class DepositConfirmationBanner extends StatefulWidget {
  const DepositConfirmationBanner({
    required this.state,
    required this.onDismiss,
    super.key,
  });

  final DepositConfirmationState state;
  final VoidCallback onDismiss;

  @override
  State<DepositConfirmationBanner> createState() =>
      _DepositConfirmationBannerState();
}

class _DepositConfirmationBannerState extends State<DepositConfirmationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DepositConfirmationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.switchKey != widget.state.switchKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Card(
          elevation: 0,
          color: _backgroundColor(theme),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _borderColor(theme)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusIcon(kind: widget.state.kind),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title(l10n),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.state.kind ==
                              DepositConfirmationKind.pending) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.depositPendingMessage,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          if (widget.state.kind ==
                              DepositConfirmationKind.rejected) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.state.message ?? l10n.depositTryAgain,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.depositTryAgain,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (widget.state.kind ==
                              DepositConfirmationKind.verifying) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.depositVerifying,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.state.kind != DepositConfirmationKind.verifying)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onDismiss,
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                  ],
                ),
                if (widget.state.kind == DepositConfirmationKind.approved ||
                    widget.state.kind == DepositConfirmationKind.pending) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: l10n.depositSelectProvider,
                    value: widget.state.provider?.label ?? '',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.depositAmount,
                    value: widget.state.amount != null
                        ? '${formatMoney(widget.state.amount!)} ETB'
                        : '',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.depositReceiptCode,
                    value: widget.state.transactionRef ?? '',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(dynamic l10n) {
    return switch (widget.state.kind) {
      DepositConfirmationKind.verifying => l10n.depositVerifying,
      DepositConfirmationKind.approved => l10n.depositApprovedTitle,
      DepositConfirmationKind.pending => l10n.depositPendingTitle,
      DepositConfirmationKind.rejected => l10n.depositRejectedTitle,
    };
  }

  Color _backgroundColor(ThemeData theme) {
    return switch (widget.state.kind) {
      DepositConfirmationKind.verifying =>
        AppBranding.casinoPurple.withValues(alpha: 0.18),
      DepositConfirmationKind.approved =>
        AppBranding.feltGreen.withValues(alpha: 0.14),
      DepositConfirmationKind.pending =>
        theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
      DepositConfirmationKind.rejected =>
        theme.colorScheme.error.withValues(alpha: 0.12),
    };
  }

  Color _borderColor(ThemeData theme) {
    return switch (widget.state.kind) {
      DepositConfirmationKind.verifying =>
        AppBranding.casinoPurple.withValues(alpha: 0.35),
      DepositConfirmationKind.approved =>
        AppBranding.feltGreen.withValues(alpha: 0.45),
      DepositConfirmationKind.pending =>
        theme.colorScheme.outline.withValues(alpha: 0.35),
      DepositConfirmationKind.rejected =>
        theme.colorScheme.error.withValues(alpha: 0.35),
    };
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.kind});

  final DepositConfirmationKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (kind == DepositConfirmationKind.verifying) {
      return SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppBranding.goldAccent,
        ),
      );
    }

    final isApproved = kind == DepositConfirmationKind.approved;
    final isPending = kind == DepositConfirmationKind.pending;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isApproved
            ? AppBranding.feltGreen
            : isPending
            ? AppBranding.goldAccent
            : theme.colorScheme.error,
      ),
      child: Icon(
        isApproved
            ? Icons.check_rounded
            : isPending
            ? Icons.schedule_rounded
            : Icons.close_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
