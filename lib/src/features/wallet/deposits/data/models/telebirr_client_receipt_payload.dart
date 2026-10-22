enum TelebirrReceiptParseStatus {
  parsed('parsed'),
  unavailable('unavailable');

  const TelebirrReceiptParseStatus(this.apiValue);

  final String apiValue;
}

class TelebirrClientReceiptPayload {
  const TelebirrClientReceiptPayload({
    required this.invoiceNumber,
    required this.transactionStatus,
    required this.settledAmount,
    required this.creditedPartyName,
    required this.creditedPartyAccountNo,
  });

  final String invoiceNumber;
  final String transactionStatus;
  final String settledAmount;
  final String creditedPartyName;
  final String creditedPartyAccountNo;

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'transactionStatus': transactionStatus,
      'settledAmount': settledAmount,
      'creditedPartyName': creditedPartyName,
      'creditedPartyAccountNo': creditedPartyAccountNo,
    };
  }
}
