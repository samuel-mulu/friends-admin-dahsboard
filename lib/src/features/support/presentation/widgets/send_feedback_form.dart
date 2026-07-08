import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/support_message_model.dart';
import '../../data/repositories/support_repository.dart';
import '../providers/support_messages_provider.dart';

class SendFeedbackForm extends ConsumerStatefulWidget {
  const SendFeedbackForm({
    this.onSubmitted,
    super.key,
  });

  final VoidCallback? onSubmitted;

  @override
  ConsumerState<SendFeedbackForm> createState() => _SendFeedbackFormState();
}

class _SendFeedbackFormState extends ConsumerState<SendFeedbackForm> {
  final _messageController = TextEditingController();
  SupportCategory _category = SupportCategory.feedback;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(supportRepositoryProvider).submitMessage(
            category: _category,
            message: message,
          );
      ref.invalidate(mySupportMessagesProvider);

      if (!mounted) {
        return;
      }

      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.supportMessageSent)),
      );
      widget.onSubmitted?.call();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.supportMessageSendFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.supportSendFeedbackSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.supportCategoryLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: SupportCategory.values.map((category) {
            return ChoiceChip(
              label: Text(_categoryLabel(l10n, category)),
              selected: _category == category,
              onSelected: (_) => setState(() => _category = category),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _messageController,
          maxLines: 6,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: l10n.supportMessageLabel,
            hintText: l10n.supportMessageHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.supportSendButton),
        ),
      ],
    );
  }

  String _categoryLabel(dynamic l10n, SupportCategory category) {
    return switch (category) {
      SupportCategory.feedback => l10n.supportCategoryFeedback,
      SupportCategory.complaint => l10n.supportCategoryComplaint,
      SupportCategory.advice => l10n.supportCategoryAdvice,
      SupportCategory.other => l10n.supportCategoryOther,
    };
  }
}
