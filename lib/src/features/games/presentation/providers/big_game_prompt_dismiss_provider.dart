import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hides [BigGameLivePromptBanner] until phase/round context changes.
final bigGamePromptDismissProvider =
    NotifierProvider<BigGamePromptDismissNotifier, String?>(
      BigGamePromptDismissNotifier.new,
    );

class BigGamePromptDismissNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void dismissForContext(String contextKey) {
    state = contextKey;
  }

  bool isHiddenFor(String contextKey) => state == contextKey;
}
