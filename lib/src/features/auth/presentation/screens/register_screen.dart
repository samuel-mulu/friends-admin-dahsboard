import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../../domain/registration_draft.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_flow_provider.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_home_back_button.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_validators.dart';
import '../widgets/register_otp_panel.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_handleFullNameChanged);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_handleFullNameChanged);
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = ref.watch(registerStepProvider);
    final draft = ref.watch(registrationDraftProvider);
    final authState = ref.watch(authControllerProvider);

    return AuthErrorListener(
      child: AuthScreenScaffold(
        leading: const AuthHomeBackButton(),
        footer: step == RegisterStep.details
            ? TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.registerAlreadyHaveAccount),
              )
            : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: step == RegisterStep.otp && draft != null
              ? RegisterOtpPanel(
                  key: const ValueKey('register-otp'),
                  draft: draft,
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    key: const ValueKey('register-details'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            UserProfileAvatar(
                              fullName: _previewName,
                              avatarId: _selectedAvatarId,
                              radius: 34,
                              showBorder: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Choose avatar',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Optional for your profile',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickAvatar,
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(
                                    _selectedAvatarId == null
                                        ? 'Choose avatar'
                                        : 'Change avatar',
                                  ),
                                ),
                                if (_selectedAvatarId != null)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedAvatarId = null;
                                      });
                                    },
                                    child: const Text('Use initials'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      AuthFormField(
                        controller: _fullNameController,
                        label: l10n.registerFullName,
                        hint: l10n.registerFullNameHint,
                        prefixIcon: Icons.person_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => validateFullName(v, l10n),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        controller: _phoneController,
                        label: l10n.loginPhone,
                        hint: l10n.loginPhoneHint,
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (v) => validatePhoneNumber(v, l10n),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        controller: _passwordController,
                        label: l10n.registerPassword,
                        hint: l10n.registerPasswordHint,
                        prefixIcon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => validatePassword(v, l10n),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        controller: _confirmPasswordController,
                        label: l10n.registerConfirmPassword,
                        hint: l10n.registerConfirmPasswordHint,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return l10n.validatorPasswordMismatch;
                          }
                          return validatePassword(value, l10n);
                        },
                        onFieldSubmitted: (_) => _continueToOtp(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: l10n.registerContinue,
                        isLoading: authState.isSendingOtp,
                        onPressed: _continueToOtp,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _continueToOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneNumber = _phoneController.text.trim();

    ref.read(registrationDraftProvider.notifier).save(
          RegistrationDraft(
            fullName: _fullNameController.text.trim(),
            phoneNumber: phoneNumber,
            password: _passwordController.text,
            avatarId: _selectedAvatarId,
          ),
        );

    final message = await ref
        .read(authControllerProvider.notifier)
        .requestRegisterOtp(phoneNumber: phoneNumber);

    if (!mounted) {
      return;
    }

    if (message != null) {
      ref.read(registerStepProvider.notifier).showOtp();
    }
  }

  String get _previewName {
    final value = _fullNameController.text.trim();
    return value.isEmpty ? 'Friends Bingo' : value;
  }

  void _handleFullNameChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAvatar() async {
    final result = await showAvatarPickerSheet(
      context,
      selectedAvatarId: _selectedAvatarId,
      previewName: _previewName,
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedAvatarId =
          result == kClearAvatarSelection || result.isEmpty ? null : result;
    });
  }
}
