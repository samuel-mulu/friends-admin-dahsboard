import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/utils/l10n.dart';
import '../../data/models/payment_provider.dart';
import '../guides/deposit_guide_config.dart';
import '../utils/youtube_video_id.dart';

/// Deposit instructions with tabs: image steps + in-app YouTube player.
class DepositGuideSteps extends StatefulWidget {
  const DepositGuideSteps({
    required this.provider,
    this.youtubeUrl,
    this.requestedTabIndex,
    super.key,
  });

  final PaymentProvider provider;
  final String? youtubeUrl;

  /// 0 = steps, 1 = video. Updated when user taps Instructions.
  final ValueListenable<int>? requestedTabIndex;

  @override
  State<DepositGuideSteps> createState() => _DepositGuideStepsState();
}

class _DepositGuideStepsState extends State<DepositGuideSteps>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  YoutubePlayerController? _youtubeController;
  String? _loadedVideoId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    widget.requestedTabIndex?.addListener(_onTabRequested);
    final initial = widget.requestedTabIndex?.value;
    if (initial != null && initial >= 0 && initial < 2) {
      _tabController.index = initial;
    }
    _syncYoutubePlayer();
  }

  @override
  void didUpdateWidget(covariant DepositGuideSteps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestedTabIndex != widget.requestedTabIndex) {
      oldWidget.requestedTabIndex?.removeListener(_onTabRequested);
      widget.requestedTabIndex?.addListener(_onTabRequested);
    }
    if (oldWidget.provider != widget.provider ||
        oldWidget.youtubeUrl != widget.youtubeUrl) {
      _syncYoutubePlayer(forceReload: true);
    }
  }

  @override
  void dispose() {
    widget.requestedTabIndex?.removeListener(_onTabRequested);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _disposeYoutube();
    super.dispose();
  }

  void _onTabRequested() {
    final index = widget.requestedTabIndex?.value;
    if (index == null || index < 0 || index > 1) {
      return;
    }
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    if (_tabController.index != 1) {
      _youtubeController?.pauseVideo();
    } else {
      _syncYoutubePlayer();
    }
  }

  void _disposeYoutube() {
    _youtubeController?.close();
    _youtubeController = null;
    _loadedVideoId = null;
  }

  void _syncYoutubePlayer({bool forceReload = false}) {
    final videoId = youtubeVideoIdFromUrl(widget.youtubeUrl);
    if (videoId == null) {
      if (_youtubeController != null) {
        setState(_disposeYoutube);
      }
      return;
    }

    if (!forceReload &&
        _youtubeController != null &&
        _loadedVideoId == videoId) {
      return;
    }

    _youtubeController?.close();
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        playsInline: true,
        strictRelatedVideos: true,
        enableCaption: true,
      ),
    );
    setState(() {
      _youtubeController = controller;
      _loadedVideoId = videoId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final steps = depositGuideStepsFor(widget.provider);
    final videoId = youtubeVideoIdFromUrl(widget.youtubeUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.depositGuideTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          borderRadius: BorderRadius.circular(14),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: [
              Tab(text: l10n.depositGuideTabSteps),
              Tab(text: l10n.depositGuideTabVideo),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            if (_tabController.index == 1) {
              return _DepositGuideVideoPane(
                controller: _youtubeController,
                videoId: videoId,
                youtubeUrl: widget.youtubeUrl,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  _GuideStepCard(
                    stepNumber: index + 1,
                    label: steps[index].label(l10n),
                    imageAsset: steps[index].imageAsset,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DepositGuideVideoPane extends StatelessWidget {
  const _DepositGuideVideoPane({
    required this.controller,
    required this.videoId,
    required this.youtubeUrl,
  });

  final YoutubePlayerController? controller;
  final String? videoId;
  final String? youtubeUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (videoId == null || controller == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.ondemand_video_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.depositGuideVideoMissing,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: controller!,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.depositGuideVideoHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final raw = (youtubeUrl ?? '').trim();
              final uri = Uri.tryParse(
                raw.startsWith('http')
                    ? raw
                    : 'https://www.youtube.com/watch?v=$videoId',
              );
              if (uri == null) {
                return;
              }
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(l10n.depositGuideOpenOnYoutube),
          ),
        ),
      ],
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.stepNumber,
    required this.label,
    required this.imageAsset,
  });

  final int stepNumber;
  final String label;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDepositGuideImagePreview(
          context,
          imageAsset: imageAsset,
          label: label,
          stepNumber: stepNumber,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '$stepNumber',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Text(
                                    l10n.depositGuideImageMissing,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.open_in_full_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.depositGuideTapToExpand,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showDepositGuideImagePreview(
  BuildContext context, {
  required String imageAsset,
  required String label,
  required int stepNumber,
}) {
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.88;

      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '$stepNumber',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        dialogContext,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.75,
                  maxScale: 4,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.depositGuideImageMissing,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}
