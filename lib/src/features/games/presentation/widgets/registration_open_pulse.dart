import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/time/countdown_target_tracker.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/api_date_time.dart';
import '../../../../core/utils/l10n.dart';
import '../debug/live_realtime_debug.dart';
import '../utils/big_game_countdown.dart';
import '../widgets/game_countdown.dart';

/// Animated registration call-to-action for the live registration room.
class RegistrationOpenPulse extends StatefulWidget {
  const RegistrationOpenPulse({
    required this.ruleName,
    this.isGuest = false,
    this.scheduledStartAt,
    this.countdownOverrideLabel,
    this.titleOverride,
    this.animateMemberMessages = true,
    this.onRegistrationClosed,
    this.serverClock,
    this.countdownTracker,
    this.scopeKey,
    this.embedded = false,
    this.showFlair = true,
    this.useBigGameCountdownFormat = false,
    this.rotatingTitleMessages,
    this.rotatingSubtitleMessages,
    this.trailing,
    super.key,
  });

  static const messageRotationInterval = Duration(seconds: 5);
  static const pulseDuration = Duration(milliseconds: 2000);
  static const messageSwitchDuration = Duration(milliseconds: 550);

  final String ruleName;
  final bool isGuest;
  final DateTime? scheduledStartAt;
  final String? countdownOverrideLabel;
  final String? titleOverride;
  final bool animateMemberMessages;
  final VoidCallback? onRegistrationClosed;
  final ServerClockService? serverClock;
  final CountdownTargetTracker? countdownTracker;
  final String? scopeKey;
  final bool embedded;
  final bool showFlair;
  final bool useBigGameCountdownFormat;
  final List<String>? rotatingTitleMessages;
  final List<String>? rotatingSubtitleMessages;
  final Widget? trailing;

  @override
  State<RegistrationOpenPulse> createState() => _RegistrationOpenPulseState();
}

class _RegistrationOpenPulseState extends State<RegistrationOpenPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _borderGlow;
  late final Animation<double> _shine;
  late final Animation<double> _textScale;

  Timer? _messageTimer;
  Timer? _countdownTimer;
  int _messageIndex = 0;
  int? _secondsUntilStart;
  bool _registrationClosedNotified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RegistrationOpenPulse.pulseDuration,
    )..repeat(reverse: true);
    _borderGlow = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _shine = Tween<double>(
      begin: 0.1,
      end: 0.28,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _textScale = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (!widget.isGuest && widget.animateMemberMessages) {
      _messageTimer = Timer.periodic(
        RegistrationOpenPulse.messageRotationInterval,
        (_) {
          if (!mounted) {
            return;
          }
          setState(() => _messageIndex = (_messageIndex + 1) % 2);
        },
      );
    }

    _scheduleCountdownSync(fromLifecycle: true);
    if (widget.scheduledStartAt != null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _syncCountdown();
      });
    }
  }

  @override
  void didUpdateWidget(covariant RegistrationOpenPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateMemberMessages != widget.animateMemberMessages ||
        oldWidget.titleOverride != widget.titleOverride) {
      _messageTimer?.cancel();
      _messageTimer = null;
      if (!widget.isGuest && widget.animateMemberMessages) {
        _messageTimer = Timer.periodic(
          RegistrationOpenPulse.messageRotationInterval,
          (_) {
            if (!mounted) {
              return;
            }
            setState(() => _messageIndex = (_messageIndex + 1) % 2);
          },
        );
      } else {
        _messageIndex = 0;
      }
    }
    if (oldWidget.scheduledStartAt != widget.scheduledStartAt ||
        oldWidget.countdownOverrideLabel != widget.countdownOverrideLabel ||
        oldWidget.scopeKey != widget.scopeKey) {
      if (oldWidget.scopeKey != widget.scopeKey) {
        _registrationClosedNotified = false;
      }
      if (widget.scheduledStartAt != null &&
          widget.scheduledStartAt!.isAfter(_countdownNow())) {
        _registrationClosedNotified = false;
      }
      _countdownTimer?.cancel();
      _scheduleCountdownSync(fromLifecycle: true);
      if (widget.scheduledStartAt != null) {
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _syncCountdown();
        });
      } else if (_secondsUntilStart != null) {
        setState(() => _secondsUntilStart = null);
      }
    }
  }

  void _scheduleCountdownSync({required bool fromLifecycle}) {
    if (!fromLifecycle) {
      _syncCountdown();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncCountdown();
      }
    });
  }

  DateTime _countdownNow() {
    final clock = widget.serverClock;
    if (clock?.isSynced == true) {
      return clock!.nowLocal();
    }
    return DateTime.now();
  }

  void _syncCountdown() {
    if (_registrationClosedNotified) {
      return;
    }

    final target = widget.scheduledStartAt;
    if (!mounted) {
      return;
    }

    if (target == null) {
      widget.countdownTracker?.reset();
      _countdownTimer?.cancel();
      _countdownTimer = null;
      if (_secondsUntilStart != null && _secondsUntilStart! > 0) {
        setState(() => _secondsUntilStart = null);
      }
      return;
    }

    final rawSeconds = secondsUntilCeil(target, clock: widget.serverClock);
    final nextSeconds =
        widget.countdownTracker?.apply(
          target: target,
          scopeKey: widget.scopeKey,
          rawRemaining: rawSeconds,
        ) ??
        rawSeconds;

    LiveRealtimeDebug.countdown(
      target: target,
      serverNow: widget.serverClock?.lastServerNowUtc,
      deviceNow: DateTime.now(),
      offsetMs: widget.serverClock?.offsetMs,
      remaining: nextSeconds,
    );

    setState(() {
      _secondsUntilStart = nextSeconds;
    });

    if (nextSeconds > 0) {
      return;
    }

    _countdownTimer?.cancel();
    _countdownTimer = null;
    _notifyRegistrationClosed();
  }

  String _formattedCountdownRemaining() {
    final target = widget.scheduledStartAt;
    if (target == null) {
      return '--';
    }

    if (widget.useBigGameCountdownFormat) {
      return formatBigGameCountdown(target, clock: widget.serverClock);
    }

    return formatGameCountdown(target, clock: widget.serverClock);
  }

  List<String> _memberMessages(AppLocalizations l10n) =>
      widget.rotatingTitleMessages ??
      [
        widget.ruleName,
        l10n.registrationOpenBanner,
      ];

  List<String>? _subtitleMessages(AppLocalizations l10n) {
    if (widget.rotatingSubtitleMessages != null &&
        widget.rotatingSubtitleMessages!.isNotEmpty) {
      return widget.rotatingSubtitleMessages;
    }

    return null;
  }

  String _countdownLabel(AppLocalizations l10n) {
    final overrideLabel = widget.countdownOverrideLabel;
    if (overrideLabel != null) {
      return overrideLabel;
    }

    if (_registrationClosedNotified ||
        (_secondsUntilStart != null && _secondsUntilStart! <= 0)) {
      return l10n.registrationClosedPreparing;
    }

    if (widget.scheduledStartAt != null && _secondsUntilStart != null) {
      return _secondsUntilStart! > 0
          ? l10n.registrationClosesInDuration(_formattedCountdownRemaining())
          : l10n.registrationClosedPreparing;
    }

    return l10n.registrationOpenLabel;
  }

  void _notifyRegistrationClosed() {
    if (_registrationClosedNotified) {
      return;
    }

    _registrationClosedNotified = true;
    final callback = widget.onRegistrationClosed;
    if (callback == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        callback();
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final memberMessages = _memberMessages(l10n);
    final subtitleMessages = _subtitleMessages(l10n);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppBranding.gold : AppBranding.brandPurple;
    final titleShadows = isDark
        ? const [
            Shadow(
              color: Color(0x99000000),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ]
        : null;
    final accentIconColor = isDark
        ? AppBranding.gold.withValues(alpha: 0.9)
        : AppBranding.goldAccent;
    final staticTitle = widget.titleOverride ?? widget.ruleName;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.embedded) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: child,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? null : AppBranding.lightSurface,
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppBranding.casinoPurpleDeep,
                      AppBranding.casinoPurple,
                      AppBranding.casinoPurpleDeep.withValues(alpha: 0.9),
                    ],
                  )
                : null,
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: AppBranding.gold.withValues(alpha: _shine.value),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppBranding.brandPurple.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: isDark
                  ? AppBranding.gold.withValues(alpha: _borderGlow.value)
                  : Color.lerp(
                      AppBranding.lightOutline,
                      AppBranding.goldAccent,
                      _borderGlow.value * 0.65,
                    )!,
              width: isDark ? 2 : 1.5,
            ),
          ),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showFlair) ...[
                _PulsingDot(animation: _controller),
                const SizedBox(width: 8),
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 20,
                  color: accentIconColor,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ScaleTransition(
                  scale: _textScale,
                  child: widget.isGuest
                      ? Text(
                          l10n.registrationSignUpToPlay,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppBranding.wordmarkGold(size: 28).copyWith(
                            color: titleColor,
                            shadows: titleShadows,
                            fontSize: widget.embedded ? 22 : 28,
                          ),
                        )
                      : !widget.animateMemberMessages ||
                            widget.titleOverride != null
                      ? Text(
                          staticTitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppBranding.wordmarkGold(size: 28).copyWith(
                            color: titleColor,
                            shadows: titleShadows,
                            fontSize: widget.embedded ? 22 : 28,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: RegistrationOpenPulse.messageSwitchDuration,
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.35),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            memberMessages[
                              _messageIndex % memberMessages.length
                            ],
                            key: ValueKey(
                              memberMessages[
                                _messageIndex % memberMessages.length
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppBranding.wordmarkGold(size: 28).copyWith(
                              color: titleColor,
                              shadows: titleShadows,
                              fontSize: widget.embedded ? 22 : 28,
                            ),
                          ),
                        ),
                ),
              ),
              if (widget.showFlair) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 20,
                  color: accentIconColor,
                ),
                const SizedBox(width: 8),
                _PulsingDot(animation: _controller),
              ],
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          if (!widget.isGuest) ...[
            const SizedBox(height: 6),
            if (subtitleMessages != null &&
                subtitleMessages.length > 1 &&
                widget.animateMemberMessages &&
                widget.titleOverride == null)
              AnimatedSwitcher(
                duration: RegistrationOpenPulse.messageSwitchDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _CountdownLabel(
                  key: ValueKey(
                    subtitleMessages[_messageIndex % subtitleMessages.length],
                  ),
                  label: subtitleMessages[
                    _messageIndex % subtitleMessages.length
                  ],
                  isDark: isDark,
                  theme: theme,
                ),
              )
            else
              _CountdownLabel(
                label: _countdownLabel(l10n),
                isDark: isDark,
                theme: theme,
              ),
          ],
        ],
      ),
    );
  }
}

class _CountdownLabel extends StatelessWidget {
  const _CountdownLabel({
    super.key,
    required this.label,
    required this.isDark,
    required this.theme,
  });

  final String label;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: isDark
          ? AppBranding.gold.withValues(alpha: 0.95)
          : AppBranding.brandPurple,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (isDark) {
      return Text(
        label,
        textAlign: TextAlign.center,
        style: textStyle,
        softWrap: true,
        maxLines: 3,
      );
    }

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppBranding.lightSurfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textStyle,
            softWrap: true,
            maxLines: 3,
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppBranding.gold.withValues(
              alpha: 0.45 + (animation.value * 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: AppBranding.gold.withValues(
                  alpha: animation.value * 0.6,
                ),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
