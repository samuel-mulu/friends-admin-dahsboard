import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import '../presentation/debug/telebirr_deposit_debug.dart';
import 'models/deposit_config_model.dart';
import 'models/telebirr_receipt_preview.dart';

class TelebirrReceiptPreviewService {
  TelebirrReceiptPreviewService(this._dio);

  final Dio _dio;

  Future<TelebirrReceiptPreview> preview({
    required String transactionRef,
    required String submittedAmount,
    required TelebirrDepositConfig config,
  }) async {
    final receiptUrl = _buildReceiptUrl(config.receiptBaseUrl, transactionRef);

    TelebirrDepositDebug.log(
      'fetch receipt ref=${TelebirrDepositDebug.maskRef(transactionRef)} amountSet=${submittedAmount.isNotEmpty}',
    );

    try {
      final response = await _dio.get<String>(
        receiptUrl,
        options: Options(responseType: ResponseType.plain),
      );

      final html = response.data;
      if (html == null || html.trim().isEmpty) {
        TelebirrDepositDebug.preview(
          transactionRef: transactionRef,
          status: TelebirrReceiptPreviewStatus.previewUnavailable.name,
          message: 'empty html',
        );
        return TelebirrReceiptPreview(
          status: TelebirrReceiptPreviewStatus.previewUnavailable,
          transactionRef: transactionRef,
          message:
              'We could not preview the receipt. Server verification will continue.',
        );
      }

      final preview = _parsePreview(
        html: html,
        transactionRef: transactionRef,
        submittedAmount: submittedAmount,
        config: config,
      );
      TelebirrDepositDebug.preview(
        transactionRef: transactionRef,
        status: preview.status.name,
        settledAmount: preview.settledAmount,
        totalPaidAmount: preview.totalPaidAmount,
        creditedPartyName: preview.creditedPartyName,
        creditedPartyAccountNo: preview.creditedPartyAccountNo,
        transactionStatus: preview.transactionStatus,
        message: preview.message,
      );
      return preview;
    } catch (error) {
      final message = error is DioException
          ? (error.message ?? error.type.name)
          : error.toString();
      TelebirrDepositDebug.preview(
        transactionRef: transactionRef,
        status: TelebirrReceiptPreviewStatus.previewUnavailable.name,
        message: message,
      );
      return TelebirrReceiptPreview(
        status: TelebirrReceiptPreviewStatus.previewUnavailable,
        transactionRef: transactionRef,
        message:
            'We could not preview the receipt. Server verification will continue.',
      );
    }
  }

  TelebirrReceiptPreview parsePreviewHtml({
    required String html,
    required String transactionRef,
    required String submittedAmount,
    required TelebirrDepositConfig config,
  }) {
    return _parsePreview(
      html: html,
      transactionRef: transactionRef,
      submittedAmount: submittedAmount,
      config: config,
    );
  }

  TelebirrReceiptPreview _parsePreview({
    required String html,
    required String transactionRef,
    required String submittedAmount,
    required TelebirrDepositConfig config,
  }) {
    final document = html_parser.parse(html);
    final receiptText =
        document.body?.text ?? document.documentElement?.text ?? '';
    final normalizedText = _normalizeText(receiptText);

    final invoiceDetails = _findInvoiceAndSettledAmount(
      document: document,
      transactionRef: transactionRef,
    );
    final invoiceNumber =
        invoiceDetails?.invoice ??
        _findInvoiceNumber(
          document: document,
          normalizedText: normalizedText,
          transactionRef: transactionRef,
        );
    final transactionStatus = _findValue(
      document,
      normalizedText,
      labels: const ['Transaction Status', 'transaction status'],
    );
    final settledAmount = _cleanMoney(
      invoiceDetails?.settled ??
          _findValue(
            document,
            normalizedText,
            labels: const ['Settled Amount'],
          ),
    );
    final totalPaidAmount = _cleanMoney(
      _findValue(
        document,
        normalizedText,
        labels: const ['Total Paid Amount', 'Total Paid'],
      ),
    );
    final creditedPartyName = _findValue(
      document,
      normalizedText,
      labels: const [
        'Credited party name',
        'Credited Party name',
        'Credited Party Name',
      ],
    );
    final creditedPartyAccountNo = _findValue(
      document,
      normalizedText,
      labels: const [
        'Credited party account no',
        'Credited party account no.',
        'Credited Party Account No',
      ],
    );

    if (invoiceNumber == null) {
      TelebirrDepositDebug.log(
        'parse incomplete invoiceNumberMissing=true '
        'hasTransactionStatus=${transactionStatus != null} '
        'hasSettledAmount=${settledAmount != null} '
        'hasReceiverName=${creditedPartyName?.isNotEmpty == true}',
      );
      return TelebirrReceiptPreview(
        status: TelebirrReceiptPreviewStatus.previewUnavailable,
        transactionRef: transactionRef,
        message:
            'We could not preview the receipt. Server verification will continue.',
      );
    }

    if (!_normalizeCode(
      invoiceNumber,
    ).contains(_normalizeCode(transactionRef))) {
      TelebirrDepositDebug.log('parse invoice mismatch');
      return TelebirrReceiptPreview(
        status: TelebirrReceiptPreviewStatus.invalidReceipt,
        transactionRef: transactionRef,
        transactionStatus: transactionStatus,
      );
    }

    if (transactionStatus == null ||
        _normalizeText(transactionStatus) != 'completed') {
      return TelebirrReceiptPreview(
        status: TelebirrReceiptPreviewStatus.invalidReceipt,
        transactionRef: transactionRef,
        transactionStatus: transactionStatus,
      );
    }

    if (settledAmount == null ||
        !_amountMatches(settledAmount, submittedAmount)) {
      TelebirrDepositDebug.log(
        'parse amount mismatch hasSettledAmount=${settledAmount != null}',
      );
      return TelebirrReceiptPreview(
        status: TelebirrReceiptPreviewStatus.amountMismatch,
        transactionRef: transactionRef,
        settledAmount: settledAmount,
        totalPaidAmount: totalPaidAmount,
        transactionStatus: transactionStatus,
      );
    }

    if (!_receiverMatches(config, creditedPartyName, creditedPartyAccountNo)) {
      return TelebirrReceiptPreview(
        status: TelebirrReceiptPreviewStatus.receiverMismatch,
        transactionRef: transactionRef,
        creditedPartyName: creditedPartyName,
        creditedPartyAccountNo: creditedPartyAccountNo,
      );
    }

    return TelebirrReceiptPreview(
      status: TelebirrReceiptPreviewStatus.valid,
      transactionRef: transactionRef,
      settledAmount: settledAmount,
      totalPaidAmount: totalPaidAmount,
      creditedPartyName: creditedPartyName,
      creditedPartyAccountNo: creditedPartyAccountNo,
      transactionStatus: transactionStatus,
    );
  }

  String _buildReceiptUrl(String baseUrl, String transactionRef) {
    return '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/$transactionRef';
  }

  String? _findInvoiceNumber({
    required Document document,
    required String normalizedText,
    required String transactionRef,
  }) {
    const labels = [
      'Invoice No',
      'Invoice No.',
      'Invoice Number',
      'Receipt Code',
    ];
    for (final label in labels) {
      final columnValue = _findColumnTableValue(
        document,
        label,
        validate: (value) => _isPlausibleInvoiceNumber(value, transactionRef),
      );
      if (columnValue != null && columnValue.isNotEmpty) {
        return columnValue;
      }
    }

    for (final label in labels) {
      final rowValue = _findRowValue(
        document,
        label,
        validate: (value) => _isPlausibleInvoiceNumber(value, transactionRef),
      );
      if (rowValue != null && rowValue.isNotEmpty) {
        return rowValue;
      }
    }

    final normalizedRef = _normalizeCode(transactionRef);
    if (normalizedText.contains(normalizedRef.toLowerCase())) {
      final refPattern = RegExp(
        '\\b${RegExp.escape(normalizedRef)}\\b',
        caseSensitive: false,
      );
      if (refPattern.hasMatch(normalizedText)) {
        return transactionRef;
      }
    }

    for (final label in labels) {
      final textValue = _findTextValue(normalizedText, label);
      if (textValue != null &&
          textValue.isNotEmpty &&
          _isPlausibleInvoiceNumber(textValue, transactionRef)) {
        return textValue;
      }
    }

    return null;
  }

  ({String invoice, String settled})? _findInvoiceAndSettledAmount({
    required Document document,
    required String transactionRef,
  }) {
    for (final table in document.querySelectorAll('table')) {
      final rows = _tableRows(table);
      for (var rowIndex = 0; rowIndex < rows.length - 1; rowIndex++) {
        final headerCells = rows[rowIndex].querySelectorAll('td, th');
        if (!_rowLooksLikeColumnHeaderRow(headerCells)) {
          continue;
        }

        var invoiceColumn = -1;
        var settledColumn = -1;
        for (var cellIndex = 0; cellIndex < headerCells.length; cellIndex++) {
          final text = headerCells[cellIndex].text;
          if (_labelMatches(text, 'Invoice No') ||
              _labelMatches(text, 'Invoice No.')) {
            invoiceColumn = cellIndex;
          }
          if (_labelMatches(text, 'Settled Amount')) {
            settledColumn = cellIndex;
          }
        }

        if (invoiceColumn < 0 || settledColumn < 0) {
          continue;
        }

        for (
          var dataRowIndex = rowIndex + 1;
          dataRowIndex < rows.length && dataRowIndex <= rowIndex + 6;
          dataRowIndex++
        ) {
          final dataCells = rows[dataRowIndex].querySelectorAll('td, th');
          if (invoiceColumn >= dataCells.length ||
              settledColumn >= dataCells.length) {
            continue;
          }

          final invoiceValue = dataCells[invoiceColumn].text.trim();
          final settledValue = dataCells[settledColumn].text.trim();
          if (!_isPlausibleInvoiceNumber(invoiceValue, transactionRef)) {
            continue;
          }
          if (settledValue.isEmpty ||
              _looksLikeColumnHeader(settledValue) ||
              _cleanMoney(settledValue) == null) {
            continue;
          }

          return (invoice: invoiceValue, settled: settledValue);
        }
      }
    }

    return null;
  }

  bool _isPlausibleInvoiceNumber(String value, String transactionRef) {
    final normalizedValue = _normalizeCode(value);
    if (normalizedValue.isEmpty || _looksLikeColumnHeader(value)) {
      return false;
    }

    if (normalizedValue.contains('INVOICE') ||
        normalizedValue.contains('DETAILS') ||
        normalizedValue.contains('PAYMENT')) {
      return false;
    }

    final normalizedRef = _normalizeCode(transactionRef);
    if (normalizedValue.contains(normalizedRef)) {
      return true;
    }

    return RegExp(r'^[A-Z0-9]{8,15}$').hasMatch(normalizedValue);
  }

  String? _findValue(
    Document document,
    String normalizedText, {
    required List<String> labels,
  }) {
    for (final label in labels) {
      final columnValue = _findColumnTableValue(document, label);
      if (columnValue != null && columnValue.isNotEmpty) {
        return columnValue;
      }

      final rowValue = _findRowValue(document, label);
      if (rowValue != null && rowValue.isNotEmpty) {
        return rowValue;
      }

      final textValue = _findTextValue(normalizedText, label);
      if (textValue != null && textValue.isNotEmpty) {
        return textValue;
      }
    }

    return null;
  }

  String? _findRowValue(
    Document document,
    String label, {
    bool Function(String value)? validate,
  }) {
    for (final row in document.querySelectorAll('tr')) {
      final cells = row.children
          .where(
            (element) => element.localName == 'td' || element.localName == 'th',
          )
          .toList();
      for (var index = 0; index < cells.length; index++) {
        if (!_labelMatches(cells[index].text, label)) {
          continue;
        }

        for (
          var valueIndex = index + 1;
          valueIndex < cells.length;
          valueIndex++
        ) {
          final value = cells[valueIndex].text.trim();
          if (value.isEmpty || _labelMatches(value, label)) {
            continue;
          }
          if (validate != null && !validate(value)) {
            continue;
          }
          return value;
        }
      }
    }

    return null;
  }

  String? _findColumnTableValue(
    Document document,
    String label, {
    bool Function(String value)? validate,
  }) {
    for (final table in document.querySelectorAll('table')) {
      final rows = _tableRows(table);
      for (var rowIndex = 0; rowIndex < rows.length - 1; rowIndex++) {
        final headerCells = rows[rowIndex].querySelectorAll('td, th');
        if (!_rowLooksLikeColumnHeaderRow(headerCells)) {
          continue;
        }

        var columnIndex = -1;
        for (var cellIndex = 0; cellIndex < headerCells.length; cellIndex++) {
          if (_labelMatches(headerCells[cellIndex].text, label)) {
            columnIndex = cellIndex;
            break;
          }
        }

        if (columnIndex < 0) {
          continue;
        }

        for (
          var dataRowIndex = rowIndex + 1;
          dataRowIndex < rows.length && dataRowIndex <= rowIndex + 4;
          dataRowIndex++
        ) {
          final dataCells = rows[dataRowIndex].querySelectorAll('td, th');
          if (columnIndex >= dataCells.length) {
            continue;
          }

          final value = dataCells[columnIndex].text.trim();
          if (value.isEmpty || _looksLikeColumnHeader(value)) {
            continue;
          }
          if (validate != null && !validate(value)) {
            continue;
          }
          return value;
        }
      }
    }

    return null;
  }

  List<Element> _tableRows(Element table) {
    final directRows = _directTableRows(table);
    if (directRows.isNotEmpty) {
      return directRows;
    }

    final rows = <Element>[];
    for (final row in table.querySelectorAll('tr')) {
      final parent = row.parent;
      if (parent == table ||
          (parent?.localName == 'tbody' && parent?.parent == table)) {
        rows.add(row);
      }
    }

    return rows;
  }

  List<Element> _directTableRows(Element table) {
    final rows = <Element>[];
    for (final child in table.nodes) {
      if (child is! Element) {
        continue;
      }

      if (child.localName == 'tr') {
        rows.add(child);
        continue;
      }

      if (child.localName == 'tbody' || child.localName == 'thead') {
        rows.addAll(
          child.children.whereType<Element>().where(
            (element) => element.localName == 'tr',
          ),
        );
      }
    }

    return rows;
  }

  bool _rowLooksLikeColumnHeaderRow(List<Element> cells) {
    if (cells.length < 2) {
      return false;
    }

    var headerLikeCount = 0;
    for (final cell in cells) {
      final text = _normalizeLabelText(cell.text);
      if (text.contains('invoice no') ||
          text.contains('payment date') ||
          text.contains('settled amount')) {
        headerLikeCount++;
      }
    }

    return headerLikeCount >= 2;
  }

  bool _labelMatches(String cellText, String label) {
    final cell = _normalizeLabelText(cellText);
    final target = _normalizeLabelText(label);
    if (cell == target) {
      return true;
    }

    if (cell.endsWith('/$target')) {
      return true;
    }

    final cellWithoutPeriod = cell.replaceAll('.', '');
    final targetWithoutPeriod = target.replaceAll('.', '');
    if (cellWithoutPeriod == targetWithoutPeriod) {
      return true;
    }
    if (cellWithoutPeriod.endsWith('/$targetWithoutPeriod')) {
      return true;
    }

    if (targetWithoutPeriod == 'invoice no') {
      return cellWithoutPeriod.contains('/$targetWithoutPeriod') ||
          cellWithoutPeriod.endsWith(targetWithoutPeriod);
    }

    if (targetWithoutPeriod.length <= 6) {
      return cellWithoutPeriod == targetWithoutPeriod ||
          cellWithoutPeriod.endsWith('/$targetWithoutPeriod');
    }

    return cellWithoutPeriod.contains(targetWithoutPeriod);
  }

  bool _looksLikeColumnHeader(String value) {
    final normalized = _normalizeLabelText(value);
    return normalized.contains('invoice details') ||
        normalized.contains('payment date') ||
        normalized.contains('settled amount') ||
        normalized.contains('invoice no');
  }

  String _normalizeLabelText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String? _findTextValue(String normalizedText, String label) {
    final pattern = RegExp(
      '${RegExp.escape(_normalizeText(label))}\\s*[:：]?\\s*([a-z0-9*\\-./ ]{1,80})',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(normalizedText);
    return match?.group(1)?.trim();
  }

  bool _receiverMatches(
    TelebirrDepositConfig config,
    String? receiverName,
    String? receiverAccount,
  ) {
    final accounts = config.accounts.isNotEmpty
        ? config.accounts
        : [
            TelebirrAccountConfig(
              settlementAccount: '',
              receiverName: config.receiverName,
              receiverPhoneLast4: config.receiverPhoneLast4,
            ),
          ];

    for (final account in accounts) {
      if (_accountReceiverMatches(
        account,
        receiverName,
        receiverAccount,
      )) {
        return true;
      }
    }

    return false;
  }

  /// The masked account number is the only stable identifier on a Telebirr
  /// receipt. Receiver names are free text and vary in spelling, so they are
  /// only compared when no last4 is configured for the account.
  bool _accountReceiverMatches(
    TelebirrAccountConfig account,
    String? receiverName,
    String? receiverAccount,
  ) {
    final configuredLast4 = _resolveConfiguredLast4(account);
    if (configuredLast4 != null) {
      final receiverLast4 = _digitsOnly(receiverAccount ?? '');
      return receiverLast4.length >= 4 &&
          receiverLast4.endsWith(configuredLast4);
    }

    final configuredName = _normalizeText(account.receiverName);
    if (configuredName.isEmpty) {
      return false;
    }

    return _normalizeText(receiverName ?? '') == configuredName;
  }

  String? _resolveConfiguredLast4(TelebirrAccountConfig account) {
    for (final candidate in [
      account.receiverPhoneLast4,
      account.settlementAccount,
    ]) {
      final digits = _digitsOnly(candidate);
      if (digits.length >= 4) {
        return digits.substring(digits.length - 4);
      }
    }

    return null;
  }

  bool _amountMatches(String settledAmount, String submittedAmount) {
    final normalizedSettled = double.tryParse(settledAmount);
    final normalizedSubmitted = double.tryParse(submittedAmount);
    if (normalizedSettled == null || normalizedSubmitted == null) {
      return false;
    }

    return normalizedSettled.toStringAsFixed(2) ==
        normalizedSubmitted.toStringAsFixed(2);
  }

  String? _cleanMoney(String? raw) {
    if (raw == null) {
      return null;
    }

    final match = RegExp(
      r'\d+(?:\.\d{1,2})?',
    ).firstMatch(raw.replaceAll(',', ''));
    return match?.group(0);
  }

  String _normalizeCode(String value) {
    return value.trim().toUpperCase();
  }

  String _normalizeText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}

final telebirrReceiptPreviewServiceProvider =
    Provider<TelebirrReceiptPreviewService>((ref) {
      return TelebirrReceiptPreviewService(
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
          ),
        ),
      );
    });
