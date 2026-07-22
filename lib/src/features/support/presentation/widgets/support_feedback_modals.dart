import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_support.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/support_message_model.dart';
import '../providers/support_messages_provider.dart';
import '../providers/support_unread_provider.dart';
import '../widgets/send_feedback_form.dart';
import '../widgets/support_message_tile.dart';

Future<void> showFeedbackHubModal(BuildContext context, WidgetRef ref) {
  final session = ref.read(authControllerProvider).session;
  if (session != null) {
    unawaited(
      ref.read(supportUnreadCountProvider.notifier).markSeenAndClear(),
    );
    ref.invalidate(mySupportMessagesProvider);
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _FeedbackHubSheet(parentContext: context),
  );
}

Future<void> showSendFeedbackModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => const _SendFeedbackSheet(),
  );
}

class _FeedbackHubSheet extends ConsumerWidget {
  const _FeedbackHubSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isGuest = ref.watch(authControllerProvider).session == null;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.supportFeedbackHubTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _openSendFeedback(context, ref),
                icon: const Icon(Icons.add_comment_rounded),
                label: Text(l10n.drawerSendFeedback),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isGuest)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.drawerSignInToPlay,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            parentContext.go(loginPathWithRedirect('/games'));
                          },
                          child: Text(l10n.signIn),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  child: _MyFeedbackChatSection(),
                ),
              const SizedBox(height: AppSpacing.md),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppSupport.contactTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppSupport.supportPhoneDisplay,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSendFeedback(BuildContext context, WidgetRef ref) {
    if (ref.read(authControllerProvider).session == null) {
      Navigator.of(context).pop();
      parentContext.go(loginPathWithRedirect('/support/contact'));
      return;
    }

    showSendFeedbackModal(context);
  }
}

class _MyFeedbackChatSection extends ConsumerStatefulWidget {
  const _MyFeedbackChatSection();

  @override
  ConsumerState<_MyFeedbackChatSection> createState() =>
      _MyFeedbackChatSectionState();
}

class _MyFeedbackChatSectionState extends ConsumerState<_MyFeedbackChatSection> {
  final _scrollController = ScrollController();
  int _lastScrolledCount = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(mySupportMessagesProvider);

    ref.listen(mySupportMessagesProvider, (previous, next) {
      next.whenData((page) {
        final count = page.items.length;
        if (count > 0 && count != _lastScrolledCount) {
          _lastScrolledCount = count;
          _scrollToBottom();
        }
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.drawerMyFeedback,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: messagesAsync.when(
            data: (page) {
              final items = chronologicalSupportMessages(page.items);

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    l10n.supportMyFeedbackEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (_lastScrolledCount != items.length) {
                _lastScrolledCount = items.length;
                _scrollToBottom();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(mySupportMessagesProvider);
                  await ref.read(mySupportMessagesProvider.future);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return SupportMessageTile(message: items[index]);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ),
      ],
    );
  }
}

class _SendFeedbackSheet extends StatelessWidget {
  const _SendFeedbackSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.sm,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_comment_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.supportSendFeedbackTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SendFeedbackForm(
                onSubmitted: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
