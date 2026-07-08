import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../data/games_repository.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/cartela_reservation_model.dart';
import '../../domain/cartela_board_preview_cache.dart';
import 'cartela_board_preview.dart';
import 'cartela_number_badge.dart';

/// Opens a read-only bottom sheet showing the cartela B-I-N-G-O board.
Future<void> showCartelaPreviewSheet({
  required BuildContext context,
  required CartelaModel cartela,
  String? sessionId,
  String? slotId,
  bool reserveForBoardLoad = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CartelaPreviewSheet(
      cartela: cartela,
      sessionId: sessionId,
      slotId: slotId,
      reserveForBoardLoad: reserveForBoardLoad,
    ),
  );
}

Future<void> showCartelaPreviewSheetForNumber({
  required BuildContext context,
  required int number,
  CartelaModel? cartela,
  String? sessionId,
  String? slotId,
  bool reserveForBoardLoad = false,
}) {
  final resolved = cartela ??
      CartelaBoardPreviewCache.findByNumber(number) ??
      CartelaModel(
        id: '',
        number: number,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  return showCartelaPreviewSheet(
    context: context,
    cartela: resolved,
    sessionId: sessionId,
    slotId: slotId,
    reserveForBoardLoad: reserveForBoardLoad,
  );
}

class CartelaPreviewSheet extends ConsumerStatefulWidget {
  const CartelaPreviewSheet({
    required this.cartela,
    this.sessionId,
    this.slotId,
    this.reserveForBoardLoad = false,
    super.key,
  });

  final CartelaModel cartela;
  final String? sessionId;
  final String? slotId;
  final bool reserveForBoardLoad;

  @override
  ConsumerState<CartelaPreviewSheet> createState() => _CartelaPreviewSheetState();
}

class _CartelaPreviewSheetState extends ConsumerState<CartelaPreviewSheet> {
  CartelaModel? _previewCartela;
  bool _loadFailed = false;
  late final GamesRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(gamesRepositoryProvider);
    _previewCartela = _initialPreviewCartela();
    if (_previewCartela?.hasBoardValues != true) {
      unawaited(_loadBoard());
    }
  }

  CartelaModel? _initialPreviewCartela() {
    if (widget.cartela.hasBoardValues) {
      CartelaBoardPreviewCache.put(widget.cartela);
      return widget.cartela;
    }

    final cached = CartelaBoardPreviewCache.get(widget.cartela.id) ??
        CartelaBoardPreviewCache.findByNumber(widget.cartela.number);
    return cached;
  }

  List<List<String>> get _displayColumns {
    if (_previewCartela?.hasBoardValues == true) {
      return _previewCartela!.columns;
    }
    return emptyCartelaBoardColumns();
  }

  Future<void> _loadBoard() async {
    if (widget.cartela.id.isEmpty) {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
      return;
    }

    try {
      var sessionId = widget.sessionId;
      if ((sessionId == null || sessionId.isEmpty) && widget.slotId != null) {
        final slot = await _repository.getSlotDetail(widget.slotId!);
        sessionId = slot.sessionId;
      }

      if (sessionId != null && sessionId.isNotEmpty) {
        try {
          final board = await _repository.getCartelaBoard(
            cartelaId: widget.cartela.id,
            sessionId: sessionId,
          );
          _applyBoard(board);
          return;
        } catch (_) {}
      }

      if (!widget.reserveForBoardLoad) {
        if (mounted) {
          setState(() => _loadFailed = true);
        }
        return;
      }

      final CartelaReservationModel reservation;
      if (widget.slotId != null) {
        reservation = await _repository.reserveCartelaForSlot(
          slotId: widget.slotId!,
          cartelaId: widget.cartela.id,
          preserveOtherReservations: true,
        );
      } else if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        reservation = await _repository.reserveCartela(
          sessionId: widget.sessionId!,
          cartelaId: widget.cartela.id,
          preserveOtherReservations: true,
        );
      } else {
        if (mounted) {
          setState(() => _loadFailed = true);
        }
        return;
      }

      await _applyBoardFromReservation(reservation);
    } catch (_) {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  Future<void> _applyBoardFromReservation(
    CartelaReservationModel reservation,
  ) async {
    if (reservation.cartela?.hasBoardValues == true) {
      _applyBoard(reservation.cartela!);
      return;
    }

    final board = await _repository.getCartelaBoard(
      cartelaId: widget.cartela.id,
      sessionId: reservation.gameSessionId,
    );
    _applyBoard(board);
  }

  void _applyBoard(CartelaModel board) {
    final preview = widget.cartela.copyWithBoard(
      b: board.b,
      i: board.i,
      n: board.n,
      g: board.g,
      o: board.o,
    );
    CartelaBoardPreviewCache.put(preview);
    if (!mounted) {
      return;
    }
    setState(() {
      _previewCartela = preview;
      _loadFailed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBoard = _previewCartela?.hasBoardValues == true;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppBranding.casinoPurpleDeep,
                      AppBranding.casinoPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    CartelaNumberCircleBadge(
                      number: widget.cartela.number,
                      size: 52,
                      baseFontSize: 26,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cartela preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CartelaBoardPreview(columns: _displayColumns),
              if (_loadFailed && !hasBoard) ...[
                const SizedBox(height: 8),
                Text(
                  'Could not load board numbers. Try again in a moment.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
