import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_branding.dart';

/// Four-digit OTP input designed for SMS verification flows.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    required this.onChanged,
    this.onCompleted,
    this.length = 4,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final int length;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  void _notifyChanged() {
    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _controllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      _notifyChanged();
      return;
    }

    if (digits.length > 1) {
      _fillFromPaste(index, digits);
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection = TextSelection.collapsed(
      offset: _controllers[index].text.length,
    );

    if (digits.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    _notifyChanged();
  }

  void _fillFromPaste(int startIndex, String digits) {
    var cursor = startIndex;
    for (var i = 0; i < digits.length; i++) {
      if (cursor >= widget.length) {
        break;
      }
      _controllers[cursor].text = digits[i];
      cursor++;
    }

    if (cursor < widget.length) {
      _focusNodes[cursor].requestFocus();
    } else {
      _focusNodes.last.unfocus();
    }

    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == widget.length - 1 ? 0 : 10),
          child: SizedBox(
            width: 56,
            height: 60,
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: index == widget.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppBranding.casinoPurple,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) => _handleChanged(index, value),
              onTap: () {
                _controllers[index].selection = TextSelection.collapsed(
                  offset: _controllers[index].text.length,
                );
              },
              onFieldSubmitted: (_) {
                if (index < widget.length - 1) {
                  _focusNodes[index + 1].requestFocus();
                }
              },
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
        );
      }),
    );
  }
}
