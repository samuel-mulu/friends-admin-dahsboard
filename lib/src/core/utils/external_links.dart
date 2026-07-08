import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUri(
  BuildContext context,
  Uri uri, {
  String? copiedMessage,
}) async {
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copiedMessage ?? 'Could not open link')),
      );
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copiedMessage ?? 'Could not open link')),
      );
    }
    return false;
  }
}
