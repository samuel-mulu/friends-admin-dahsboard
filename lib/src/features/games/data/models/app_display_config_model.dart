class AppDisplayConfigModel {
  const AppDisplayConfigModel({
    required this.bigGamePromotionCardEnabled,
  });

  static const fallback = AppDisplayConfigModel(
    bigGamePromotionCardEnabled: true,
  );

  final bool bigGamePromotionCardEnabled;

  factory AppDisplayConfigModel.fromJson(Map<String, dynamic> json) {
    return AppDisplayConfigModel(
      bigGamePromotionCardEnabled:
          json['bigGamePromotionCardEnabled'] as bool? ?? true,
    );
  }
}
