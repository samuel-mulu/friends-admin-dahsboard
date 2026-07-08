import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'server_clock_service.dart';

final serverClockProvider = Provider<ServerClockService>((ref) {
  return ServerClockService();
});
