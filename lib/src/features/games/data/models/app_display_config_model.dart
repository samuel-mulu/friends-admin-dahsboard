class AppDisplayConfigModel {
  const AppDisplayConfigModel({
    required this.bigGamePromotionCardEnabled,
    this.bingoClaimLastSecondLockEnabled = false,
  });

  static const fallback = AppDisplayConfigModel(
    bigGamePromotionCardEnabled: true,
  );

  final bool bigGamePromotionCardEnabled;

  /// Admin toggle for the last-second Bingo button lock. Off unless set.
  final bool bingoClaimLastSecondLockEnabled;

  factory AppDisplayConfigModel.fromJson(Map<String, dynamic> json) {
    return AppDisplayConfigModel(
      bigGamePromotionCardEnabled:
          json['bigGamePromotionCardEnabled'] as bool? ?? true,
      bingoClaimLastSecondLockEnabled:
          json['bingoClaimLastSecondLockEnabled'] == true,
    );
  }
}
