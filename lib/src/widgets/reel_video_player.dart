import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../controllers/reel_controller.dart';
import '../services/analytics_service.dart';

/// Widget for playing reel videos with advanced features
class ReelVideoPlayer extends StatefulWidget {
  final ReelModel reel;
  final ReelController controller;
  final ReelConfig config;
  final void Function(Duration position)? onTap;
  final Widget Function(BuildContext context, ReelModel reel, String error)? errorBuilder;
  final Widget Function(BuildContext context, ReelModel reel)? loadingBuilder;

  const ReelVideoPlayer({
    Key? key,
    required this.reel,
    required this.controller,
    required this.config,
    this.onTap,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVisible = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String? _error;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.reel.id != oldWidget.reel.id) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (_isInitializing) return;
    
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      _videoController = widget.controller.getVideoController(widget.reel.id);
      
      if (_videoController != null && _videoController!.value.isInitialized) {
        _fadeController.forward();
        
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
        return;
      }

      // Wait for video to be initialized by the controller
      await Future.delayed(const Duration(milliseconds: 100));
      _videoController = widget.controller.getVideoController(widget.reel.id);
      
      if (_videoController != null && _videoController!.value.isInitialized) {
        _fadeController.forward();
      } else {
        // Video not ready yet, show loading
      }
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      
    } catch (e) {
      _error = e.toString();
      
      // Track error in analytics
      if (widget.config.enableAnalytics) {
        AnalyticsService.instance.trackVideoError(
          widget.reel.id,
          Duration.zero,
          e.toString(),
        );
      }
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
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
        onLongPress: _onVideoLongPressed,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: _buildVideoContent(),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    // Show error widget if there's an error
    if (_error != null) {
      return _buildErrorWidget();
    }

    // Show loading widget if video is not ready
    if (_videoController == null || 
        !_videoController!.value.isInitialized ||
        _isInitializing) {
      return _buildLoadingWidget();
    }

    // Show video player
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildVideoWidget(),
    );
  }

  Widget _buildVideoWidget() {
    final videoController = _videoController!;
    final videoValue = videoController.value;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        FittedBox(
          fit: widget.config.videoPlayerConfig.videoFit,
          child: SizedBox(
            width: videoValue.size.width,
            height: videoValue.size.height,
            child: VideoPlayer(videoController),
          ),
        ),
        
        // Buffering indicator
        if (videoValue.isBuffering)
          _buildBufferingIndicator(),
        
        // Play/pause overlay
        if (widget.config.showControlsOverlay)
          _buildControlsOverlay(),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, widget.reel);
    }
    
    if (widget.config.showShimmerWhileLoading) {
      return _buildShimmerLoading();
    }
    
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
  Widget _buildShimmerLoading() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          color: widget.config.accentColor,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, widget.reel, _error!);
    }
    
    if (widget.config.errorWidgetBuilder != null) {
      return widget.config.errorWidgetBuilder!(context, _error!);
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading video',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeVideo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return AnimatedOpacity(
          opacity: widget.controller.isPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Center(
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
      },
    );
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.5;
    
    if (_isVisible && !wasVisible) {
      // Video became visible
      if (_videoController != null && _videoController!.value.isInitialized) {
        widget.controller.play();
      }
    } else if (!_isVisible && wasVisible) {
      // Video became invisible
      if (_videoController != null && _videoController!.value.isInitialized) {
        widget.controller.pause();
      }
    }
  }

  void _onVideoTapped() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    
    final position = _videoController!.value.position;
    
    // Toggle play/pause
    widget.controller.togglePlayPause();
    
    // Track analytics
    if (widget.config.enableAnalytics) {
      AnalyticsService.instance.trackTap(
        widget.reel.id,
        position,
        {'action': 'video_tap'},
      );
    }
    
    // Call external callback
    if (widget.onTap != null) {
      widget.onTap!(position);
    }
  }

  void _onVideoDoubleTapped() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    
    final position = _videoController!.value.position;
    
    // Track analytics
    if (widget.config.enableAnalytics) {
      AnalyticsService.instance.trackDoubleTap(widget.reel.id, position);
    }
    
    // Could trigger like animation here
    _showLikeAnimation();
  }

  void _onVideoLongPressed() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    
    final position = _videoController!.value.position;
    
    // Track analytics
    if (widget.config.enableAnalytics) {
      AnalyticsService.instance.trackLongPress(widget.reel.id, position);
    }
    
    // Could show context menu or other actions
  }

  void _showLikeAnimation() {
    // Show a heart animation overlay
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

/// Animation overlay for like gesture
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
    );  }
}
