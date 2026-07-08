import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leading != null) ...[
                    Align(alignment: Alignment.centerLeft, child: leading),
                    VGap.md,
                  ],
                  const AuthBrandHeader(),
                  if (hasHeading) ...[
                    VGap.xl,
                    if (title != null && title!.isNotEmpty)
                      Text(
                        title!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      VGap.md,
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
                  VGap.xl,
                  Container(
                    padding: AppSpacing.cardPaddingDense,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.55,
                              )
                            : AppBranding.lightOutline.withValues(alpha: 0.85),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppBranding.elevationShadow(context).withValues(
                            alpha: theme.brightness == Brightness.dark ? 0.12 : 0.08,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  if (footer != null) ...[
                    VGap.xl,
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
