part of 'live_game_screen.dart';

void _bulkDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('[bulk_debug] $message');
  }
}

mixin _LiveGameRegistration on _LiveGameOrchestration {
  void _handleRegistrationSessionResolved(String sessionId) {
    if (!mounted || sessionId.isEmpty) {
      return;
    }

    final game = _game;
    if (game != null && game.sessionId != sessionId) {
      setState(() {
        _game = game.copyWith(sessionId: sessionId);
      });
    }

    _applySocketSessionMembership(sessionId);
    ref.invalidate(registrationStateProvider(sessionId));
  }

  void _handleQueuedRegistrationSessionResolved(String sessionId) {
    if (!mounted || sessionId.isEmpty) {
      return;
    }

    setState(() {
      final nextGame = _nextUpcomingGame;
      if (nextGame != null && nextGame.sessionId != sessionId) {
        _nextUpcomingGame = nextGame.copyWith(sessionId: sessionId);
      }
    });

    _applySocketSessionMembership(sessionId);
    ref.invalidate(registrationStateProvider(sessionId));
    _scheduleCanonicalRefetch(
      wallet: false,
      registrationSessionId: sessionId,
    );
  }

  void _handleCartelasRegistered(List<GameCartelaModel> registeredCartelas) {
    _registration.handleCartelasRegistered(registeredCartelas);
  }
}

void _applyMineRegistrationPatches(
  String sessionId,
  List<GameCartelaModel> registeredCartelas, {
  required WidgetRef ref,
  LiveRegistrationController? registration,
}) {
  if (registration != null) {
    registration.applyRegistrationPatch(sessionId, registeredCartelas);
    return;
  }

  if (registeredCartelas.isEmpty) {
    return;
  }

  final actorUserId = ref.read(authControllerProvider).session?.user.id;
  ref
      .read(registrationStatePatchProvider.notifier)
      .applyChanges(
        sessionId,
        registeredCartelas
            .map(
              (cartela) => RegistrationCartelaChange(
                cartelaId: cartela.cartelaId,
                cartelaNumber: cartela.cartela.number,
                owner: 'ME',
                actorUserId: actorUserId,
              ),
            )
            .toList(growable: false),
      );
}

class CartelaRegistrationPanel extends ConsumerStatefulWidget {
  const CartelaRegistrationPanel({
    required this.registration,
    required this.slotId,
    required this.sessionId,
    required this.gameStatus,
    required this.entryFee,
    required this.prizePerCartela,
    this.category = GameCategory.normal,
    this.fixedPrizeAmount,
    this.maxCartelasPerPlayer,
    this.roundPrizes,
    required this.registeredCartelas,
    required this.cartelaHoldSeconds,
    required this.bulkSelectionSeconds,
    required this.onRegistered,
    this.isGuest = false,
    this.onSessionIdResolved,
    this.autoOpenCartelaNumbers,
    this.onAutoOpenConsumed,
    this.lockedCartelaIds = const {},
    super.key,
  });

  final LiveRegistrationController registration;
  final String slotId;
  final String? sessionId;
  final GameStatus gameStatus;
  final String entryFee;
  final String prizePerCartela;
  final GameCategory category;
  final String? fixedPrizeAmount;
  final int? maxCartelasPerPlayer;
  final List<String>? roundPrizes;
  final List<GameCartelaModel> registeredCartelas;
  final int cartelaHoldSeconds;
  final int bulkSelectionSeconds;
  final bool isGuest;
  final ValueChanged<List<GameCartelaModel>> onRegistered;
  final ValueChanged<String>? onSessionIdResolved;
  final List<int>? autoOpenCartelaNumbers;
  final VoidCallback? onAutoOpenConsumed;
  final Set<String> lockedCartelaIds;

  @override
  ConsumerState<CartelaRegistrationPanel> createState() =>
      _CartelaRegistrationPanelState();
}

class _CartelaRegistrationPanelState
    extends ConsumerState<CartelaRegistrationPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _cartelaSheetOpen = false;
  Future<BulkRegisterResult>? _bulkRegisterInFlight;
  bool _autoOpenConsumed = false;
  bool _autoOpenScheduled = false;
  List<String>? _shuffledCartelaIds;
  bool _preferBigGameTicket = true;

  final ValueNotifier<int> _gridVisualRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> _selectModeRevision = ValueNotifier<int>(0);

  Map<String, RegisteredCartelaSummary>? _summaryByCartelaIdCache;
  String? _summaryCacheKey;
  Map<String, CartelaModel> _catalogById = const {};
  String _catalogByIdVersion = '';
  String _shuffledCatalogVersion = '';
  List<CartelaModel>? _lastShuffledCatalogItems;

  RegistrationPanelSession get _session =>
      widget.registration.panelSessionFor(widget.slotId);

  ServerClockService get _serverClock => ref.read(serverClockProvider);

  DateTime _reservationNow() {
    final clock = _serverClock;
    if (clock.isSynced) {
      return clock.nowLocal();
    }
    return DateTime.now();
  }

  String? get _effectiveSessionId =>
      widget.registration.effectiveSessionIdFor(
        widget.slotId,
        widgetSessionId: widget.sessionId,
        registeredCartelas: widget.registeredCartelas,
      );

  RegistrationLimitKind get _registrationLimitKind {
    if (_isBonus) {
      return RegistrationLimitKind.bonus;
    }
    if (_isBigGotd) {
      return RegistrationLimitKind.bigGotd;
    }
    if (_isChainGame) {
      return RegistrationLimitKind.chainGame;
    }
    return RegistrationLimitKind.normal;
  }

  void _handleRegistrationActionResult(RegistrationActionResult result) {
    switch (result) {
      case RegistrationGuestRequired():
        unawaited(showGuestAuthPromptSheet(context));
      case RegistrationInsufficientBalance(
        :final maxAffordable,
        :final limitKind,
      ):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_insufficientBalanceMessage(maxAffordable, limitKind)),
          ),
        );
      case RegistrationNetworkError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      case RegistrationActionSuccess(:final resolvedSessionId):
        if (resolvedSessionId != null && resolvedSessionId.isNotEmpty) {
          _handleSessionIdResolved(resolvedSessionId);
        }
      case RegistrationActionIgnored():
      case RegistrationCartelaUnavailable():
      case RegistrationValidationError():
      case RegistrationReserveFlushCancelled():
        break;
    }
  }

  String _insufficientBalanceMessage(
    int? maxAffordable,
    RegistrationLimitKind limitKind,
  ) {
    final l10n = context.l10n;
    return switch (limitKind) {
      RegistrationLimitKind.bonus =>
        maxAffordable == null || maxAffordable < 1
            ? 'You have already used all free cartelas for this bonus game.'
            : 'You can still register up to $maxAffordable more free cartela${maxAffordable == 1 ? '' : 's'} for this bonus game.',
      RegistrationLimitKind.bigGotd =>
        maxAffordable == null || maxAffordable < 1
            ? (_isCartelaCountLimitReached() &&
                    !_isWalletBalanceLimited(_walletBalanceValue())
                ? l10n.registrationBigGotdLimitReached
                : l10n.registrationInsufficientBalance)
            : l10n.registrationBigGotdCanRegisterMore(maxAffordable),
      RegistrationLimitKind.chainGame =>
        maxAffordable == null || maxAffordable < 1
            ? (_isCartelaCountLimitReached() &&
                    !_isWalletBalanceLimited(_walletBalanceValue())
                ? l10n.registrationChainLimitReached
                : l10n.registrationInsufficientBalance)
            : l10n.registrationChainCanRegisterMore(maxAffordable),
      RegistrationLimitKind.normal =>
        maxAffordable == null || maxAffordable < 1
            ? (_isCartelaCountLimitReached() &&
                    !_isWalletBalanceLimited(_walletBalanceValue())
                ? l10n.registrationNormalLimitReached
                : l10n.registrationInsufficientBalanceRegister)
            : _hasNormalCartelaCap
            ? l10n.registrationNormalCanRegisterMore(maxAffordable)
            : l10n.registrationBalanceAllowsUpTo(maxAffordable),
    };
  }

  String _insufficientBalanceSelectionMessage(
    int? maxAffordable,
    RegistrationLimitKind limitKind,
  ) {
    final l10n = context.l10n;
    return switch (limitKind) {
      RegistrationLimitKind.bonus =>
        maxAffordable == null || maxAffordable < 1
            ? 'You have already used all free cartelas for this bonus game.'
            : 'You can still register up to $maxAffordable more free cartela${maxAffordable == 1 ? '' : 's'} for this bonus game.',
      RegistrationLimitKind.bigGotd =>
        maxAffordable == null || maxAffordable < 1
            ? (_isCartelaCountLimitReached() &&
                    !_isWalletBalanceLimited(_walletBalanceValue())
                ? l10n.registrationBigGotdAllCartelasUsed
                : l10n.registrationInsufficientBalanceSelect)
            : l10n.registrationBigGotdCanSelectMore(maxAffordable),
      RegistrationLimitKind.chainGame =>
        maxAffordable == null || maxAffordable < 1
            ? (_isCartelaCountLimitReached() &&
                    !_isWalletBalanceLimited(_walletBalanceValue())
                ? l10n.registrationChainAllCartelasUsed
                : l10n.registrationInsufficientBalanceSelect)
            : l10n.registrationChainCanSelectMore(maxAffordable),
      RegistrationLimitKind.normal =>
        maxAffordable == null || maxAffordable < 1
            ? (_isCartelaCountLimitReached() &&
                    !_isWalletBalanceLimited(_walletBalanceValue())
                ? l10n.registrationNormalAllCartelasUsed
                : l10n.registrationInsufficientBalanceSelect)
            : _hasNormalCartelaCap
            ? l10n.registrationNormalCanSelectMore(maxAffordable)
            : l10n.registrationBalanceAllowsUpTo(maxAffordable),
    };
  }

  bool get _isBonus => widget.category == GameCategory.bonus;

  bool get _isBigGotd => widget.category == GameCategory.bigGotd;

  bool get _isBonusLike => widget.category.isBonusLike;

  bool get _isNormalGame => widget.category == GameCategory.normal;

  bool get _hasNormalCartelaCap =>
      _isNormalGame && widget.maxCartelasPerPlayer != null;

  bool get _hasFreeEntry => widget.category.hasFreeEntry;

  bool get _canUseBonusCartelaBalance =>
      widget.category.canUseBonusCartelaBalance;

  bool get _isBigGame => widget.category == GameCategory.bigGame;

  bool get _isChainGame => widget.category == GameCategory.chainGame;

  int get _bonusCartelaLimit => widget.maxCartelasPerPlayer ?? 5;

  int get _bigGameTicketBalance {
    final walletAsync = ref.read(myWalletProvider);
    return walletAsync is AsyncData<WalletModel>
        ? walletAsync.value.bigGameTicketBalance
        : 0;
  }

  bool get _canChooseBigTicketPayment =>
      _isBigGame && _bigGameTicketBalance > 0;

  bool get _usingBigGameTicket =>
      _canChooseBigTicketPayment && _preferBigGameTicket;

  String? get _bigGamePaymentSource {
    if (!_isBigGame) {
      return null;
    }
    return _usingBigGameTicket
        ? CartelaPaymentSource.bigGameTicket
        : CartelaPaymentSource.moneyWallet;
  }

  int _currentMineCount(List<RegisteredCartelaSummary> summary) {
    final mineIds = <String>{
      for (final item in summary)
        if (item.isMine || item.isReservedByMe) item.cartelaId,
      for (final item in _session.trackedRegisteredCartelas) item.cartelaId,
    };
    return mineIds.length;
  }

  int? _bonusRemainingSelections() {
    if (!_isBonusLike) {
      return null;
    }

    final sessionId = _effectiveSessionId;
    if (_hasFreeEntry && sessionId != null) {
      final state = ref
          .read(registrationStateProvider(sessionId))
          .asData
          ?.value;
      final serverRemaining = state?.remainingFreeCartelas;
      if (serverRemaining != null) {
        return serverRemaining < 0 ? 0 : serverRemaining;
      }
    }

    final remaining =
        _bonusCartelaLimit - _currentMineCount(_currentRegistrationSummary());
    return remaining < 0 ? 0 : remaining;
  }

  void _syncTrackedRegisteredCartelasFromWidget({bool forceReplace = false}) {
    if (forceReplace) {
      _session.trackedRegisteredCartelas =
          List<GameCartelaModel>.from(widget.registeredCartelas)..sort(
            (left, right) =>
                left.cartela.number.compareTo(right.cartela.number),
          );
      return;
    }

    if (widget.registeredCartelas.isEmpty) {
      return;
    }

    _session.trackedRegisteredCartelas =
        mergeRegisteredCartelas(
          current: _session.trackedRegisteredCartelas,
          incoming: widget.registeredCartelas,
          sessionId: _effectiveSessionId,
        )..sort(
          (left, right) => left.cartela.number.compareTo(right.cartela.number),
        );
  }

  void _notifyRegistered(List<GameCartelaModel> registeredCartelas) {
    if (registeredCartelas.isEmpty) {
      return;
    }

    final sessionId = registeredCartelas.first.gameId;
    setState(() {
      if (sessionId.isNotEmpty) {
        _session.resolvedSessionId = sessionId;
      }
      _session.trackedRegisteredCartelas =
          mergeRegisteredCartelas(
            current: _session.trackedRegisteredCartelas,
            incoming: registeredCartelas,
            sessionId: sessionId,
          )..sort(
            (left, right) =>
                left.cartela.number.compareTo(right.cartela.number),
          );
    });
    _applyMineRegistrationPatches(
      sessionId,
      registeredCartelas,
      ref: ref,
      registration: widget.registration,
    );
    ref.invalidate(registrationStateProvider(sessionId));
    widget.onSessionIdResolved?.call(sessionId);
    widget.onRegistered(registeredCartelas);
  }

  void _handleSessionIdResolved(String sessionId) {
    if (sessionId.isEmpty) {
      return;
    }

    if (_session.resolvedSessionId != sessionId) {
      setState(() => _session.resolvedSessionId = sessionId);
      ref.invalidate(registrationStateProvider(sessionId));
    }

    widget.onSessionIdResolved?.call(sessionId);
  }

  List<RegisteredCartelaSummary> _currentRegistrationSummary() {
    final sessionId = _effectiveSessionId;
    if (sessionId == null) {
      return const [];
    }

    final state = ref.read(registrationStateProvider(sessionId)).asData?.value;
    final patchState = registrationStatePatchForSession(
      ref.read(registrationStatePatchProvider),
      sessionId,
    );

    return mergeRegistrationStateWithPatches(
      snapshot: state,
      patches: patchState.patches,
      removedCartelaIds: patchState.removedCartelaIds,
      sessionId: sessionId,
    );
  }

  @override
  void initState() {
    super.initState();
    _session.resolvedSessionId = widget.sessionId;
    _session.trackedRegisteredCartelas = List<GameCartelaModel>.from(
      widget.registeredCartelas,
    );
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query == _searchQuery) {
        return;
      }
      setState(() {
        _searchQuery = query;
      });
    });

    final initialSessionId = widget.sessionId;
    if (initialSessionId != null && initialSessionId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        widget.onSessionIdResolved?.call(initialSessionId);
      });
    }
  }

  @override
  void didUpdateWidget(covariant CartelaRegistrationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slotChanged = oldWidget.slotId != widget.slotId;
    final sessionReset = _session.syncSessionId(widget.sessionId);
    _syncTrackedRegisteredCartelasFromWidget(
      forceReplace: slotChanged || sessionReset,
    );
    if (slotChanged || sessionReset) {
      _bumpGridVisual();
      _bumpSelectModeVisual();
    }
    if (oldWidget.autoOpenCartelaNumbers != widget.autoOpenCartelaNumbers) {
      _autoOpenConsumed = false;
      _autoOpenScheduled = false;
    }
  }

  @override
  void dispose() {
    _session.bulkReserveGeneration += 1;
    _session.bulkReserveDebounceTimer?.cancel();
    _gridVisualRevision.dispose();
    _selectModeRevision.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _bumpGridVisual() {
    _gridVisualRevision.value++;
  }

  void _bumpSelectModeVisual() {
    _selectModeRevision.value++;
  }

  void _applyCatalogShuffleOrder(CartelaCatalogState catalogState) {
    if (catalogState.isShuffled) {
      if (identical(catalogState.items, _lastShuffledCatalogItems) &&
          _shuffledCartelaIds != null) {
        return;
      }
      final version = RegistrationCartelaGridIndex.versionForCatalog(
        catalogState.items,
      );
      if (version == _shuffledCatalogVersion && _shuffledCartelaIds != null) {
        _lastShuffledCatalogItems = catalogState.items;
        return;
      }
      _lastShuffledCatalogItems = catalogState.items;
      _shuffledCatalogVersion = version;
      _shuffledCartelaIds =
          catalogState.items.map((cartela) => cartela.id).toList();
      return;
    }

    _lastShuffledCatalogItems = null;
    _shuffledCatalogVersion = '';
    _shuffledCartelaIds = null;
  }

  void _syncCatalogById(List<CartelaModel> cartelas) {
    final version = RegistrationCartelaGridIndex.versionForCatalog(cartelas);
    if (version == _catalogByIdVersion) {
      return;
    }

    _catalogByIdVersion = version;
    _catalogById = {for (final cartela in cartelas) cartela.id: cartela};
  }

  String _registrationSummaryCacheKey(
    List<RegisteredCartelaSummary> summaries,
  ) {
    if (summaries.isEmpty) {
      return 'empty';
    }

    return summaries
        .map(
          (summary) =>
              '${summary.cartelaId}:${summary.owner}:${summary.expiresAt?.millisecondsSinceEpoch ?? 0}',
        )
        .join('|');
  }

  List<CartelaModel> _buildSelectedCartelasForReview() {
    return _session.selectedCartelaIds
        .map((id) {
          final cached = CartelaBoardPreviewCache.get(id);
          if (cached != null) {
            return cached;
          }

          final catalogCartela = _catalogById[id];
          if (catalogCartela != null) {
            return catalogCartela;
          }

          return CartelaModel(
            id: id,
            number: _session.selectedCartelaNumbers[id]!,
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .toList(growable: false);
  }

  int? get _selectionSecondsRemaining {
    return null;
  }

  String get _selectedTotalCost {
    final count = _session.selectionCount;
    if (count == 0 || _hasFreeEntry || _usingBigGameTicket) {
      return '0';
    }
    final bonusCartelas = _usableBonusCartelaBalance;
    final paidCount = count > bonusCartelas ? count - bonusCartelas : 0;
    return (_parseMoney(widget.entryFee) * paidCount).toStringAsFixed(2);
  }

  int get _bonusCartelaBalance {
    final walletAsync = ref.read(myWalletProvider);
    return walletAsync is AsyncData<WalletModel>
        ? walletAsync.value.bonusCartelaBalance
        : 0;
  }

  int get _usableBonusCartelaBalance =>
      _canUseBonusCartelaBalance ? _bonusCartelaBalance : 0;

  String? _selectedRemainingBalance(String? walletBalance) {
    if (_hasFreeEntry || _usingBigGameTicket) {
      return null;
    }
    if (walletBalance == null) {
      return null;
    }

    final remaining =
        _parseMoney(walletBalance) - _parseMoney(_selectedTotalCost);
    return remaining < 0 ? '0.00' : remaining.toStringAsFixed(2);
  }

  int? _cartelaLimitRemaining() {
    if (_isChainGame || _hasNormalCartelaCap) {
      final max = widget.maxCartelasPerPlayer;
      if (max == null) {
        return null;
      }
      return remainingCartelaLimit(
        maxPerPlayer: max,
        alreadyRegistered: _currentMineCount(_currentRegistrationSummary()),
      );
    }
    if (!_isBonusLike) {
      return null;
    }
    return _bonusRemainingSelections();
  }

  int? _moneyAffordableSelections(String? walletBalance) {
    if (_hasFreeEntry) {
      return null;
    }
    if (walletBalance == null) {
      return null;
    }

    final entryFee = _parseMoney(widget.entryFee);
    if (entryFee <= 0) {
      return null;
    }

    final moneyAffordable = (_parseMoney(walletBalance) / entryFee).floor();
    return _usableBonusCartelaBalance + moneyAffordable;
  }

  bool _isCartelaCountLimitReached() {
    final limit = _cartelaLimitRemaining();
    return limit != null && limit < 1;
  }

  bool _isWalletBalanceLimited(String? walletBalance) {
    if (_hasFreeEntry) {
      return false;
    }
    if (!_isBigGotd && !_isChainGame && !_hasNormalCartelaCap) {
      return false;
    }
    final money = _moneyAffordableSelections(walletBalance);
    return money != null && money < 1;
  }

  String? _walletBalanceValue() {
    if (_hasFreeEntry) {
      return null;
    }
    final walletAsync = ref.read(myWalletProvider);
    return walletAsync is AsyncData<WalletModel>
        ? walletAsync.value.balance
        : null;
  }

  int? _maxAffordableSelections(String? walletBalance) {
    if (_isBonus) {
      return _cartelaLimitRemaining();
    }
    if (_isBigGotd) {
      return minCartelaSelectionCap(
        _cartelaLimitRemaining(),
        _moneyAffordableSelections(walletBalance),
      );
    }
    if (_isBigGame || _isChainGame) {
      final byPayment = _usingBigGameTicket
          ? _bigGameTicketBalance
          : _moneyAffordableSelections(walletBalance);
      return minCartelaSelectionCap(_cartelaLimitRemaining(), byPayment);
    }
    return minCartelaSelectionCap(
      _cartelaLimitRemaining(),
      _moneyAffordableSelections(walletBalance),
    );
  }

  bool _canAddMoreSelections(String? walletBalance) {
    final maxAffordable = _maxAffordableSelections(walletBalance);
    if (maxAffordable == null) {
      return true;
    }

    return _session.selectionCount < maxAffordable;
  }

  void _setSelectModeEnabled(
    bool enabled, {
    _RegisterCartelaOption? initialOption,
  }) {
    if (!enabled) {
      widget.registration.exitSelectMode(widget.slotId);
      if (mounted) {
        setState(() {});
        _bumpSelectModeVisual();
        _bumpGridVisual();
      }
      return;
    }

    final walletBalanceForSelection = _walletBalanceValue();
    final maxAffordable = _maxAffordableSelections(walletBalanceForSelection);
    final result = widget.registration.enterSelectMode(
      slotId: widget.slotId,
      isGuest: widget.isGuest,
      maxAffordable: maxAffordable,
      limitKind: _registrationLimitKind,
    );

    if (result is RegistrationGuestRequired) {
      _handleRegistrationActionResult(result);
      return;
    }
    if (result is RegistrationInsufficientBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _insufficientBalanceMessage(result.maxAffordable, result.limitKind),
          ),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {});
      _bumpSelectModeVisual();
      _bumpGridVisual();
    }

    if (initialOption != null &&
        initialOption.availability == CartelaAvailability.available &&
        _canAddMoreSelections(walletBalanceForSelection)) {
      unawaited(_toggleCartelaSelection(initialOption));
    }
  }

  Future<void> _toggleCartelaSelection(_RegisterCartelaOption option) async {
    final walletBalance = _walletBalanceValue();
    final result = widget.registration.toggleCartelaSelection(
      slotId: widget.slotId,
      cartela: RegistrationCartelaSelectionInput(
        cartelaId: option.cartela.id,
        cartelaNumber: option.cartela.number,
        availability: option.availability,
      ),
      maxAffordable: _maxAffordableSelections(walletBalance),
      limitKind: _registrationLimitKind,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case RegistrationInsufficientBalance(
        :final maxAffordable,
        :final limitKind,
      ):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _insufficientBalanceSelectionMessage(maxAffordable, limitKind),
            ),
          ),
        );
      case RegistrationActionSuccess():
        setState(() {});
        _bumpGridVisual();
      default:
        break;
    }
  }

  void _clearSelection() {
    widget.registration.cancelSelection(widget.slotId);
    if (mounted) {
      setState(() {});
      _bumpGridVisual();
    }
  }

  Future<void> _reserveCartelasForSelection(
    List<_RegisterCartelaOption> options,
  ) async {
    for (final option in options) {
      await _toggleCartelaSelection(option);
    }
  }

  Future<void> _unselectReservedCartela(_RegisterCartelaOption option) async {
    final result = await widget.registration.unselectReservedCartela(
      slotId: widget.slotId,
      cartelaId: option.cartela.id,
      cartelaNumber: option.cartela.number,
      widgetSessionId: widget.sessionId,
      registeredCartelas: widget.registeredCartelas,
    );
    if (!mounted) {
      return;
    }
    _handleRegistrationActionResult(result);
    setState(() {});
    _bumpGridVisual();
  }

  void _forgetSelectionReservations(
    Set<String> cartelaIds, {
    bool cancelOnServer = true,
  }) {
    widget.registration.forgetSelectionReservations(
      slotId: widget.slotId,
      cartelaIds: cartelaIds,
      cancelOnServer: cancelOnServer,
    );
    if (mounted) {
      setState(() {});
      _bumpGridVisual();
    }
  }

  Future<void> _openReviewSheet() async {
    if (_session.reviewSheetOpen || _session.selectedCartelaIds.isEmpty || widget.isGuest) {
      return;
    }

    final walletBalance = _walletBalanceValue();
    final maxAffordable = _maxAffordableSelections(walletBalance);

    if (maxAffordable != null && _session.selectedCartelaIds.length > maxAffordable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _insufficientBalanceSelectionMessage(
              maxAffordable,
              _registrationLimitKind,
            ),
          ),
        ),
      );
      return;
    }

    // KISS: No flush reserve needed, just open review sheet with selected cartelas
    if (_session.selectedCartelaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cartelas selected. Please select cartelas first.'),
        ),
      );
      return;
    }

    setState(() => _session.reviewSheetOpen = true);

    final selectedCartelas = _buildSelectedCartelasForReview();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BulkCartelaReviewSheet(
          selectedCartelas: selectedCartelas,
          entryFee: widget.entryFee,
          sessionId: _effectiveSessionId,
          slotId: widget.slotId,
          isBonus: _isBonus,
          isBigGotd: _isBigGotd,
          isBigGame: _isBigGame,
          isChainGame: widget.category == GameCategory.chainGame,
          fixedPrizeAmount: widget.fixedPrizeAmount,
          maxCartelasPerPlayer: widget.maxCartelasPerPlayer,
          bonusCartelaBalance: _usableBonusCartelaBalance,
          bigGameTicketBalance: _usingBigGameTicket ? _bigGameTicketBalance : 0,
          onCartelaRemoved: (cartela) {
            unawaited(
              _unselectReservedCartela(
                _RegisterCartelaOption(
                  cartela: cartela,
                  resolved: ResolvedCartelaAvailability(
                    cartelaId: cartela.id,
                    cartelaNumber: cartela.number,
                    availability: CartelaAvailability.reservedByMe,
                  ),
                ),
              ),
            );
          },
          onRegister: (cartelas, onProgress) =>
              _bulkRegister(cartelas: cartelas, onProgress: onProgress),
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _session.reviewSheetOpen = false;
      if (confirmed == true) {
        // KISS: Just clear local selection state
        _bulkDebugLog('review_sheet_confirmed clearing_selection');
        _session.selectModeEnabled = false;
        _session.selectedCartelaIds.clear();
        _session.selectedCartelaNumbers.clear();
      }
    });
  }

  Future<BulkRegisterResult> _bulkRegister({
    required List<CartelaModel> cartelas,
    required BulkRegisterProgressCallback onProgress,
  }) async {
    if (cartelas.isEmpty) {
      return const BulkRegisterResult(successes: [], failures: []);
    }

    if (_bulkRegisterInFlight != null) {
      return _bulkRegisterInFlight!;
    }

    _bulkRegisterInFlight = _bulkRegisterInternal(
      cartelas: cartelas,
      onProgress: onProgress,
    );
    try {
      return await _bulkRegisterInFlight!;
    } finally {
      _bulkRegisterInFlight = null;
    }
  }

  Future<BulkRegisterResult> _bulkRegisterInternal({
    required List<CartelaModel> cartelas,
    required BulkRegisterProgressCallback onProgress,
  }) async {
    // KISS: No flush reserve, no hold checks - just register selected cartelas
    _bulkDebugLog('bulk_register_start count=${cartelas.length}');

    if (!mounted || cartelas.isEmpty) {
      return const BulkRegisterResult(successes: [], failures: []);
    }

    final cartelaIds = cartelas.map((cartela) => cartela.id).toSet();
    final registeringIds = cartelaIds;

    setState(() {
      _session.registeringCartelaIds
        ..clear()
        ..addAll(registeringIds);
    });

    try {
      final payload = cartelas
          .map(
            (cartela) => (cartelaId: cartela.id, cartelaNumber: cartela.number),
          )
          .toList(growable: false);

      final result = await ref
          .read(gamesRepositoryProvider)
          .registerCartelasForSlot(
            slotId: widget.slotId,
            sessionId: _effectiveSessionId ?? widget.sessionId,
            cartelas: payload,
            paymentSource: _bigGamePaymentSource,
            onProgress: onProgress,
          );

      if (!mounted) {
        return result;
      }

      ref.invalidate(myWalletProvider);

      if (result.hasSuccesses) {
        // KISS: Just notify and clear selection
        _bulkDebugLog('bulk_register_success count=${result.successes.length}');
        _notifyRegistered(result.myCartelas ?? result.successes);

        // Clear selected state for successfully registered cartelas
        setState(() {
          for (final success in result.successes) {
            _session.selectedCartelaIds.remove(success.cartelaId);
            _session.selectedCartelaNumbers.remove(success.cartelaId);
          }
        });
      }

      if (result.hasFailures) {
        // KISS: Remove conflicted cartelas from selection and show message
        _bulkDebugLog('bulk_register_failures count=${result.failures.length}');

        setState(() {
          for (final failure in result.failures) {
            _session.selectedCartelaIds.remove(failure.cartelaId);
            _session.selectedCartelaNumbers.remove(failure.cartelaId);
          }
        });

        final message = _bulkRegisterMessage(result);
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }

        // Refresh registration state to show updated availability
        final sessionId = _effectiveSessionId;
        if (sessionId != null) {
          ref.invalidate(registrationStateProvider(sessionId));
        }
      }

      return result;
    } on ApiException catch (error) {
      if (!mounted) {
        rethrow;
      }

      if (isRegistrationClosedError(error) || isSessionNotReadyError(error)) {
        await handleRegistrationWindowClosed(
          ref,
          context: context,
          error: error,
        );
        return const BulkRegisterResult(successes: [], failures: []);
      }

      rethrow;
    } finally {
      if (mounted) {
        setState(() => _session.registeringCartelaIds.clear());
      }
    }
  }

  String? _bulkRegisterMessage(BulkRegisterResult result) {
    if (!result.hasFailures) {
      return null;
    }

    final limitReached = result.failures.any(
      (failure) => failure.reason == 'BONUS_CARTELA_LIMIT_REACHED',
    );
    if (limitReached) {
      return 'You can register up to $_bonusCartelaLimit free cartelas for this bonus game.';
    }

    final takenNumbers = result.failures
        .map((failure) => '#${failure.cartelaNumber}')
        .join(', ');

    final alreadyRegistered = result.failures.every(
      (failure) =>
          failure.reason.contains('already registered') ||
          failure.reason.contains('already taken'),
    );

    final successCount = result.successes.length;
    if (!result.hasSuccesses) {
      if (alreadyRegistered) {
        return 'Those cartelas are already registered for this round.';
      }
      return 'Could not register selected cartelas. $takenNumbers already taken.';
    }

    return 'Registered $successCount cartela${successCount == 1 ? '' : 's'}. $takenNumbers taken.';
  }

  void _scheduleAutoOpenIfNeeded(List<CartelaModel> loadedCartelas) {
    if (widget.gameStatus == GameStatus.playing ||
        widget.gameStatus == GameStatus.checking ||
        widget.gameStatus == GameStatus.winnerWindow) {
      _autoOpenConsumed = true;
      widget.onAutoOpenConsumed?.call();
      return;
    }

    final numbers = widget.autoOpenCartelaNumbers;
    if (_autoOpenConsumed ||
        _autoOpenScheduled ||
        numbers == null ||
        numbers.isEmpty ||
        widget.isGuest) {
      return;
    }

    _autoOpenScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resolveAutoOpenMatches(loadedCartelas, numbers));
    });
  }

  Future<void> _resolveAutoOpenMatches(
    List<CartelaModel> loadedCartelas,
    List<int> numbers,
  ) async {
    if (!mounted) {
      return;
    }

    try {
      final cartelasByNumber = <int, CartelaModel>{
        for (final cartela in loadedCartelas) cartela.number: cartela,
      };
      final missingNumbers = numbers
          .where((number) => !cartelasByNumber.containsKey(number))
          .toList(growable: false);

      if (missingNumbers.isNotEmpty) {
        final repository = ref.read(cartelasRepositoryProvider);
        for (final number in missingNumbers) {
          final page = await repository.getCartelasPage(
            search: number.toString(),
            limit: 20,
          );
          for (final cartela in page.items) {
            if (cartela.number == number) {
              cartelasByNumber[number] = cartela;
            }
          }
        }
      }

      if (!mounted) {
        return;
      }

      final matches = <_RegisterCartelaOption>[];
      final summaryByCartelaId = _summaryByCartelaId(
        _currentRegistrationSummary(),
      );
      for (final number in numbers) {
        final cartela = cartelasByNumber[number];
        if (cartela == null) {
          continue;
        }
        matches.add(
          _resolveRegisterOption(
            cartela: cartela,
            summaryByCartelaId: summaryByCartelaId,
          ),
        );
      }

      final consumed = _consumeAutoOpen(numbers, matches);
      if (!consumed) {
        _autoOpenScheduled = false;
      }
    } catch (_) {
      if (mounted) {
        _autoOpenScheduled = false;
      }
    }
  }

  bool _consumeAutoOpen(
    List<int> numbers,
    List<_RegisterCartelaOption> options,
  ) {
    if (_autoOpenConsumed) {
      return true;
    }

    if (widget.gameStatus == GameStatus.playing ||
        widget.gameStatus == GameStatus.checking ||
        widget.gameStatus == GameStatus.winnerWindow) {
      _autoOpenConsumed = true;
      widget.onAutoOpenConsumed?.call();
      return true;
    }

    final registeredNumbers = widget.registeredCartelas
        .map((cartela) => cartela.cartela.number)
        .toSet();
    final pendingNumbers = numbers
        .where((number) => !registeredNumbers.contains(number))
        .toList(growable: false);
    if (pendingNumbers.isEmpty) {
      _autoOpenConsumed = true;
      widget.onAutoOpenConsumed?.call();
      return true;
    }

    final matches = options
        .where((option) => pendingNumbers.contains(option.cartela.number))
        .toList(growable: false);

    if (matches.isEmpty) {
      return false;
    }

    final actionableMatches = matches
        .where(
          (option) =>
              option.availability == CartelaAvailability.available ||
              option.availability == CartelaAvailability.reservedByMe,
        )
        .toList(growable: false);

    if (actionableMatches.isEmpty) {
      _autoOpenConsumed = true;
      widget.onAutoOpenConsumed?.call();
      return true;
    }

    _autoOpenConsumed = true;
    widget.onAutoOpenConsumed?.call();

    if (pendingNumbers.length == 1) {
      final match = actionableMatches.first;
      unawaited(_openCartelaModal(match));
      return true;
    }

    _setSelectModeEnabled(true);
    unawaited(
      _reserveCartelasForSelection(
        actionableMatches,
      ).then((_) => _openReviewSheet()),
    );

    return true;
  }

  void _handleCartelaTap(CartelaModel cartela, ResolvedCartelaAvailability resolved) {
    final option = _RegisterCartelaOption(cartela: cartela, resolved: resolved);
    if (_session.selectModeEnabled) {
      unawaited(_toggleCartelaSelection(option));
      return;
    }

    unawaited(_openCartelaModal(option));
  }

  void _handleCartelaLongPress(
    CartelaModel cartela,
    ResolvedCartelaAvailability resolved,
  ) {
    final option = _RegisterCartelaOption(cartela: cartela, resolved: resolved);
    if (widget.isGuest) {
      unawaited(showGuestAuthPromptSheet(context));
      return;
    }

    if (_session.registeringCartelaIds.isNotEmpty ||
        _session.selectModeEnabled ||
        option.availability != CartelaAvailability.available) {
      return;
    }

    _setSelectModeEnabled(true, initialOption: option);
  }

  List<int> _toolbarRegisteredNumbers(String? sessionId) {
    final numbers = <int>{
      for (final cartela in _session.trackedRegisteredCartelas)
        cartela.cartela.number,
    };

    if (sessionId == null) {
      return numbers.toList()..sort();
    }

    final snapshot = ref.watch(registrationStateProvider(sessionId)).asData?.value;
    if (snapshot != null) {
      for (final summary in snapshot.registeredCartelasSummary) {
        if (summary.isMine) {
          numbers.add(summary.cartelaNumber);
        }
      }
    }

    final patchMineKey = ref.watch(
      registrationStatePatchProvider.select((all) {
        final patchState = all[sessionId];
        if (patchState == null) {
          return '';
        }

        final mineNumbers = <int>[
          for (final summary in patchState.patches.values)
            if (summary.isMine) summary.cartelaNumber,
        ]..sort();
        return mineNumbers.join(',');
      }),
    );
    if (patchMineKey.isNotEmpty) {
      for (final raw in patchMineKey.split(',')) {
        final parsed = int.tryParse(raw);
        if (parsed != null) {
          numbers.add(parsed);
        }
      }
    }

    return numbers.toList()..sort();
  }

  void _requestShuffleReshuffle() {
    if (!mounted) {
      return;
    }

    unawaited(ref.read(cartelaCatalogProvider.notifier).reshuffle());
  }

  void _openChainRoundsFromRegistration() {
    final prizes = widget.roundPrizes;
    if (prizes == null || prizes.isEmpty || !mounted) {
      return;
    }
    unawaited(
      showChainGameRoundsDialog(
        context: context,
        plan: ChainRoundPlan(
          sessionId: widget.sessionId ?? '',
          roundCount: prizes.length,
          currentRound: 1,
          totalPrizeAmount: widget.fixedPrizeAmount ?? widget.prizePerCartela,
          currentRoundPrizeAmount: prizes.first,
          rounds: [
            for (var i = 0; i < prizes.length; i++)
              ChainRoundPlanEntry(
                roundIndex: i + 1,
                prizeAmount: prizes[i],
                state: i == 0
                    ? ChainRoundState.current
                    : ChainRoundState.upcoming,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cartelaCatalogProvider, (previous, next) {
      final catalogState = next.asData?.value;
      if (catalogState == null) {
        return;
      }

      _applyCatalogShuffleOrder(catalogState);
    });

    final cartelasAsync = ref.watch(cartelaCatalogProvider);
    final wallet = widget.isGuest
        ? null
        : switch (ref.watch(myWalletProvider)) {
            AsyncData(:final value) => value,
            _ => null,
          };
    final snapshotSessionId = _effectiveSessionId;
    final registeredNumbers = _toolbarRegisteredNumbers(snapshotSessionId);
    final maxAffordable = _maxAffordableSelections(wallet?.balance);
    final remainingBonusCartelas = _isBonusLike ||
            _isChainGame ||
            _isBigGame ||
            _hasNormalCartelaCap
        ? _cartelaLimitRemaining()
        : null;
    if (snapshotSessionId != null) {
      ref.listen(registrationStateProvider(snapshotSessionId), (
        previous,
        next,
      ) {
        next.whenData((state) {
          if (state.sessionId == snapshotSessionId) {
            ref
                .read(registrationStatePatchProvider.notifier)
                .onSnapshotLoaded(snapshotSessionId, snapshot: state);
          }
        });
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationCatalogControls(
          registeredNumbers: registeredNumbers,
          walletBalance: wallet?.balance,
          bonusCartelaBalance: _usableBonusCartelaBalance,
          bigGameTicketBalance: _bigGameTicketBalance,
          preferBigGameTicket: _preferBigGameTicket,
          onPreferBigGameTicketChanged: _canChooseBigTicketPayment
              ? (value) {
                  setState(() => _preferBigGameTicket = value);
                }
              : null,
          isFirstTimePlayer: wallet?.isFirstTimePlayer ?? false,
          selectModeEnabled: _session.selectModeEnabled,
          maxAffordableSelections: maxAffordable,
          remainingBonusCartelas: remainingBonusCartelas,
          category: widget.category,
          entryFee: widget.entryFee,
          fixedPrizeAmount: widget.fixedPrizeAmount,
          maxCartelasPerPlayer: widget.maxCartelasPerPlayer,
          roundPrizes: widget.roundPrizes,
          selectedCount: _session.selectionCount,
          remainingBalance: _selectedRemainingBalance(wallet?.balance),
          onSelectModeChanged: _setSelectModeEnabled,
          isGuest: widget.isGuest,
          searchController: _searchController,
          onReshuffle: _requestShuffleReshuffle,
          onRegisteredNumberTap: _handleRegisteredNumberTap,
          onViewChainRounds: _isChainGame &&
                  (widget.roundPrizes ?? const []).isNotEmpty
              ? _openChainRoundsFromRegistration
              : null,
        ),
        if (_session.registeringCartelaIds.isNotEmpty) ...[
          VGap.sm,
          RegistrationBulkBanner(count: _session.registeringCartelaIds.length),
        ],
        if (!widget.isGuest && !_session.selectModeEnabled) ...[
          VGap.xxs,
          const RegistrationTapHint(isGuest: false, selectModeEnabled: false),
        ],
        VGap.sm,
        Expanded(
          child: cartelasAsync.when(
            data: (catalogState) {
              if (catalogState.isReshuffling) {
                return const FriendsBingoLoader.inline(compact: true);
              }

              _syncCatalogById(catalogState.items);
              _scheduleAutoOpenIfNeeded(catalogState.items);
              _applyCatalogShuffleOrder(catalogState);

              if (catalogState.items.isEmpty) {
                return const _LiveInfoCard(
                  title: 'No matches',
                  message: 'Try another number.',
                );
              }

              return RegistrationCartelaGrid(
                searchQuery: _searchQuery,
                // Keep shuffle order only when not searching; search sorts by number.
                shuffledCartelaIds: _searchQuery.isEmpty && catalogState.isShuffled
                    ? _shuffledCartelaIds
                    : null,
                serverSideSearch: false,
                session: _session,
                sessionId: snapshotSessionId,
                lockedCartelaIds: widget.lockedCartelaIds,
                cartelaHoldSeconds: widget.cartelaHoldSeconds,
                isGuest: widget.isGuest,
                maxAffordable: maxAffordable,
                gridVisualRevision: _gridVisualRevision,
                selectModeRevision: _selectModeRevision,
                onCartelaTap: _handleCartelaTap,
                onCartelaLongPress: _handleCartelaLongPress,
                onExpiredSelectionReservations: _forgetSelectionReservations,
              );
            },
            loading: () => const FriendsBingoLoader.inline(compact: true),
            error: (error, _) => _LiveInfoCard(
              title: 'Could not load cartelas',
              message: error is ApiException
                  ? error.message
                  : 'Please try again.',
            ),
          ),
        ),
        RegistrationActionDock(
          isGuest: widget.isGuest,
          selectModeEnabled: _session.selectModeEnabled,
          selectionSecondsRemaining: _selectionSecondsRemaining,
          selectedCount: _session.selectionCount,
          maxAffordableSelections: maxAffordable,
          remainingBalance: _selectedRemainingBalance(wallet?.balance),
          onReview: () => unawaited(_openReviewSheet()),
          onCancelSelection: _clearSelection,
          onExitSelectMode: () => _setSelectModeEnabled(false),
        ),
      ],
    );
  }

  Future<void> _openCartelaModal(_RegisterCartelaOption option) async {
    // Debug guard: Detect if modal is called during select mode
    if (_session.selectModeEnabled) {
      _bulkDebugLog(
        'BLOCK_SINGLE_MODAL selectMode=true cartela=${option.cartela.number}',
      );
      return;
    }

    final alreadyOwned = option.availability == CartelaAvailability.mine;
    var carriedForward = false;
    if (alreadyOwned) {
      final sessionId = _effectiveSessionId ?? widget.sessionId;
      final summaries = sessionId == null
          ? const <RegisteredCartelaSummary>[]
          : ref
                    .read(registrationStateProvider(sessionId))
                    .asData
                    ?.value
                    .registeredCartelasSummary ??
                const <RegisteredCartelaSummary>[];
      carriedForward = summaries.any(
        (s) => s.cartelaId == option.cartela.id && s.isCarriedForward,
      );
    }
    if ((!option.resolved.isAvailable && !alreadyOwned) || _cartelaSheetOpen) {
      return;
    }

    RegistrationUxMetrics.modalOpened();

    if (widget.isGuest) {
      await showGuestAuthPromptSheet(context);
      return;
    }

    final walletAsync = ref.read(myWalletProvider);
    final walletBalance = walletAsync is AsyncData<WalletModel>
        ? walletAsync.value.balance
        : null;
    final bonusCartelaBalance = _usableBonusCartelaBalance;
    final bigGameTicketBalance = _bigGameTicketBalance;
    final isFirstTimePlayer = walletAsync is AsyncData<WalletModel>
        ? walletAsync.value.isFirstTimePlayer
        : false;

    setState(() => _cartelaSheetOpen = true);

    GameCartelaModel? registeredCartela;
    try {
      registeredCartela = await showModalBottomSheet<GameCartelaModel?>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        showDragHandle: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return CartelaRegistrationSheet(
            cartela: option.cartela,
            entryFee: widget.entryFee,
            walletBalance: walletBalance,
            bonusCartelaBalance: bonusCartelaBalance,
            bigGameTicketBalance: bigGameTicketBalance,
            isFirstTimePlayer: isFirstTimePlayer,
            slotId: widget.slotId,
            sessionId: widget.sessionId,
            cartelaHoldSeconds: widget.cartelaHoldSeconds,
            category: widget.category,
            fixedPrizeAmount: widget.fixedPrizeAmount,
            maxCartelasPerPlayer: widget.maxCartelasPerPlayer,
            initialPaymentSource: _bigGamePaymentSource,
            onSessionIdResolved: alreadyOwned ? null : _handleSessionIdResolved,
            alreadyOwned: alreadyOwned,
            carriedForward: carriedForward,
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _cartelaSheetOpen = false);
      }
    }

    if (!mounted || registeredCartela == null || alreadyOwned) {
      return;
    }

    _notifyRegistered([registeredCartela]);
  }

  CartelaModel? _findCartelaModelByNumber(int number) {
    for (final cartela in _catalogById.values) {
      if (cartela.number == number) {
        return cartela;
      }
    }
    for (final registered in widget.registeredCartelas) {
      if (registered.cartela.number == number) {
        return registered.cartela;
      }
    }
    for (final registered in _session.trackedRegisteredCartelas) {
      if (registered.cartela.number == number) {
        return registered.cartela;
      }
    }
    return null;
  }

  void _handleRegisteredNumberTap(int number) {
    if (_session.selectModeEnabled || _cartelaSheetOpen) {
      return;
    }

    final cartela = _findCartelaModelByNumber(number);
    if (cartela == null) {
      return;
    }

    unawaited(
      _openCartelaModal(
        _RegisterCartelaOption(
          cartela: cartela,
          resolved: ResolvedCartelaAvailability(
            cartelaId: cartela.id,
            cartelaNumber: cartela.number,
            availability: CartelaAvailability.mine,
          ),
        ),
      ),
    );
  }

  Map<String, RegisteredCartelaSummary> _summaryByCartelaId(
    List<RegisteredCartelaSummary> summaries,
  ) {
    final cacheKey = _registrationSummaryCacheKey(summaries);
    if (cacheKey == _summaryCacheKey && _summaryByCartelaIdCache != null) {
      return _summaryByCartelaIdCache!;
    }

    _summaryCacheKey = cacheKey;
    _summaryByCartelaIdCache = {
      for (final summary in summaries) summary.cartelaId: summary,
    };
    return _summaryByCartelaIdCache!;
  }

  _RegisterCartelaOption _resolveRegisterOption({
    required CartelaModel cartela,
    required Map<String, RegisteredCartelaSummary> summaryByCartelaId,
  }) {
    final trackedMine = _session.trackedRegisteredCartelas.any(
      (registered) => registered.cartelaId == cartela.id,
    );
    final summary = summaryByCartelaId[cartela.id];
    final localReservation = _session.selectionReservations[cartela.id];
    final isSelecting =
        _session.selectModeEnabled &&
        _session.selectedCartelaIds.contains(cartela.id) &&
        (_session.pendingBulkReserveIds.contains(cartela.id) ||
            !(_session.selectionReservations[cartela.id]?.expiresAt.isAfter(
                  _reservationNow(),
                ) ??
                false));

    final resolved = resolveCartelaAvailability(
      cartela: cartela,
      summary: summary,
      isTrackedMine: trackedMine,
      isSelecting: isSelecting,
      isReservePending: _session.pendingBulkReserveIds.contains(cartela.id),
      isRegistering: _session.registeringCartelaIds.contains(cartela.id),
      localHoldExpiresAt: localReservation?.expiresAt,
      cartelaHoldSeconds: widget.cartelaHoldSeconds,
      clock: _serverClock,
    );
    final availability = widget.lockedCartelaIds.contains(cartela.id)
        ? CartelaAvailability.taken
        : resolved.availability;

    return _RegisterCartelaOption(
      cartela: cartela,
      resolved: resolved.copyWith(availability: availability),
    );
  }
}

class _RegisterCartelaOption {
  const _RegisterCartelaOption({required this.cartela, required this.resolved});

  final CartelaModel cartela;
  final ResolvedCartelaAvailability resolved;

  CartelaAvailability get availability => resolved.availability;

  int? get reservationSecondsRemaining => resolved.reservationSecondsRemaining;
}

double _parseMoney(String value) => double.tryParse(value.trim()) ?? 0;
