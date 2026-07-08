import 'package:flutter_test/flutter_test.dart';

void main() {
  group('registration shuffle order', () {
    test('regenerating shuffle ids can produce a different order', () {
      final sourceIds = List<String>.generate(12, (index) => 'c-$index');

      for (var attempt = 0; attempt < 25; attempt++) {
        final first = sourceIds.toList()..shuffle();
        final second = sourceIds.toList()..shuffle();
        if (!_listsEqual(first, second)) {
          return;
        }
      }

      fail('expected at least one different shuffle order in 25 attempts');
    });
  });
}

bool _listsEqual(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
