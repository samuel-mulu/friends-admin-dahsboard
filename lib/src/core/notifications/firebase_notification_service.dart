import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'app_push_message.dart';
import 'notification_display_policy.dart';

const _androidNotificationChannelId = 'friends_bingo_updates';
const _androidNotificationChannelName = 'Friends Bingo Updates';
const _androidNotificationChannelDescription =
    'Game, winner, deposit, withdrawal, and system updates from Friends Bingo.';

final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
final _notificationTapController =
    StreamController<AppPushMessage>.broadcast();
bool _localNotificationsInitialized = false;
bool _localNotificationsAvailable = true;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!_isAndroidNotificationPlatform) {
    return;
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  final pushMessage = AppPushMessage.fromRemoteMessage(message);
  final shouldDisplay = await shouldDisplayPushNotification(pushMessage);

  if (kDebugMode) {
    debugPrint(
      '[Notifications/FCM] background message category=${pushMessage.category} shouldDisplay=$shouldDisplay',
    );
  }

  if (!shouldDisplay) {
    return;
  }

  await _ensureLocalNotificationsInitialized();
  if (!_localNotificationsAvailable) {
    return;
  }
  await _showLocalNotification(pushMessage);
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    return;
  }

  if (kDebugMode) {
    debugPrint('[Notifications/Local] background tap payload received');
  }
}

bool get _isAndroidNotificationPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<void> _ensureLocalNotificationsInitialized() async {
  if (_localNotificationsInitialized || !_localNotificationsAvailable) {
    return;
  }

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);

  try {
    await _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidNotificationChannelId,
        _androidNotificationChannelName,
        description: _androidNotificationChannelDescription,
        importance: Importance.high,
      ),
    );

    _localNotificationsInitialized = true;
  } on MissingPluginException {
    _localNotificationsAvailable = false;
    if (kDebugMode) {
      debugPrint(
        '[Notifications/Local] plugin unavailable. Stop the app and run it again with a full restart after adding native notification plugins.',
      );
    }
  }
}

Future<void> _showLocalNotification(AppPushMessage message) async {
  await _localNotificationsPlugin.show(
    _buildNotificationId(message),
    message.title,
    message.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidNotificationChannelId,
        _androidNotificationChannelName,
        channelDescription: _androidNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        groupKey: androidNotificationGroupKey,
      ),
    ),
    payload: message.toPayload(),
  );
}

int _buildNotificationId(AppPushMessage message) {
  final seed = '${message.category}:${message.entityId ?? message.title}';
  return seed.hashCode & 0x7fffffff;
}

void _handleLocalNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    return;
  }

  final message = AppPushMessage.fromPayload(payload);
  if (!_notificationTapController.isClosed) {
    _notificationTapController.add(message);
  }

  if (kDebugMode) {
    debugPrint(
      '[Notifications/Local] tapped category=${message.category} route=${message.route ?? 'none'}',
    );
  }
}

class FirebaseNotificationService {
  bool _initialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;

  bool get isSupportedPlatform => _isAndroidNotificationPlatform;

  String? get currentToken => _currentToken;

  String get platform => 'android';

  Stream<AppPushMessage> get notificationTapStream =>
      _notificationTapController.stream;

  Future<void> initialize() async {
    if (!isSupportedPlatform || _initialized) {
      if (!isSupportedPlatform) {
        _log('initialize skipped: unsupported platform');
      }
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    await _ensureLocalNotificationsInitialized();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _notificationTapSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _initialized = true;
    _log('initialized');
  }

  Future<bool> requestPermission() async {
    if (!isSupportedPlatform) {
      return false;
    }

    await initialize();
    final settings = await FirebaseMessaging.instance.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    _log(
      'permission status=${settings.authorizationStatus.name} granted=$granted',
    );
    return granted;
  }

  Future<String?> getToken() async {
    if (!isSupportedPlatform) {
      return null;
    }

    await initialize();
    _currentToken = await FirebaseMessaging.instance.getToken();
    _log(
      _currentToken == null || _currentToken!.isEmpty
          ? 'token unavailable'
          : 'token fetched suffix=${_suffix(_currentToken!)}',
    );
    return _currentToken;
  }

  Future<void> listenForTokenRefresh(
    Future<void> Function(String token) onTokenRefresh,
  ) async {
    if (!isSupportedPlatform) {
      return;
    }

    await initialize();
    await _tokenRefreshSubscription?.cancel();
    _log('listen for token refresh');
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) {
        _currentToken = token;
        _log('token refresh event suffix=${_suffix(token)}');
        unawaited(onTokenRefresh(token));
      },
    );
  }

  Future<void> stopTokenRefreshListener() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _log('token refresh listener stopped');
  }

  Future<void> dispose() async {
    await stopTokenRefreshListener();
    await _foregroundMessageSubscription?.cancel();
    await _notificationTapSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _notificationTapSubscription = null;
    _initialized = false;
    _log('disposed');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final pushMessage = AppPushMessage.fromRemoteMessage(message);
    final shouldDisplay = await shouldDisplayPushNotification(pushMessage);

    _log(
      'foreground message category=${pushMessage.category} shouldDisplay=$shouldDisplay',
    );

    if (!shouldDisplay) {
      return;
    }

    if (!_localNotificationsAvailable) {
      _log(
        'foreground notification skipped because local notification plugin is unavailable',
      );
      return;
    }

    await _showLocalNotification(pushMessage);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final pushMessage = AppPushMessage.fromRemoteMessage(message);
    if (!_notificationTapController.isClosed) {
      _notificationTapController.add(pushMessage);
    }

    _log(
      'tapped message category=${pushMessage.category} route=${pushMessage.route ?? 'none'}',
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Notifications/FCM] $message');
    }
  }

  String _suffix(String token) {
    if (token.length <= 8) {
      return token;
    }

    return token.substring(token.length - 8);
  }
}

final firebaseNotificationServiceProvider =
    Provider<FirebaseNotificationService>((ref) {
      final service = FirebaseNotificationService();
      ref.onDispose(() {
        unawaited(service.dispose());
      });
      return service;
    });
