import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/support_message_model.dart';
import '../providers/support_messages_provider.dart';
import '../widgets/support_message_tile.dart';

class MyFeedbackScreen extends ConsumerWidget {
  const MyFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final messagesAsync = ref.watch(mySupportMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportMyFeedbackTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mySupportMessagesProvider);
          await ref.read(mySupportMessagesProvider.future);
        },
        child: messagesAsync.when(
          data: (page) {
            final items = chronologicalSupportMessages(page.items);

            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screenPadding,
                children: [
                  Text(
                    l10n.supportMyFeedbackEmpty,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.screenPadding,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return SupportMessageTile(message: items[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screenPadding,
            children: [
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
