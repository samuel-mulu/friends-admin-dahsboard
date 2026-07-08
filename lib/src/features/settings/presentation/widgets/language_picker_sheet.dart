import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../providers/locale_provider.dart';

Future<void> showLanguagePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _LanguagePickerSheet(parentContext: context),
  );
}

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet({required this.parentContext});

  final BuildContext parentContext;

  static const _languages = [
    (code: 'en', name: 'English', native: 'English'),
    (code: 'am', name: 'Amharic', native: 'አማርኛ'),
    (code: 'om', name: 'Oromo', native: 'Afaan Oromoo'),
    (code: 'ti', name: 'Tigrinya', native: 'ትግርኛ'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);
    final currentCode = currentLocale.languageCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ..._languages.map(
              (lang) => ListTile(
                title: Text(lang.native),
                subtitle: lang.native != lang.name ? Text(lang.name) : null,
                trailing: currentCode == lang.code
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () async {
                  final locale = Locale(lang.code);
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(localeProvider.notifier).setLocale(locale);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
