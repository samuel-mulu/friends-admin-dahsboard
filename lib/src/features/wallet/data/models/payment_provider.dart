enum PaymentProvider {
  cbe,
  telebirr;

  factory PaymentProvider.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'CBE':
        return PaymentProvider.cbe;
      case 'TELEBIRR':
        return PaymentProvider.telebirr;
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
    }
  }

  String get label {
    switch (this) {
      case PaymentProvider.cbe:
        return 'CBE';
      case PaymentProvider.telebirr:
        return 'Telebirr';
    }
  }

  String get depositInstruction {
    switch (this) {
      case PaymentProvider.cbe:
        return 'Send money with CBE, then enter the FT transaction number here.';
      case PaymentProvider.telebirr:
        return 'Send money with Telebirr, then enter the receipt ID here.';
    }
  }

  String get receiverFieldLabel {
    switch (this) {
      case PaymentProvider.cbe:
        return 'Receiver account';
      case PaymentProvider.telebirr:
        return 'Receiver phone';
    }
  }

  String get receiverFieldHint {
    switch (this) {
      case PaymentProvider.cbe:
        return '1002003004005006';
      case PaymentProvider.telebirr:
        return '0912345678';
    }
  }
}
