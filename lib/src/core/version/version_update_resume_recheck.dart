import 'package:flutter_riverpod/flutter_riverpod.dart';

class VersionUpdateResumeRecheckController extends Notifier<bool> {
  @override
  bool build() => false;

  void markForRecheck() => state = true;

  bool consumeRecheck() {
    final shouldRecheck = state;
    state = false;
    return shouldRecheck;
  }
}

final versionUpdateResumeRecheckControllerProvider =
    NotifierProvider<VersionUpdateResumeRecheckController, bool>(
      VersionUpdateResumeRecheckController.new,
    );
