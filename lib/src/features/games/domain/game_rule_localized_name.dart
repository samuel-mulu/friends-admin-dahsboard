import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/providers/locale_provider.dart';
import '../data/models/game_model.dart';

const _assetPath = 'assets/i18n/game_rule_names.json';

/// Loaded rule display names keyed by [GameRule.key] from the API.
class GameRuleNamesRepository {
  GameRuleNamesRepository._(this._namesByKey);

  final Map<String, Map<String, String>> _namesByKey;

  static Future<GameRuleNamesRepository> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final namesByKey = <String, Map<String, String>>{};
    for (final entry in decoded.entries) {
      if (entry.key.startsWith('_')) {
        continue;
      }
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        continue;
      }
      namesByKey[entry.key] = {
        for (final localeEntry in value.entries)
          if (localeEntry.value is String)
            localeEntry.key: localeEntry.value as String,
      };
    }

    return GameRuleNamesRepository._(namesByKey);
  }

  String nameForKey(
    String ruleKey,
    Locale locale, {
    String? fallback,
  }) {
    final normalizedKey = ruleKey.trim().toUpperCase();
    final translations = _namesByKey[normalizedKey];
    if (translations == null || translations.isEmpty) {
      return fallback ?? normalizedKey;
    }

    final localeCode = _resolveLocaleCode(locale);
    final localized = translations[localeCode];
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }

    final english = translations['en'];
    if (english != null && english.isNotEmpty) {
      return english;
    }

    return fallback ?? normalizedKey;
  }

  static String _resolveLocaleCode(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    if (code == 'om') {
      return 'en';
    }
    return code;
  }
}

final gameRuleNamesRepositoryProvider =
    FutureProvider<GameRuleNamesRepository>((ref) {
  return GameRuleNamesRepository.load();
});

typedef GameRuleNameLookup = ({String ruleKey, String fallback});

final localizedGameRuleNameProvider =
    Provider.family<String, GameRuleNameLookup>((ref, lookup) {
  final locale = ref.watch(localeProvider);
  final repository = ref.watch(gameRuleNamesRepositoryProvider).maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );

  return localizedGameRuleName(
    ruleKey: lookup.ruleKey,
    locale: locale,
    repository: repository,
    fallback: lookup.fallback,
  );
});

extension GameModelLocalizedName on GameModel {
  String localizedRuleName(WidgetRef ref) {
    return ref.watch(
      localizedGameRuleNameProvider(
        (ruleKey: ruleKey, fallback: ruleName),
      ),
    );
  }
}

String localizedGameRuleName({
  required String ruleKey,
  required Locale locale,
  required GameRuleNamesRepository? repository,
  String? fallback,
}) {
  if (repository == null) {
    return fallback ?? ruleKey;
  }

  return repository.nameForKey(
    ruleKey,
    locale,
    fallback: fallback,
  );
}
