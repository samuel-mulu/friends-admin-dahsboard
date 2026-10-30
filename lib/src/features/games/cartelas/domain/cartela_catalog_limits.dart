/// Registration catalog sizing (aligned with FriendsBingo GET /cartelas limits).
abstract final class CartelaCatalogLimits {
  /// Rows requested from shuffle API (`limit` query param).
  static const fetchPoolSize = 500;

  /// Cartela numbers painted in the grid before scroll load-more.
  static const visibleBatchSize = 300;
}
