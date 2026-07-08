import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/notifications/firebase_notification_service.dart';
import 'src/app.dart';
import 'src/features/wallet/data/receipt_ocr/receipt_ocr_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(
    ProviderScope(
      overrides: [
        receiptOcrServiceProvider.overrideWithValue(
          createDefaultReceiptOcrService(),
        ),
      ],
      child: const FriendsBingoApp(),
    ),
  );
}
