import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';

/// Display order for the registration number grid without materializing every
/// [CartelaModel] into option rows on each availability patch.
class RegistrationCartelaGridIndex {
  List<CartelaModel> _catalog = const [];
  List<int> _displayIndices = const [];
  String _searchQuery = '';
  bool _serverSideSearch = false;
  List<String>? _shuffledCartelaIds;
  int? _shuffledOrderHash;
  String _catalogVersion = '';
  Map<String, int>? _cachedShuffleIndex;
  int? _cachedShuffleOrderHash;

  int get length => _displayIndices.length;

  bool get isEmpty => _displayIndices.isEmpty;

  static String versionForCatalog(List<CartelaModel> catalog) {
    if (catalog.isEmpty) {
      return 'empty';
    }

    var idsHash = 0;
    for (var i = 0; i < catalog.length; i++) {
      idsHash = Object.hash(idsHash, catalog[i].id);
    }
    return '${catalog.length}:${catalog.first.id}:${catalog.last.id}:$idsHash';
  }

  CartelaModel cartelaAt(int displayIndex) =>
      _catalog[_displayIndices[displayIndex]];

  void update({
    required List<CartelaModel> catalog,
    required String searchQuery,
    required List<String>? shuffledCartelaIds,
    bool serverSideSearch = false,
  }) {
    final catalogVersion = versionForCatalog(catalog);
    final nextShuffleHash = shuffledCartelaIds == null
        ? null
        : Object.hashAll(shuffledCartelaIds);
    final nextShuffleLength = shuffledCartelaIds?.length;
    final prevShuffleLength = _shuffledCartelaIds?.length;
    final needsRebuild =
        catalogVersion != _catalogVersion ||
        searchQuery != _searchQuery ||
        nextShuffleLength != prevShuffleLength ||
        nextShuffleHash != _shuffledOrderHash ||
        serverSideSearch != _serverSideSearch;

    _catalog = catalog;
    _searchQuery = searchQuery;
    _shuffledCartelaIds = shuffledCartelaIds;
    _shuffledOrderHash = nextShuffleHash;
    _serverSideSearch = serverSideSearch;
    _catalogVersion = catalogVersion;

    if (needsRebuild) {
      _displayIndices = _buildDisplayIndices();
    }
  }

  List<int> _buildDisplayIndices() {
    if (_catalog.isEmpty) {
      return const [];
    }

    final indices = <int>[];
    final query = _searchQuery;

    for (var index = 0; index < _catalog.length; index++) {
      final cartela = _catalog[index];
      if (query.isNotEmpty &&
          !_serverSideSearch &&
          !_matchesCartelaNumberQuery(cartela.number, query)) {
        continue;
      }
      indices.add(index);
    }

    if (_shuffledCartelaIds != null) {
      final shuffleIndex = _getOrBuildShuffleIndex();
      final fallbackIndex = shuffleIndex.length;

      indices.sort((left, right) {
        final leftShuffle =
            shuffleIndex[_catalog[left].id] ?? fallbackIndex;
        final rightShuffle =
            shuffleIndex[_catalog[right].id] ?? fallbackIndex;
        final byShuffle = leftShuffle.compareTo(rightShuffle);
        if (byShuffle != 0) {
          return byShuffle;
        }

        return _catalog[left].number.compareTo(_catalog[right].number);
      });
    }

    return indices;
  }

  Map<String, int> _getOrBuildShuffleIndex() {
    final list = _shuffledCartelaIds!;
    final hash = _shuffledOrderHash;
    if (_cachedShuffleIndex != null && _cachedShuffleOrderHash == hash) {
      return _cachedShuffleIndex!;
    }
    _cachedShuffleOrderHash = hash;
    return _cachedShuffleIndex = {
      for (var index = 0; index < list.length; index++)
        list[index]: index,
    };
  }
}

bool _matchesCartelaNumberQuery(int cartelaNumber, String query) {
  final numberText = cartelaNumber.toString();
  if (RegExp(r'^\d+$').hasMatch(query)) {
    return numberText.startsWith(query);
  }

  return numberText.contains(query);
}
