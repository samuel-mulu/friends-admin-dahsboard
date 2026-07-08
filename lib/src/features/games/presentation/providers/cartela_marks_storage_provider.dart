import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/cartela_marks_storage.dart';

final cartelaMarksStorageProvider = FutureProvider<CartelaMarksStorage>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CartelaMarksStorage(prefs);
});
