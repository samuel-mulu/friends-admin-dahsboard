import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';

/// Resend OTP button with a cooldown countdown (default 3 minutes).
class OtpResendButton extends StatefulWidget {
  const OtpResendButton({
    required this.onPressed,
    required this.isSending,
    this.cooldownSeconds = 180,
    super.key,
  });

  final Future<void> Function() onPressed;
  final bool isSending;
  final int cooldownSeconds;

  @override
  State<OtpResendButton> createState() => _OtpResendButtonState();
}

class _OtpResendButtonState extends State<OtpResendButton> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = widget.cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  Future<void> _handlePressed() async {
    if (_secondsRemaining > 0 || widget.isSending) {
      return;
    }

    await widget.onPressed();
    if (mounted) {
      _startCooldown();
    }
  }

  String _cooldownLabel(AppLocalizations l10n) {
    final total = _secondsRemaining;
    if (total >= 60) {
      final minutes = total ~/ 60;
      final seconds = total % 60;
      if (seconds == 0) {
        return l10n.otpResendInMinutes(minutes);
      }
      return l10n.otpResendInMinutesSeconds(minutes, seconds);
    }

    return l10n.otpResendInSeconds(total);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canResend = _secondsRemaining == 0 && !widget.isSending;

    return OutlinedButton(
      onPressed: canResend ? _handlePressed : null,
      child: widget.isSending
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _secondsRemaining > 0
                  ? _cooldownLabel(l10n)
                  : l10n.otpResendCode,
            ),
    );
  }
}
