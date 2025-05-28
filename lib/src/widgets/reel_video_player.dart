import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../controllers/reel_controller.dart';
import 'package:get/get.dart';

/// Optimized video player widget for reels
class ReelVideoPlayer extends StatefulWidget {
  final ReelModel reel;
  final ReelController controller;
  final ReelConfig config;
  final void Function(Duration position)? onTap;
  final Widget Function(BuildContext context, ReelModel reel, String error)? errorBuilder;
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
  final RxBool _showControls = false.obs;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reel_${widget.reel.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _onVideoTapped,
        onDoubleTap: _onVideoDoubleTapped,
        child: Obx(() => Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildVideoContent(),
              if (_showControls.value) _buildPlayPauseIcon(),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Obx(() {
      final controller = widget.controller.currentVideoController;
      
      // Show loading if no controller or not initialized
      if (controller == null || !controller.value.isInitialized) {
        return _buildLoadingWidget();
      }

      // Show video with full screen cover
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    });
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, widget.reel);
    }

    // Single Lottie loading animation
    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Lottie.asset(
          'packages/flutter_awesome_reels/assets/reel-loading.json',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildPlayPauseIcon() {
    return Center(
      child: AnimatedOpacity(
        opacity: _showControls.value ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.controller.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final wasVisible = _isVisible.value;
    _isVisible.value = info.visibleFraction > 0.5;

    if (_isVisible.value && !wasVisible) {
      // Video became visible - play
      widget.controller.play();
    } else if (!_isVisible.value && wasVisible) {
      // Video became invisible - pause
      widget.controller.pause();
    }
  }

  void _onVideoTapped() {
    widget.controller.togglePlayPause();
    
    // Show play/pause icon briefly
    _showControls.value = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _showControls.value = false;
      }
    });

    if (widget.onTap != null) {
      final controller = widget.controller.currentVideoController;
      if (controller != null) {
        widget.onTap!(controller.value.position);
      }
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
