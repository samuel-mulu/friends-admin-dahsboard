const kDefaultTelebirrReceiptBaseUrl =
    'https://transactioninfo.ethiotelecom.et/receipt';

class DepositProviderConfig {
  const DepositProviderConfig({
    required this.key,
    required this.name,
    required this.receiptCodeLabel,
    required this.helpText,
    required this.requiresAmount,
    required this.settlementAccount,
    required this.receiverName,
  });

  final String key;
  final String name;
  final String receiptCodeLabel;
  final String helpText;
  final bool requiresAmount;
  final String settlementAccount;
  final String receiverName;

  factory DepositProviderConfig.fromJson(Map<String, dynamic> json) {
    return DepositProviderConfig(
      key: json['key'] as String,
      name: json['name'] as String,
      receiptCodeLabel: json['receiptCodeLabel'] as String,
      helpText: json['helpText'] as String? ?? '',
      requiresAmount: json['requiresAmount'] as bool? ?? true,
      settlementAccount: json['settlementAccount'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? '',
    );
  }
}

class TelebirrDepositConfig {
  const TelebirrDepositConfig({
    required this.providerName,
    required this.receiptHelpText,
    required this.receiptBaseUrl,
    required this.receiverPhoneLast4,
    required this.receiverName,
  });

  final String providerName;
  final String receiptHelpText;
  final String receiptBaseUrl;
  final String receiverPhoneLast4;
  final String receiverName;

  factory TelebirrDepositConfig.fromJson(Map<String, dynamic> json) {
    final receiptBaseUrl = (json['receiptBaseUrl'] as String? ?? '').trim();
    return TelebirrDepositConfig(
      providerName: json['providerName'] as String? ?? 'Telebirr',
      receiptHelpText: json['receiptHelpText'] as String? ?? '',
      receiptBaseUrl: receiptBaseUrl.isEmpty
          ? kDefaultTelebirrReceiptBaseUrl
          : receiptBaseUrl,
      receiverPhoneLast4: json['receiverPhoneLast4'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? '',
    );
  }
}

class DepositConfigModel {
  const DepositConfigModel({
    required this.providers,
    required this.telebirr,
  });

  final List<DepositProviderConfig> providers;
  final TelebirrDepositConfig telebirr;

  factory DepositConfigModel.fromJson(Map<String, dynamic> json) {
    final providersJson = json['providers'] as List<dynamic>? ?? const [];
    final telebirrJson = json['telebirr'] as Map<String, dynamic>? ?? const {};

    return DepositConfigModel(
      providers: providersJson
          .whereType<Map<String, dynamic>>()
          .map(DepositProviderConfig.fromJson)
          .toList(growable: false),
      telebirr: TelebirrDepositConfig.fromJson(telebirrJson),
    );
  }

  DepositProviderConfig? providerForKey(String key) {
    for (final provider in providers) {
      if (provider.key == key) {
        return provider;
      }
    }
    return null;
  }
}
