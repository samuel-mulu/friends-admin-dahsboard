import 'package:flutter/material.dart';

/// App bar section for standard non-embedded live game presentation.
class LiveGameAppBarSection extends StatelessWidget
    implements PreferredSizeWidget {
  const LiveGameAppBarSection({
    this.title = 'Live game',
    this.onBack,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
