import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import 'auth_brand_header.dart';

class AuthScreenScaffold extends StatelessWidget {
  const AuthScreenScaffold({
    required this.child,
    this.title,
    this.subtitle,
    this.footer,
    this.leading,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeading =
        (title != null && title!.isNotEmpty) ||
        (subtitle != null && subtitle!.isNotEmpty);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leading != null) ...[
                    Align(alignment: Alignment.centerLeft, child: leading),
                    const SizedBox(height: 8),
                  ],
                  const AuthBrandHeader(),
                  if (hasHeading) ...[
                    const SizedBox(height: 20),
                    if (title != null && title!.isNotEmpty)
                      Text(
                        title!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppBranding.casinoPurple.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.12
                                : 0.06,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 20),
                    Center(child: footer),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
