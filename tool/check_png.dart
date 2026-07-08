import 'dart:io';
import 'dart:ui' as ui;

Future<void> check(String path) async {
  final bytes = await File(path).readAsBytes();
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    stdout.writeln('$path: ${frame.image.width}x${frame.image.height} ok');
    frame.image.dispose();
  } catch (e) {
    stdout.writeln('$path: DECODE ERROR $e');
  }
}

Future<void> main() async {
  for (final s in ['step_1', 'step_2', 'step_3']) {
    await check('assets/deposit_guides/telebirr/$s.png');
  }
}
