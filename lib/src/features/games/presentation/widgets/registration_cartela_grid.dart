import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../domain/cartela_availability.dart';
import '../../domain/resolved_cartela_availability.dart';
import '../controllers/registration_panel_session.dart';
import '../providers/cartela_catalog_provider.dart';
import '../providers/registration_cartela_grid_summary_provider.dart';
import '../utils/registration_cartela_grid_index.dart';
import '../utils/registration_cartela_grid_layout.dart';
import 'cartela_number_chip.dart';

class RegistrationGridScope extends InheritedWidget {
  const RegistrationGridScope({
    required this.session,
    required this.sessionId,
    required this.lockedCartelaIds,
    required this.cartelaHoldSeconds,
    required this.isGuest,
    required this.maxAffordable,
    required this.selectModeEnabledListenable,
    required super.child,
    super.key,
  });

  final RegistrationPanelSession session;
  final String? sessionId;
  final Set<String> lockedCartelaIds;
  final int cartelaHoldSeconds;
  final bool isGuest;
  final int? maxAffordable;
  final ValueListenable<int> selectModeEnabledListenable;

  static RegistrationGridScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RegistrationGridScope>();
    assert(scope != null, 'RegistrationGridScope not found in context');
    return scope!;
  }

  bool isTrackedMine(String cartelaId) {
    return session.trackedRegisteredCartelas.any(
      (registered) => registered.cartelaId == cartelaId,
    );
  }

  @override
  bool updateShouldNotify(RegistrationGridScope oldWidget) {
    return session != oldWidget.session ||
        sessionId != oldWidget.sessionId ||
        lockedCartelaIds != oldWidget.lockedCartelaIds ||
        cartelaHoldSeconds != oldWidget.cartelaHoldSeconds ||
        isGuest != oldWidget.isGuest ||
        maxAffordable != oldWidget.maxAffordable ||
        selectModeEnabledListenable != oldWidget.selectModeEnabledListenable;
  }
}

typedef RegistrationCartelaGridTapHandler =
    void Function(CartelaModel cartela, ResolvedCartelaAvailability resolved);

class RegistrationCartelaGrid extends ConsumerStatefulWidget {
  const RegistrationCartelaGrid({
    required this.searchQuery,
    required this.shuffledCartelaIds,
    required this.serverSideSearch,
    required this.session,
    required this.sessionId,
    required this.lockedCartelaIds,
    required this.cartelaHoldSeconds,
    required this.isGuest,
    required this.maxAffordable,
    required this.gridVisualRevision,
    required this.selectModeRevision,
    required this.onCartelaTap,
    required this.onCartelaLongPress,
    required this.onExpiredSelectionReservations,
    this.scrollController,
    super.key,
  });

  final String searchQuery;
  final List<String>? shuffledCartelaIds;
  final bool serverSideSearch;
  final RegistrationPanelSession session;
  final String? sessionId;
  final Set<String> lockedCartelaIds;
  final int cartelaHoldSeconds;
  final bool isGuest;
  final int? maxAffordable;
  final Listenable gridVisualRevision;
  final ValueNotifier<int> selectModeRevision;
  final RegistrationCartelaGridTapHandler onCartelaTap;
  final RegistrationCartelaGridTapHandler onCartelaLongPress;
  final ValueChanged<Set<String>> onExpiredSelectionReservations;
  final ScrollController? scrollController;

  @override
  ConsumerState<RegistrationCartelaGrid> createState() =>
      _RegistrationCartelaGridState();
}

class _RegistrationCartelaGridState extends ConsumerState<RegistrationCartelaGrid> {
  static const _loadMoreThreshold = 240.0;
  static const _reservationExpiryInterval = Duration(milliseconds: 250);

  late ScrollController _scrollController;
  var _ownsScrollController = false;
  final RegistrationCartelaGridIndex _gridIndex = RegistrationCartelaGridIndex();
  Timer? _selectionReservationTimer;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _syncSelectionReservationTimer();
    widget.gridVisualRevision.addListener(_handleGridVisualRevision);
    widget.selectModeRevision.addListener(_handleSelectModeRevision);
  }

  @override
  void didUpdateWidget(covariant RegistrationCartelaGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gridVisualRevision != widget.gridVisualRevision) {
      oldWidget.gridVisualRevision.removeListener(_handleGridVisualRevision);
      widget.gridVisualRevision.addListener(_handleGridVisualRevision);
    }
    if (oldWidget.selectModeRevision != widget.selectModeRevision) {
      oldWidget.selectModeRevision.removeListener(_handleSelectModeRevision);
      widget.selectModeRevision.addListener(_handleSelectModeRevision);
    }
    if (oldWidget.scrollController != widget.scrollController) {
      _scrollController.removeListener(_onScroll);
      if (_ownsScrollController) {
        _scrollController.dispose();
      }
      _ownsScrollController = widget.scrollController == null;
      _scrollController = widget.scrollController ?? ScrollController();
      _scrollController.addListener(_onScroll);
    }
    _syncSelectionReservationTimer();
  }

  @override
  void dispose() {
    widget.gridVisualRevision.removeListener(_handleGridVisualRevision);
    widget.selectModeRevision.removeListener(_handleSelectModeRevision);
    _selectionReservationTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleGridVisualRevision() {
    if (mounted) {
      setState(() {});
      _syncSelectionReservationTimer();
    }
  }

  void _handleSelectModeRevision() {
    if (mounted) {
      setState(() {});
    }
  }

  void scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.jumpTo(0);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final catalog = ref.read(cartelaCatalogProvider).value;
    if (catalog == null) {
      return;
    }

    final canLoadMore = catalog.isShuffled
        ? catalog.hasMoreShufflePool
        : catalog.hasMore;
    if (!canLoadMore || catalog.isLoadingMore || catalog.isSearchPending) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreThreshold) {
      return;
    }

    ref.read(cartelaCatalogProvider.notifier).loadMore();
  }

  void _syncSelectionReservationTimer() {
    final needsTimer = widget.session.selectionReservations.isNotEmpty;
    if (needsTimer && _selectionReservationTimer == null) {
      _selectionReservationTimer = Timer.periodic(
        _reservationExpiryInterval,
        (_) => _handleSelectionReservationExpiry(),
      );
    } else if (!needsTimer && _selectionReservationTimer != null) {
      _selectionReservationTimer?.cancel();
      _selectionReservationTimer = null;
    }
  }

  void _handleSelectionReservationExpiry() {
    if (!mounted) {
      return;
    }

    final clock = ref.read(serverClockProvider);
    final now = clock.isSynced ? clock.nowLocal() : DateTime.now();
    final expiredIds = widget.session.selectionReservations.entries
        .where((entry) => !entry.value.expiresAt.isAfter(now))
        .map((entry) => entry.key)
        .toSet();
    if (expiredIds.isEmpty) {
      return;
    }

    widget.onExpiredSelectionReservations(expiredIds);
    _syncSelectionReservationTimer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cartelaCatalogProvider, (previous, next) {
      final catalogState = next.asData?.value;
      if (catalogState == null || catalogState.isShuffled) {
        return;
      }

      final wasReshuffling = previous?.asData?.value.isReshuffling ?? false;
      if (wasReshuffling || catalogState.isReshuffling) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            scrollToTop();
          }
        });
      }
    });

    final catalogState = ref.watch(cartelaCatalogProvider).asData?.value;
    if (catalogState == null) {
      return const SizedBox.shrink();
    }

    _gridIndex.update(
      catalog: catalogState.items,
      searchQuery: widget.searchQuery,
      shuffledCartelaIds: widget.shuffledCartelaIds,
      serverSideSearch: widget.serverSideSearch,
    );

    if (_gridIndex.isEmpty) {
      return const SizedBox.shrink();
    }

    final extraTiles = catalogState.isLoadingMore ? 8 : 0;
    final isShuffled = catalogState.isShuffled;

    return RegistrationGridScope(
      session: widget.session,
      sessionId: widget.sessionId,
      lockedCartelaIds: widget.lockedCartelaIds,
      cartelaHoldSeconds: widget.cartelaHoldSeconds,
      isGuest: widget.isGuest,
      maxAffordable: widget.maxAffordable,
      selectModeEnabledListenable: widget.selectModeRevision,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleCount = _gridIndex.length;
          final fitsWithoutScrolling = isShuffled &&
              RegistrationCartelaGridLayout.fitsWithoutScrolling(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                itemCount: visibleCount,
              );
          final aspectRatio = fitsWithoutScrolling
              ? RegistrationCartelaGridLayout.aspectRatioForItemCount(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                  itemCount: visibleCount,
                )
              : RegistrationCartelaGridLayout.childAspectRatio;

          return GridView.builder(
            controller: _scrollController,
            primary: false,
            physics: fitsWithoutScrolling
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
            cacheExtent: fitsWithoutScrolling ? 0 : 1200,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: RegistrationCartelaGridLayout.crossAxisCount,
              mainAxisSpacing: RegistrationCartelaGridLayout.mainAxisSpacing,
              crossAxisSpacing: RegistrationCartelaGridLayout.crossAxisSpacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: visibleCount + extraTiles,
            itemBuilder: (context, index) {
              if (index >= visibleCount) {
                return const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final cartela = _gridIndex.cartelaAt(index);
              return RegistrationCartelaGridCell(
                key: ValueKey(cartela.id),
                cartela: cartela,
                onTap: widget.onCartelaTap,
                onLongPress: widget.onCartelaLongPress,
              );
            },
          );
        },
      ),
    );
  }
}

class RegistrationCartelaGridCell extends ConsumerStatefulWidget {
  const RegistrationCartelaGridCell({
    required this.cartela,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final CartelaModel cartela;
  final RegistrationCartelaGridTapHandler onTap;
  final RegistrationCartelaGridTapHandler onLongPress;

  @override
  ConsumerState<RegistrationCartelaGridCell> createState() =>
      _RegistrationCartelaGridCellState();
}

class _RegistrationCartelaGridCellState
    extends ConsumerState<RegistrationCartelaGridCell> {
  static const _countdownInterval = Duration(milliseconds: 250);

  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _syncCountdownTimer(bool needsCountdown) {
    if (needsCountdown && _countdownTimer == null) {
      _countdownTimer = Timer.periodic(_countdownInterval, (_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else if (!needsCountdown && _countdownTimer != null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  ResolvedCartelaAvailability _resolveAvailability({
    required RegistrationGridScope scope,
    required RegisteredCartelaSummary? summary,
    required ServerClockService clock,
    required bool selectModeEnabled,
  }) {
    final session = scope.session;
    final localReservation = session.selectionReservations[widget.cartela.id];
    final isSelecting =
        selectModeEnabled &&
        session.selectedCartelaIds.contains(widget.cartela.id) &&
        (session.pendingBulkReserveIds.contains(widget.cartela.id) ||
            !(localReservation?.expiresAt.isAfter(
                  clock.isSynced ? clock.nowLocal() : DateTime.now(),
                ) ??
                false));

    final resolved = resolveCartelaAvailability(
      cartela: widget.cartela,
      summary: summary,
      isTrackedMine: scope.isTrackedMine(widget.cartela.id),
      isSelecting: isSelecting,
      isReservePending: session.pendingBulkReserveIds.contains(widget.cartela.id),
      isRegistering: session.registeringCartelaIds.contains(widget.cartela.id),
      localHoldExpiresAt: localReservation?.expiresAt,
      cartelaHoldSeconds: scope.cartelaHoldSeconds,
      clock: clock,
    );

    final availability = scope.lockedCartelaIds.contains(widget.cartela.id)
        ? CartelaAvailability.taken
        : resolved.availability;

    return resolved.copyWith(availability: availability);
  }

  bool _canAddMoreSelections(RegistrationGridScope scope) {
    final maxAffordable = scope.maxAffordable;
    if (maxAffordable == null) {
      return true;
    }
    return scope.session.selectionCount < maxAffordable;
  }

  @override
  Widget build(BuildContext context) {
    final scope = RegistrationGridScope.of(context);
    final sessionId = scope.sessionId;
    final summary = sessionId == null
        ? null
        : ref.watch(
            registrationCartelaGridSummaryProvider((sessionId, widget.cartela.id)),
          );
    final clock = ref.watch(serverClockProvider);

    return ValueListenableBuilder<int>(
      valueListenable: scope.selectModeEnabledListenable,
      builder: (context, _, child) {
        final selectModeEnabled = scope.session.selectModeEnabled;
        final resolved = _resolveAvailability(
          scope: scope,
          summary: summary,
          clock: clock,
          selectModeEnabled: selectModeEnabled,
        );

        final needsCountdown = resolved.reservationSecondsRemaining != null;
        _syncCountdownTimer(needsCountdown);

        final isSelected = scope.session.selectedCartelaIds.contains(
          widget.cartela.id,
        );
        final selectBlocked =
            selectModeEnabled &&
            !isSelected &&
            !_canAddMoreSelections(scope);

        return RepaintBoundary(
          child: CartelaNumberChip(
            number: widget.cartela.number,
            availability: resolved.availability,
            isSelected: isSelected,
            selectModeEnabled: selectModeEnabled,
            isReservePending: resolved.isPending,
            isRegistering: resolved.isRegistering,
            selectBlocked: selectBlocked,
            reservationSecondsRemaining: resolved.reservationSecondsRemaining,
            onTap: () => widget.onTap(widget.cartela, resolved),
            onLongPress: () => widget.onLongPress(widget.cartela, resolved),
          ),
        );
      },
    );
  }
}
