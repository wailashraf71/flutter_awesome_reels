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
  final Widget Function(BuildContext context, ReelModel reel, String error)?
      errorBuilder;
  final Widget Function(BuildContext context, ReelModel reel)? loadingBuilder;

  const ReelVideoPlayer({
    super.key,
    required this.reel,
    required this.controller,
    required this.config,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  final RxBool _isVisible = false.obs;
  // Unused fields removed to satisfy lints
  bool _isInitialized = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Ensure we react to controller page changes by listening to current index
    ever<int>(widget.controller.currentIndex, (idx) {
      // If this reel is not the active one, make sure it is not playing
      if (!widget.controller.isReelActive(widget.reel)) {
        final vc = widget.controller.getVideoControllerForReel(widget.reel);
        if (vc != null) {
          try {
            vc.pause();
          } catch (_) {}
        }
      }
    });
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
        _isFirstLoad = false;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize video for reel: $e');
      _isInitialized =
          true; // Mark as initialized even on error to prevent infinite retry
      _isFirstLoad = false;
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
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Obx(() {
      // Get controller using the new approach
      VideoPlayerController? controller =
          widget.controller.getVideoControllerForReel(widget.reel);

      // Get reel index to check if it's already initialized
      final reelIndex = widget.controller.reels.indexOf(widget.reel);
      final isAlreadyInitialized = reelIndex != -1 &&
          widget.controller.isVideoAlreadyInitialized(reelIndex);

      // Only show initializing on first load, not for switching between videos
      if (widget.controller.isVideoInitializing &&
          _isFirstLoad &&
          !isAlreadyInitialized) {
        return _buildInitializingWidget();
      }

      // Show loading if no controller or not initialized, but only on first load
      if ((controller == null || !controller.value.isInitialized) &&
          _isFirstLoad) {
        // Skip showing "loading" if we're just switching to an already initialized video
        if (isAlreadyInitialized) {
          return Container(color: Colors.black);
        }
        return _buildLoadingWidget();
      }

      // If the controller exists but isn't initialized and we're not on first load,
      // show a black screen instead of loading (for smooth transitions)
      if ((controller == null || !controller.value.isInitialized) &&
          !_isFirstLoad) {
        return Container(color: Colors.black);
      }

      // Check for errors
      if (controller != null && controller.value.hasError) {
        return _buildErrorWidget(
            controller.value.errorDescription ?? 'Unknown error');
      }

      // If we have a controller and it's initialized, show the video
      if (controller != null && controller.value.isInitialized) {
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
      }

      // Fallback - show black screen
      return Container(color: Colors.black);
    });
  }

  Widget _buildInitializingWidget() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, widget.reel);
    }

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

  Widget _buildLoadingWidget() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, widget.reel);
    }

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
                setState(() {
                  _isInitialized = false;
                  _isFirstLoad = true;
                });
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

  void _onVisibilityChanged(VisibilityInfo info) {
    final wasVisible = _isVisible.value;
    _isVisible.value = info.visibleFraction > 0.5;

    if (_isVisible.value && !wasVisible) {
      _initializeVideo();
      final isCurrent = widget.controller.isReelActive(widget.reel);
      if (isCurrent) {
        widget.controller.play();
      }
    } else if (!_isVisible.value && wasVisible) {
      // When this reel goes off-screen, pause its controller if it's playing
      final vc = widget.controller.getVideoControllerForReel(widget.reel);
      if (vc != null) {
        try {
          vc.pause();
        } catch (_) {}
      }
    }
  }
}
