import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/reel_controller.dart';
import 'models/reel_config.dart';
import 'models/reel_model.dart';
import 'widgets/reel_overlay.dart';
import 'widgets/reel_video_player.dart';

/// The main AwesomeReels widget for displaying vertical video reels
class AwesomeReels extends StatefulWidget {
  /// List of reel models to display
  final List<ReelModel> reels;

  /// Configuration for the reels widget
  final ReelConfig config;

  /// Initial page index
  final int initialIndex;

  /// Callback when page changes
  final void Function(int index, ReelModel reel)? onPageChanged;

  /// Callback when video tapped
  final void Function(ReelModel reel, Duration position)? onTap;

  /// Callback when video long pressed
  final void Function(ReelModel reel, Duration position)? onLongPress;

  /// Callback when like button tapped
  final void Function(ReelModel reel, bool isLiked)? onLikeTapped;

  /// Callback when comment button tapped
  final void Function(ReelModel reel)? onCommentTapped;

  /// Callback when share button tapped
  final void Function(ReelModel reel)? onShareTapped;

  /// Callback when follow button tapped
  final void Function(ReelModel reel, bool isFollowing)? onFollowTapped;

  /// Callback when user profile tapped
  final void Function(ReelModel reel)? onUserProfileTapped;

  /// Custom overlay builder
  final Widget Function(
          BuildContext context, ReelModel reel, ReelController controller)?
      overlayBuilder;

  /// Custom error widget builder
  final Widget Function(BuildContext context, ReelModel reel, String error)?
      errorBuilder;

  /// Custom loading widget builder
  final Widget Function(BuildContext context, ReelModel reel)? loadingBuilder;

  final ReelController? controller;
  final void Function(int index)? onReelChanged;
  final void Function(ReelModel reel)? onReelLiked;
  final void Function(ReelModel reel)? onReelShared;
  final void Function(ReelModel reel)? onReelCommented;
  final void Function(ReelUser user)? onUserFollowed;
  final void Function(ReelUser user)? onUserBlocked;
  final void Function(ReelModel reel)? onVideoCompleted;
  final void Function(ReelModel reel, Object error)? onVideoError;

  const AwesomeReels({
    super.key,
    required this.reels,
    this.config = const ReelConfig(),
    this.initialIndex = 0,
    this.controller,
    this.onReelChanged,
    this.onReelLiked,
    this.onReelShared,
    this.onReelCommented,
    this.onUserFollowed,
    this.onUserBlocked,
    this.onVideoCompleted,
    this.onVideoError,
    this.onPageChanged,
    this.onTap,
    this.onLongPress,
    this.onLikeTapped,
    this.onCommentTapped,
    this.onShareTapped,
    this.onFollowTapped,
    this.onUserProfileTapped,
    this.overlayBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<AwesomeReels> createState() => _AwesomeReelsState();
}

class _AwesomeReelsState extends State<AwesomeReels>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late ReelController _controller;
  bool _isExternalController = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isExternalController = widget.controller != null;
    if (widget.controller != null) {
      _controller = widget.controller!;
      Get.put(_controller, permanent: true);
    } else {
      _controller = Get.put(ReelController(), permanent: true);
    }
    _initializeController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.setAppVisibility(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _controller.setAppVisibility(false);
        break;
      case AppLifecycleState.hidden:
        _controller.setAppVisibility(false);
        break;
    }
  }

  @override
  void didUpdateWidget(AwesomeReels oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize if reels or config changed
    if (widget.reels != oldWidget.reels || widget.config != oldWidget.config) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initialize(
        reels: widget.reels,
        config: widget.config,
        initialIndex: widget.initialIndex,
      );
    } catch (e) {
      debugPrint('Error initializing AwesomeReels: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: widget.config.backgroundColor,
      child: widget.config.enablePullToRefresh
          ? RefreshIndicator(
              onRefresh: () async {
                _controller.refresh();
              },
              child: _buildPageView(),
            )
          : _buildPageView(),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _controller.pageController,
      scrollDirection: Axis.vertical,
      physics: widget.config.physics,
      itemCount: widget.reels.length,
      onPageChanged: (index) {
        _controller.onPageChanged(index);
        if (widget.onReelChanged != null) {
          widget.onReelChanged!(index);
        }
      },
      itemBuilder: (context, index) {
        if (index >= widget.reels.length) return const SizedBox.shrink();
        final reel = widget.reels[index];
        return _buildReelItem(reel, index);
      },
    );
  }

  Widget _buildReelItem(ReelModel reel, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelVideoPlayer(
          key: ValueKey('reel_video_${reel.id}'),
          reel: reel,
          controller: _controller,
          config: widget.config,
          errorBuilder: (context, reel, error) {
            if (widget.onVideoError != null) {
              widget.onVideoError!(reel, error);
            }
            return widget.errorBuilder?.call(context, reel, error) ??
                const SizedBox.shrink();
          },
          loadingBuilder: widget.loadingBuilder,
        ),
        if (widget.overlayBuilder != null)
          widget.overlayBuilder!(context, reel, _controller)
        else
          ReelOverlay(
            reel: reel,
            config: widget.config,
            controller: _controller,
            onTap: widget.onTap != null
                ? () => widget.onTap!(reel, _controller.currentPosition.value)
                : null,
            onLongPress: widget.onLongPress != null
                ? () =>
                    widget.onLongPress!(reel, _controller.currentPosition.value)
                : null,
            onLike: () => widget.onReelLiked?.call(reel),
            onShare: () => widget.onReelShared?.call(reel),
            onComment: () => widget.onReelCommented?.call(reel),
            onFollow: () => widget.onUserFollowed?.call(reel.user!),
            onBlock: () => widget.onUserBlocked?.call(reel.user!),
            onCompleted: () => widget.onVideoCompleted?.call(reel),
          ),
      ],
    );
  }
}

/// Extension methods for AwesomeReels
extension AwesomeReelsExtension on AwesomeReels {
  /// Create AwesomeReels from video URLs
  static AwesomeReels fromUrls(
    List<String> videoUrls, {
    ReelConfig config = const ReelConfig(),
    int initialIndex = 0,
    void Function(int index, ReelModel reel)? onPageChanged,
    void Function(ReelModel reel, Duration position)? onVideoTapped,
  }) {
    final reels = videoUrls.asMap().entries.map((entry) {
      return ReelModel(
        id: 'reel_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
        videoUrl: entry.value, // kept for backward compatibility
      );
    }).toList();

    return AwesomeReels(
      reels: reels,
      config: config,
      initialIndex: initialIndex,
      onPageChanged: onPageChanged,
      onTap: onVideoTapped,
    );
  }
}
