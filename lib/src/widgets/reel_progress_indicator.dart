import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../controllers/reel_controller.dart';
import '../models/reel_config.dart';
import '../models/reel_model.dart';
import '../utils/reel_utils.dart';

/// Perfect video progress indicator with seeking, thumbnails, and smooth animations
class ReelProgressIndicator extends StatefulWidget {
  final ReelModel reel;
  final ReelConfig config;
  final bool showThumb;
  final bool showTime;
  final double height;
  final Function(Duration)? onSeek;
  final bool showThumbnail;

  const ReelProgressIndicator({
    super.key,
    required this.reel,
    required this.config,
    this.showThumb = true,
    this.showTime = false,
    this.height = 4.0,
    this.onSeek,
    this.showThumbnail = true,
  });

  @override
  State<ReelProgressIndicator> createState() => _ReelProgressIndicatorState();
}

class _ReelProgressIndicatorState extends State<ReelProgressIndicator>
    with TickerProviderStateMixin {
  // Interaction state
  final RxBool _isDragging = false.obs;
  final RxnDouble _dragValue = RxnDouble();

  // Thumbnail preview state
  final RxBool _showThumbnail = false.obs;
  final RxnDouble _thumbnailPosition = RxnDouble();
  final Rx<Duration> _thumbnailTime = Rx<Duration>(Duration.zero);

  // Animation controllers
  late AnimationController _scaleAnimationController;
  late AnimationController _thumbAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _thumbSizeAnimation;
  late Animation<double> _trackHeightAnimation;

  // Gesture tracking
  bool _wasPlayingBeforeDrag = false;

  @override
  void initState() {
    super.initState();

    // Scale animation for interaction feedback
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeOut,
    ));

    // Thumb size and track height animation
    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _thumbSizeAnimation = Tween<double>(
      begin: 12.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _thumbAnimationController,
      curve: Curves.elasticOut,
    ));

    _trackHeightAnimation = Tween<double>(
      begin: widget.height,
      end: widget.height * 1.5,
    ).animate(CurvedAnimation(
      parent: _thumbAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _thumbAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReelController>();
    return Obx(() {
      final videoController = controller.currentVideoController;
      if (videoController == null || !videoController.value.isInitialized) {
        return const SizedBox.shrink();
      }

      return ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: videoController,
        builder: (context, value, child) {
          if (!value.isInitialized) {
            return const SizedBox.shrink();
          }

          final position = value.position;
          final duration = value.duration;

          if (duration.inMilliseconds <= 0) {
            return const SizedBox.shrink();
          }

          // Calculate current progress
          final actualProgress =
              position.inMilliseconds / duration.inMilliseconds;
          final displayProgress = _isDragging.value
              ? (_dragValue.value ?? actualProgress)
              : actualProgress;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Thumbnail preview
              if (widget.showThumbnail && _showThumbnail.value)
                _buildThumbnailPreview(),

              // Main progress bar
              _buildProgressTrack(
                controller,
                displayProgress,
                duration,
                position,
              ),

              // Time indicators
              if (widget.showTime) ...[
                const SizedBox(height: 8),
                _buildTimeIndicators(position, duration),
              ],
            ],
          );
        },
      );
    });
  }

  Widget _buildThumbnailPreview() {
    return Obx(() {
      if (!_showThumbnail.value || _thumbnailPosition.value == null) {
        return const SizedBox.shrink();
      }

      final position = _thumbnailPosition.value!;
      final time = _thumbnailTime.value;
      final screenWidth = MediaQuery.of(context).size.width;

      // Calculate safe left position to keep thumbnail on screen
      final thumbnailWidth = 150.0;
      final safeLeft = (position - thumbnailWidth / 2)
          .clamp(16.0, screenWidth - thumbnailWidth - 16.0);

      return Positioned(
        bottom: 40, // Position above the progress bar
        left: safeLeft,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 150),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value), // Animate in with scale
              child: Opacity(
                opacity: value,
                child: Container(
                  width: thumbnailWidth,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 3,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      children: [
                        // Video frame placeholder with better styling
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.grey.shade800,
                                Colors.grey.shade900,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white70,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Preview',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Time display with better styling
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            ReelUtils.formatDuration(time),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildProgressTrack(
    ReelController controller,
    double progress,
    Duration duration,
    Duration position,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_scaleAnimation, _trackHeightAnimation, _thumbSizeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 50,
            // Increased hit area for easier interaction
            padding: const EdgeInsets.symmetric(vertical: 20),
            // More padding for touch
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Make entire area responsive
              onTapDown: _handleTapDown,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: SizedBox(
                height: 20, // Visual container height
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track
                    Container(
                      height: _trackHeightAnimation.value,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        // Light grey background
                        borderRadius: BorderRadius.circular(
                            _trackHeightAnimation.value / 2),
                      ),
                    ),

                    // Active progress
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: _trackHeightAnimation.value,
                          decoration: BoxDecoration(
                            color: widget.config.progressColor ?? Colors.white,
                            borderRadius: BorderRadius.circular(
                                _trackHeightAnimation.value / 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // Gesture handlers
  void _handleTapDown(TapDownDetails details) {
    final controller = Get.find<ReelController>();
    final videoController = controller.currentVideoController;
    if (videoController == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final width = box.size.width;
    final tapPosition = (localPosition.dx / width).clamp(0.0, 1.0);
    final duration = videoController.value.duration;

    final newPosition = Duration(
      milliseconds: (tapPosition * duration.inMilliseconds).round(),
    );

    // Immediate seek on tap
    controller.seekTo(newPosition);
    if (widget.onSeek != null) {
      widget.onSeek!(newPosition);
    }

    // Visual feedback
    _scaleAnimationController.forward().then((_) {
      _scaleAnimationController.reverse();
    });
  }

  void _handlePanStart(DragStartDetails details) {
    final controller = Get.find<ReelController>();
    final videoController = controller.currentVideoController;
    if (videoController == null) return;

    // Store playback state
    _wasPlayingBeforeDrag = controller.isPlaying.value;
    if (_wasPlayingBeforeDrag) {
      controller.pause();
    }

    // Start drag state
    _isDragging.value = true;
    _thumbAnimationController.forward();
    _scaleAnimationController.forward();

    // Calculate initial position
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final width = box.size.width;
    final dragPosition = (localPosition.dx / width).clamp(0.0, 1.0);
    _dragValue.value = dragPosition;

    // Show thumbnail if enabled
    if (widget.showThumbnail) {
      _showThumbnail.value = true;
      _thumbnailPosition.value = localPosition.dx;
      final duration = videoController.value.duration;
      _thumbnailTime.value = Duration(
        milliseconds: (dragPosition * duration.inMilliseconds).round(),
      );
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final controller = Get.find<ReelController>();
    final videoController = controller.currentVideoController;
    if (videoController == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final width = box.size.width;
    final dragPosition = (localPosition.dx / width).clamp(0.0, 1.0);
    _dragValue.value = dragPosition;

    // Update thumbnail position
    if (widget.showThumbnail && _showThumbnail.value) {
      _thumbnailPosition.value = localPosition.dx;
      final duration = videoController.value.duration;
      _thumbnailTime.value = Duration(
        milliseconds: (dragPosition * duration.inMilliseconds).round(),
      );
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final controller = Get.find<ReelController>();
    final videoController = controller.currentVideoController;

    if (videoController != null && _dragValue.value != null) {
      final duration = videoController.value.duration;
      final newPosition = Duration(
        milliseconds: (_dragValue.value! * duration.inMilliseconds).round(),
      );

      // Perform the actual seek
      controller.seekTo(newPosition);
      if (widget.onSeek != null) {
        widget.onSeek!(newPosition);
      }

      // Resume playback if it was playing before
      if (_wasPlayingBeforeDrag) {
        Future.delayed(const Duration(milliseconds: 150), () {
          controller.play();
        });
      }
    }

    // Reset drag state
    _isDragging.value = false;
    _dragValue.value = null;
    _showThumbnail.value = false;
    _thumbnailPosition.value = null;

    // Animate back
    _thumbAnimationController.reverse();
    _scaleAnimationController.reverse();
  }

  Widget _buildTimeIndicators(Duration position, Duration duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ReelUtils.formatDuration(position),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            ReelUtils.formatDuration(duration),
            style: TextStyle(
              color: widget.config.textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}