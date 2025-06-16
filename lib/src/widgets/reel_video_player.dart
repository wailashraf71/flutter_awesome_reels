import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../controllers/reel_controller.dart';
import 'package:get/get.dart';

/// Instagram-like video player widget for reels
class ReelVideoPlayer extends StatefulWidget {
  final ReelModel reel;
  final ReelController controller;
  final ReelConfig config;
  final void Function(Duration position)? onTap;
  final Widget Function(BuildContext context, ReelModel reel, String error)?
      errorBuilder;
  final Widget Function(BuildContext context, ReelModel reel)? loadingBuilder;

  const ReelVideoPlayer({
    super.key,
    required this.reel,
    required this.controller,
    required this.config,
    this.onTap,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  final RxBool _isVisible = false.obs;
  final RxBool _showPlayPauseIcon = false.obs;
  final RxBool _isLongPressing = false.obs;
  bool _wasPlayingBeforeLongPress = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  /// Initialize video with proper error handling
  Future<void> _initializeVideo() async {
    if (_isInitialized) return;

    try {
      // Only initialize if this reel is currently active or about to be active
      if (widget.controller.isReelActive(widget.reel) ||
          widget.controller.currentReel.value == widget.reel) {
        await widget.controller.initializeVideoForReel(widget.reel);
        _isInitialized = true;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize video for reel: $e');
      _isInitialized =
          true; // Mark as initialized even on error to prevent infinite retry
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reel_${widget.reel.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _onVideoTapped,
        onDoubleTap: _onVideoDoubleTapped,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildVideoContent(),
              _buildProgressBar(),
              _buildPlayPauseIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Obx(() {
      // Get controller using the new approach
      VideoPlayerController? controller =
          widget.controller.getVideoControllerForReel(widget.reel);

      // Show loading if controller is initializing
      if (widget.controller.isVideoInitializing) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      // Show loading if no controller or not initialized
      if (controller == null || !controller.value.isInitialized) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      // Check for errors
      if (controller.value.hasError) {
        return _buildErrorWidget(
            controller.value.errorDescription ?? 'Unknown error');
      }

      // Add safety check for video size
      final videoSize = controller.value.size;
      if (videoSize.width <= 0 || videoSize.height <= 0) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              'Invalid video dimensions',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoSize.width,
          height: videoSize.height,
          child: VideoPlayer(controller),
        ),
      );
    });
  }

  Widget _buildErrorWidget(String error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, widget.reel, error);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text(
              'Video Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                setState(() => _isInitialized = false);
                await widget.controller.retry();
                await _initializeVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseIcon() {
    return Obx(() {
      if (!_showPlayPauseIcon.value) return const SizedBox.shrink();

      return Center(
        child: AnimatedOpacity(
          opacity: _showPlayPauseIcon.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Obx(() => Icon(
                  widget.controller.isPlaying.value
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                )),
          ),
        ),
      );
    });
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Obx(() {
        if (_showPlayPauseIcon.value) {
          return const SizedBox.shrink();
        }

        final controller =
            widget.controller.getVideoControllerForReel(widget.reel);
        if (controller == null || !controller.value.isInitialized) {
          return const SizedBox.shrink();
        }

        final duration = controller.value.duration;
        final position = controller.value.position;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _isLongPressing.value = true;
    _wasPlayingBeforeLongPress = widget.controller.isPlaying.value;
    widget.controller.pause();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _isLongPressing.value = false;
    if (_isVisible.value && _wasPlayingBeforeLongPress) {
      widget.controller.play();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final wasVisible = _isVisible.value;
    _isVisible.value = info.visibleFraction > 0.5;

    if (_isVisible.value && !wasVisible) {
      _initializeVideo();
      final isCurrent = widget.controller.isReelActive(widget.reel);
      if (isCurrent) {
        widget.controller.play();
      }
    }
  }

  void _onVideoTapped() {
    widget.controller.togglePlayPause();

    // Show play/pause icon briefly
    _showPlayPauseIcon.value = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _showPlayPauseIcon.value = false;
      }
    });

    if (widget.onTap != null) {
      Duration position = Duration.zero;
      final controller =
          widget.controller.getVideoControllerForReel(widget.reel);
      if (controller != null) {
        position = controller.value.position;
      }
      widget.onTap!(position);
    }
  }

  void _onVideoDoubleTapped() {
    // Show like animation
    _showLikeAnimation();
  }

  void _showLikeAnimation() {
    if (mounted) {
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => _LikeAnimationOverlay(
          onComplete: () => entry.remove(),
        ),
      );
      overlay.insert(entry);
    }
  }
}

/// Like animation overlay
class _LikeAnimationOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const _LikeAnimationOverlay({required this.onComplete});

  @override
  State<_LikeAnimationOverlay> createState() => _LikeAnimationOverlayState();
}

class _LikeAnimationOverlayState extends State<_LikeAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 100,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
