import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AccountBanState {
  const AccountBanState({this.reason});

  final String? reason;

  bool get isBanned => true;
}

class AccountBanNotifier extends Notifier<AccountBanState?> {
  @override
  AccountBanState? build() => null;

  void show({String? reason}) {
    final trimmed = reason?.trim();
    state = AccountBanState(
      reason: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }

  void clear() {
    state = null;
  }
}

final accountBanProvider =
    NotifierProvider<AccountBanNotifier, AccountBanState?>(
  AccountBanNotifier.new,
);
