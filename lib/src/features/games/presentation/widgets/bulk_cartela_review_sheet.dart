import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/cartela_model.dart';
import '../../domain/bulk_register_result.dart';
import 'cartela_preview_sheet.dart';
import 'removable_cartela_number_chip.dart';

typedef BulkRegisterProgressCallback = void Function(int completed, int total);
typedef BulkRegisterHandler =
    Future<BulkRegisterResult> Function(
      List<CartelaModel> cartelas,
      BulkRegisterProgressCallback onProgress,
    );

class BulkCartelaReviewSheet extends StatefulWidget {
  const BulkCartelaReviewSheet({
    required this.selectedCartelas,
    required this.entryFee,
    required this.onRegister,
    this.sessionId,
    this.slotId,
    this.isBonus = false,
    this.isBigGotd = false,
    this.isBigGame = false,
    this.fixedPrizeAmount,
    this.maxCartelasPerPlayer,
    this.bonusCartelaBalance = 0,
    this.onCartelaRemoved,
    super.key,
  });

  final List<CartelaModel> selectedCartelas;
  final String entryFee;
  final BulkRegisterHandler onRegister;
  final String? sessionId;
  final String? slotId;
  final bool isBonus;
  final bool isBigGotd;
  final bool isBigGame;
  final String? fixedPrizeAmount;
  final int? maxCartelasPerPlayer;
  final int bonusCartelaBalance;
  final ValueChanged<CartelaModel>? onCartelaRemoved;

  @override
  State<BulkCartelaReviewSheet> createState() => _BulkCartelaReviewSheetState();
}

class _BulkCartelaReviewSheetState extends State<BulkCartelaReviewSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;
  late List<CartelaModel> _reviewCartelas;
  int _completedCount = 0;
  int _progressTotal = 0;

  @override
  void initState() {
    super.initState();
    _reviewCartelas = List<CartelaModel>.from(widget.selectedCartelas);
  }

  String _totalCostForCount(int count) {
    if (count == 0 || widget.isBonus) {
      return '0';
    }

    final entryFee = double.tryParse(widget.entryFee.trim()) ?? 0;
    final walletCartelas = _walletCartelasCharged(count);
    return (entryFee * walletCartelas).toStringAsFixed(2);
  }

  /// Welcome bonus credits apply only to normal games (not BONUS / Big GOTD / Big Game).
  bool get _canUseBonusCartelaBalance =>
      !widget.isBonus && !widget.isBigGotd && !widget.isBigGame;

  int _bonusCartelasUsed(int count) {
    if (!_canUseBonusCartelaBalance || count <= 0) {
      return 0;
    }

    return count > widget.bonusCartelaBalance
        ? widget.bonusCartelaBalance
        : count;
  }

  int _walletCartelasCharged(int count) {
    if (widget.isBonus || count <= 0) {
      return 0;
    }

    return count - _bonusCartelasUsed(count);
  }

  int get _remainingBonusAfterCommit {
    final remaining = widget.bonusCartelaBalance - _bonusCartelasUsed(_reviewCartelas.length);
    return remaining < 0 ? 0 : remaining;
  }

  List<CartelaModel> get _sortedReviewCartelas {
    final sorted = [..._reviewCartelas]
      ..sort((left, right) => left.number.compareTo(right.number));
    return sorted;
  }

  void _removeCartela(CartelaModel cartela) {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _reviewCartelas.removeWhere((item) => item.id == cartela.id);
    });
    widget.onCartelaRemoved?.call(cartela);
  }

  Future<void> _submit() async {
    if (_isSubmitting || _reviewCartelas.isEmpty) {
      return;
    }

    final total = _reviewCartelas.length;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _completedCount = 0;
      _progressTotal = total;
    });

    try {
      final result = await widget.onRegister(
        List<CartelaModel>.from(_reviewCartelas),
        (completed, progressTotal) {
          if (!mounted) {
            return;
          }

          setState(() {
            _progressTotal = progressTotal;
            _completedCount = completed.clamp(0, progressTotal);
          });
        },
      );

      if (!mounted) {
        return;
      }

      if (result.hasSuccesses) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = _failureMessage(result);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = error is Exception
            ? error.toString()
            : context.l10n.bulkRegisterError;
      });
    }
  }

  String _failureMessage(BulkRegisterResult result) {
    if (result.failures.isEmpty) {
      return context.l10n.bulkRegisterFailed;
    }

    final firstReason = result.failures.first.reason.trim();
    final sharedReason = result.failures.every(
      (failure) => failure.reason.trim() == firstReason,
    );

    if (sharedReason && firstReason.isNotEmpty) {
      return firstReason;
    }

    final takenNumbers = result.failures
        .map((failure) => '#${failure.cartelaNumber}')
        .join(', ');
    return context.l10n.bulkRegisterTaken(takenNumbers);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sorted = _sortedReviewCartelas;
    final totalCost = _totalCostForCount(sorted.length);
    final bonusUsed = _bonusCartelasUsed(sorted.length);
    final walletCartelas = _walletCartelasCharged(sorted.length);
    final canRegister = sorted.isNotEmpty;
    final bonusLimit = widget.maxCartelasPerPlayer ?? 5;
    final hasFreeEntry = widget.isBonus;

    return PopScope(
      canPop: !_isSubmitting,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isSubmitting
                      ? l10n.bulkRegisteringTitle
                      : l10n.bulkReviewTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  hasFreeEntry
                      ? '${sorted.length} free cartela${sorted.length == 1 ? '' : 's'} selected'
                      : l10n.bulkCartelasTotal(
                          sorted.length,
                          formatMoney(totalCost),
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!hasFreeEntry && sorted.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    walletCartelas > 0 && bonusUsed > 0
                        ? '$bonusUsed bonus • $walletCartelas wallet • ${formatMoney(totalCost)}'
                        : bonusUsed > 0
                        ? '$bonusUsed bonus cartela${bonusUsed == 1 ? '' : 's'}'
                        : '${formatMoney(totalCost)} total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.bonusCartelaBalance > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Bonus after commit: $_remainingBonusAfterCommit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
                const SizedBox(height: 6),
                Text(
                  hasFreeEntry
                      ? [
                          l10n.gameBonusFreeEntry,
                          if (widget.fixedPrizeAmount != null)
                            l10n.gameBonusFixedPrize(
                              formatMoney(widget.fixedPrizeAmount!),
                            ),
                          l10n.gameBonusMaxCartelas(bonusLimit),
                        ].join(' • ')
                      : widget.isBigGotd
                      ? [
                          context.l10n.gameCategoryBigGotd,
                          '${context.l10n.bigGameEntryFee}: ${formatMoney(widget.entryFee)}',
                          if (widget.fixedPrizeAmount != null)
                            l10n.gameBonusFixedPrize(
                              formatMoney(widget.fixedPrizeAmount!),
                            ),
                          l10n.gameBonusMaxCartelas(bonusLimit),
                        ].join(' • ')
                      : widget.isBigGame
                      ? [
                          l10n.gameCategoryBigGame,
                          if (widget.fixedPrizeAmount != null)
                            l10n.gameBonusFixedPrize(
                              formatMoney(widget.fixedPrizeAmount!),
                            ),
                          if (widget.maxCartelasPerPlayer != null)
                            l10n.gameBonusMaxCartelas(bonusLimit),
                        ].join(' • ')
                      : l10n.bulkPerCartela(formatMoney(widget.entryFee)),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (sorted.isEmpty)
                  Text(
                    l10n.bulkReviewEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: sorted.length > 8 ? 168 : 120,
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final cartela in sorted)
                            RemovableCartelaNumberChip(
                              key: ValueKey(cartela.id),
                              number: cartela.number,
                              enabled: !_isSubmitting,
                              registrationStatus: _isSubmitting
                                  ? BulkChipRegistrationStatus.pending
                                  : BulkChipRegistrationStatus.idle,
                              onTap: () => showCartelaPreviewSheet(
                                context: context,
                                cartela: cartela,
                                sessionId: widget.sessionId,
                                slotId: widget.slotId,
                                // Board API requires an active hold; bulk
                                // select no longer pre-reserves, so reserve
                                // briefly here to load numbers for preview.
                                reserveForBoardLoad: true,
                              ),
                              onRemove: () => _removeCartela(cartela),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_isSubmitting) ...[
                  const SizedBox(height: 20),
                  _BulkRegisterProgressPanel(
                    completed: _completedCount,
                    total: _progressTotal,
                    progressLabel: l10n.bulkProgress(
                      _completedCount >= _progressTotal && _progressTotal > 0
                          ? _progressTotal
                          : _completedCount,
                      _progressTotal,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Text(
                    canRegister ? l10n.bulkConfirmHint : l10n.bulkReviewEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.bulkCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting || !canRegister
                            ? null
                            : _submit,
                        child: _isSubmitting
                            ? Text(
                                hasFreeEntry
                                    ? 'Registering…'
                                    : l10n.bulkRegistering,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : Text(
                                hasFreeEntry
                                    ? 'Register Free ${sorted.length}'
                                    : l10n.bulkRegisterCount(sorted.length),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkRegisterProgressPanel extends StatelessWidget {
  const _BulkRegisterProgressPanel({
    required this.completed,
    required this.total,
    required this.progressLabel,
  });

  final int completed;
  final int total;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percent = total > 0 ? (progress * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppBranding.casinoPurple.withValues(alpha: isDark ? 0.42 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppBranding.gold.withValues(alpha: 0.5)
              : AppBranding.brandPurple.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 3.5,
                      backgroundColor: AppBranding.brandPurple.withValues(
                        alpha: isDark ? 0.55 : 0.14,
                      ),
                      color: AppBranding.brandAccentValue(context),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      total > 0 ? '$completed' : '—',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppBranding.brandHighlightText(context),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progressLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppBranding.brandHighlightText(context),
                        height: 1.25,
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$percent% complete',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (total > 0)
                Text(
                  '$completed/$total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppBranding.brandAccentValue(context),
                    letterSpacing: -0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  final fill = animatedProgress <= 0 && total > 0
                      ? 0.06
                      : animatedProgress.clamp(0.0, 1.0);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: AppBranding.brandPurple.withValues(
                          alpha: isDark ? 0.55 : 0.12,
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fill,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      AppBranding.gold.withValues(alpha: 0.92),
                                      AppBranding.gold,
                                    ]
                                  : [
                                      AppBranding.brandPurple
                                          .withValues(alpha: 0.75),
                                      AppBranding.brandPurple,
                                    ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
