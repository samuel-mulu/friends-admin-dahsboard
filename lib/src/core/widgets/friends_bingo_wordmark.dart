import 'package:flutter/material.dart';

import '../theme/app_branding.dart';

class FriendsBingoWordmark extends StatelessWidget {
  const FriendsBingoWordmark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppBranding.brandName,
      style: AppBranding.wordmark(context, compact: compact),
    );
  }
}
