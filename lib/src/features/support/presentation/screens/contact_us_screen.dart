import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../widgets/send_feedback_form.dart';

class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportSendFeedbackTitle),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: const [
          SendFeedbackForm(),
        ],
      ),
    );
  }
}
