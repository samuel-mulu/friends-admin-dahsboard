enum PaymentProvider {
  cbe,
  telebirr,
  awash,
  boa;

  factory PaymentProvider.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'CBE':
        return PaymentProvider.cbe;
      case 'TELEBIRR':
        return PaymentProvider.telebirr;
      case 'AWASH':
        return PaymentProvider.awash;
      case 'BOA':
        return PaymentProvider.boa;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported provider');
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentProvider.cbe:
        return 'CBE';
      case PaymentProvider.telebirr:
        return 'TELEBIRR';
      case PaymentProvider.awash:
        return 'AWASH';
      case PaymentProvider.boa:
        return 'BOA';
    }
  }

  String get label {
    switch (this) {
      case PaymentProvider.cbe:
        return 'CBE';
      case PaymentProvider.telebirr:
        return 'Telebirr';
      case PaymentProvider.awash:
        return 'Awash Bank';
      case PaymentProvider.boa:
        return 'Bank of Abyssinia';
    }
  }

  String get depositInstruction {
    switch (this) {
      case PaymentProvider.cbe:
        return 'Send money with CBE Bank, then paste the receipt link or enter the FT receipt number here.';
      case PaymentProvider.telebirr:
        return 'Send money with Telebirr, then enter the receipt ID here.';
      case PaymentProvider.awash:
        return 'Send money with Awash Bank, then enter the payment reference here.';
      case PaymentProvider.boa:
        return 'Send money with Bank of Abyssinia, then enter the payment reference here.';
    }
  }

  String get transactionRefLabel {
    switch (this) {
      case PaymentProvider.cbe:
        return 'Reference number';
      case PaymentProvider.telebirr:
        return 'Receipt code';
      case PaymentProvider.awash:
        return 'Reference number';
      case PaymentProvider.boa:
        return 'Reference number';
    }
  }

  String get transactionRefHint {
    switch (this) {
      case PaymentProvider.cbe:
        return 'FT26152ZN0XY';
      case PaymentProvider.telebirr:
        return 'DFE8V9NO7E';
      case PaymentProvider.awash:
        return 'AW12345678';
      case PaymentProvider.boa:
        return 'BOA123456';
    }
  }

  String get receiverFieldLabel {
    switch (this) {
      case PaymentProvider.cbe:
      case PaymentProvider.boa:
      case PaymentProvider.awash:
        return 'Receiver account';
      case PaymentProvider.telebirr:
        return 'Receiver phone';
    }
  }

  String get receiverFieldHint {
    switch (this) {
      case PaymentProvider.cbe:
        return '1000…';
      case PaymentProvider.boa:
      case PaymentProvider.awash:
        return '1002003004005006';
      case PaymentProvider.telebirr:
        return '0912345678';
    }
  }
}
