import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void debug(String scope, String message) {
    if (kDebugMode) {
      debugPrint('[$scope] $message');
    }
  }

  static String maskPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 6) {
      return '***';
    }

    return '${trimmed.substring(0, 3)}****${trimmed.substring(trimmed.length - 3)}';
  }

  static String maskIdentifier(String value, {int suffixLength = 4}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    if (trimmed.length <= suffixLength) {
      return '***';
    }

    return '***${trimmed.substring(trimmed.length - suffixLength)}';
  }

  static String shortIdentifier(String value, {int prefixLength = 8}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    if (trimmed.length <= prefixLength) {
      return trimmed;
    }

    return trimmed.substring(0, prefixLength);
  }
}
