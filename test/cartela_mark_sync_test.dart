import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_mark_helpers.dart';

void main() {
  group('cartela mark sync', () {
    test('FREE is always marked', () {
      expect(
        isManuallyMarkedCell(
          manualMarkedNumbers: const <String>{},
          header: 'N',
          value: 'FREE',
        ),
        isTrue,
      );
    });

    test('toggling I:22 marks column I cells with 22 on different layouts', () {
      final cartelaOne = [
        ['1', '2', '3', '4', '5'],
        ['16', '22', '18', '19', '20'],
        ['31', '32', 'FREE', '34', '35'],
        ['46', '47', '48', '49', '50'],
        ['61', '62', '63', '64', '65'],
      ];
      final cartelaTwo = [
        ['6', '7', '8', '9', '10'],
        ['17', '21', '22', '23', '24'],
        ['36', '37', 'FREE', '38', '39'],
        ['51', '52', '53', '54', '55'],
        ['66', '67', '68', '69', '70'],
      ];

      var marks = <String>{};
      marks = toggleManualMarkedNumber(
        manualMarkedNumbers: marks,
        header: 'I',
        value: '22',
      );

      expect(
        isManuallyMarkedCell(
          manualMarkedNumbers: marks,
          header: 'I',
          value: '22',
        ),
        isTrue,
      );

      expect(
        manuallyMarkedValuesForCartela(marks, cartelaOne),
        ['22'],
      );
      expect(
        manuallyMarkedValuesForCartela(marks, cartelaTwo),
        ['22'],
      );
    });

    test('multiple marks accumulate without replacing each other', () {
      var marks = toggleManualMarkedNumber(
        manualMarkedNumbers: const <String>{},
        header: 'I',
        value: '22',
      );
      marks = toggleManualMarkedNumber(
        manualMarkedNumbers: marks,
        header: 'B',
        value: '7',
      );
      marks = toggleManualMarkedNumber(
        manualMarkedNumbers: marks,
        header: 'G',
        value: '52',
      );

      expect(marks, {'I:22', 'B:7', 'G:52'});
    });

    test('toggle removes a shared mark', () {
      var marks = toggleManualMarkedNumber(
        manualMarkedNumbers: const <String>{},
        header: 'B',
        value: '7',
      );
      marks = toggleManualMarkedNumber(
        manualMarkedNumbers: marks,
        header: 'B',
        value: '7',
      );

      expect(marks, isEmpty);
    });
  });
}

List<String> manuallyMarkedValuesForCartela(
  Set<String> manualMarkedNumbers,
  List<List<String>> columns,
) {
  final marked = <String>[];
  for (var columnIndex = 0; columnIndex < bingoColumnHeaders.length; columnIndex++) {
    final header = bingoColumnHeaders[columnIndex];
    for (var rowIndex = 0; rowIndex < 5; rowIndex++) {
      final value = columns[columnIndex][rowIndex];
      if (value == 'FREE') {
        continue;
      }
      if (isManuallyMarkedCell(
        manualMarkedNumbers: manualMarkedNumbers,
        header: header,
        value: value,
      )) {
        marked.add(value);
      }
    }
  }
  return marked;
}
