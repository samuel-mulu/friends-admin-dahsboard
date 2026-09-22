import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/widgets/auth_form_field.dart';
import '../../../auth/presentation/widgets/auth_validators.dart';

/// Returns the entered password when confirmed, or null if cancelled.
Future<String?> showWithdrawConfirmDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _WithdrawConfirmDialog(),
  );
}

class _WithdrawConfirmDialog extends StatefulWidget {
  const _WithdrawConfirmDialog();

  @override
  State<_WithdrawConfirmDialog> createState() => _WithdrawConfirmDialogState();
}

class _WithdrawConfirmDialogState extends State<_WithdrawConfirmDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.withdrawConfirmTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.withdrawConfirmMessage),
            const SizedBox(height: 16),
            AuthFormField(
              controller: _passwordController,
              label: l10n.securityCurrentPassword,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) => validatePassword(value, l10n),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.bulkCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.withdrawSubmit),
        ),
      ],
    );
  }
}
