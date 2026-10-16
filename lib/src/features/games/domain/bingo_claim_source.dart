/// Matches Nest `BingoClaimSource`. Missing/omitted defaults to MANUAL server-side.
enum BingoClaimSource {
  manual('MANUAL'),
  auto('AUTO');

  const BingoClaimSource(this.apiValue);
  final String apiValue;

  static BingoClaimSource fromIdentity(Object? raw) {
    if (raw == 'AUTO' || raw == BingoClaimSource.auto.apiValue) {
      return BingoClaimSource.auto;
    }
    return BingoClaimSource.manual;
  }
}
