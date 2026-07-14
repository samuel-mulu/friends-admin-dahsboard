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

class TelebirrAccountConfig {
  const TelebirrAccountConfig({
    required this.settlementAccount,
    required this.receiverName,
    required this.receiverPhoneLast4,
  });

  final String settlementAccount;
  final String receiverName;
  final String receiverPhoneLast4;

  factory TelebirrAccountConfig.fromJson(Map<String, dynamic> json) {
    return TelebirrAccountConfig(
      settlementAccount: json['settlementAccount'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? '',
      receiverPhoneLast4: json['receiverPhoneLast4'] as String? ?? '',
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
    required this.accounts,
  });

  final String providerName;
  final String receiptHelpText;
  final String receiptBaseUrl;
  final String receiverPhoneLast4;
  final String receiverName;
  final List<TelebirrAccountConfig> accounts;

  factory TelebirrDepositConfig.fromJson(Map<String, dynamic> json) {
    final receiptBaseUrl = (json['receiptBaseUrl'] as String? ?? '').trim();
    final receiverPhoneLast4 = json['receiverPhoneLast4'] as String? ?? '';
    final receiverName = json['receiverName'] as String? ?? '';
    final accountsJson = json['accounts'] as List<dynamic>? ?? const [];
    final parsedAccounts = accountsJson
        .whereType<Map<String, dynamic>>()
        .map(TelebirrAccountConfig.fromJson)
        .where((account) => account.settlementAccount.trim().isNotEmpty)
        .toList(growable: false);

    return TelebirrDepositConfig(
      providerName: json['providerName'] as String? ?? 'Telebirr',
      receiptHelpText: json['receiptHelpText'] as String? ?? '',
      receiptBaseUrl: receiptBaseUrl.isEmpty
          ? kDefaultTelebirrReceiptBaseUrl
          : receiptBaseUrl,
      receiverPhoneLast4: receiverPhoneLast4,
      receiverName: receiverName,
      accounts: parsedAccounts,
    );
  }

  List<TelebirrAccountConfig> resolvedAccounts({
    required String fallbackSettlementAccount,
  }) {
    if (accounts.isNotEmpty) {
      return accounts;
    }

    if (fallbackSettlementAccount.trim().isEmpty) {
      return const [];
    }

    return [
      TelebirrAccountConfig(
        settlementAccount: fallbackSettlementAccount,
        receiverName: receiverName,
        receiverPhoneLast4: receiverPhoneLast4,
      ),
    ];
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
