import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_notification_category.dart';

@immutable
class AppPushMessage {
  const AppPushMessage({
    required this.category,
    required this.title,
    required this.body,
    this.route,
    this.entityId,
    this.data = const <String, String>{},
  });

  final String category;
  final String title;
  final String body;
  final String? route;
  final String? entityId;
  final Map<String, String> data;

  factory AppPushMessage.fromRemoteMessage(RemoteMessage message) {
    final data = Map<String, String>.from(message.data);
    final category = data['category'] ?? notificationCategorySystem;
    final title = data['title'] ?? message.notification?.title ?? 'Friends Bingo';
    final body = data['body'] ?? message.notification?.body ?? '';

    return AppPushMessage(
      category: category,
      title: title,
      body: body,
      route: data['route'],
      entityId: data['entityId'],
      data: data,
    );
  }

  factory AppPushMessage.fromPayload(String payload) {
    final decoded = jsonDecode(payload);
    final map = decoded is Map<String, dynamic>
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};

    return AppPushMessage(
      category: map['category']?.toString() ?? notificationCategorySystem,
      title: map['title']?.toString() ?? 'Friends Bingo',
      body: map['body']?.toString() ?? '',
      route: map['route']?.toString(),
      entityId: map['entityId']?.toString(),
      data: map.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  String toPayload() {
    final payload = <String, String>{
      'category': category,
      'title': title,
      'body': body,
      ...data,
    };

    if (route case final routeValue?) {
      payload['route'] = routeValue;
    }

    if (entityId case final entityIdValue?) {
      payload['entityId'] = entityIdValue;
    }

    return jsonEncode(payload);
  }
}
