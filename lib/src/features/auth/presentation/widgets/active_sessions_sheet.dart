import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_device_session.dart';

Future<void> showActiveSessionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ActiveSessionsSheet(),
  );
}

class _ActiveSessionsSheet extends ConsumerStatefulWidget {
  const _ActiveSessionsSheet();

  @override
  ConsumerState<_ActiveSessionsSheet> createState() =>
      _ActiveSessionsSheetState();
}

class _ActiveSessionsSheetState extends ConsumerState<_ActiveSessionsSheet> {
  late Future<List<AuthDeviceSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AuthDeviceSession>> _load() async {
    final storage = ref.read(secureTokenStorageProvider);
    final refreshToken = await storage.readRefreshToken();
    final deviceId = await storage.ensureDeviceId();
    if (refreshToken == null || refreshToken.isEmpty) {
      return [];
    }
    return ref.read(authRepositoryProvider).listSessions(
          refreshToken: refreshToken,
          deviceId: deviceId,
        );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.securityActiveSessions,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<List<AuthDeviceSession>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error! as ApiException).message
                        : l10n.securitySessionsLoadFailed;
                    return Text(message);
                  }
                  final sessions = snapshot.data ?? [];
                  if (sessions.isEmpty) {
                    return Text(l10n.securityNoSessions);
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(session.displayLabel),
                        subtitle: Text(
                          session.isCurrent
                              ? l10n.securityThisDevice
                              : (session.platform ?? ''),
                        ),
                        trailing: session.isCurrent
                            ? Chip(label: Text(l10n.securityCurrent))
                            : TextButton(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(authRepositoryProvider)
                                        .revokeSession(session.id);
                                    await _reload();
                                  } catch (error) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    final message = error is ApiException
                                        ? error.message
                                        : l10n.securitySessionsLoadFailed;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                },
                                child: Text(l10n.securityLogoutDevice),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final storage = ref.read(secureTokenStorageProvider);
                final refreshToken = await storage.readRefreshToken();
                final deviceId = await storage.ensureDeviceId();
                if (refreshToken == null) {
                  return;
                }
                try {
                  await ref.read(authRepositoryProvider).logoutOtherSessions(
                        refreshToken: refreshToken,
                        deviceId: deviceId,
                      );
                  await _reload();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.securityOthersLoggedOut)),
                  );
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  final message = error is ApiException
                      ? error.message
                      : l10n.securitySessionsLoadFailed;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
              child: Text(l10n.securityLogoutOthers),
            ),
          ],
        ),
      ),
    );
  }
}
