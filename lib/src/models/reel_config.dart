import 'package:flutter/material.dart';
import 'reel_model.dart';

/// Custom action for the more menu
class CustomAction {
  final IconData icon;
  final String title;
  final void Function(ReelModel) onTap;

  const CustomAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

/// Configuration class for customizing the AwesomeReels widget
class ReelConfig {
  /// Background color for the reels container
  final Color backgroundColor;
  
  /// Whether to show the progress indicator
  final bool showProgressIndicator;
  
  /// Progress indicator configuration
  final ProgressIndicatorConfig progressIndicatorConfig;
  
  /// Whether to show video controls overlay
  final bool showControlsOverlay;
  
  /// Auto-hide controls after this duration (null means never hide)
  final Duration? controlsAutoHideDuration;
  
  /// Whether to enable caching
  final bool enableCaching;
  
  /// Cache configuration
  final CacheConfig cacheConfig;
  
  /// Whether to enable analytics
  final bool enableAnalytics;
  
  /// Preload configuration
  final PreloadConfig preloadConfig;
  
  /// Error widget builder
  final Widget Function(BuildContext context, String error)? errorWidgetBuilder;
  
  /// Loading widget builder
  final Widget Function(BuildContext context)? loadingWidgetBuilder;
  
  /// Whether to show shimmer effect while loading
  final bool showShimmerWhileLoading;
  
  /// Custom shimmer configuration
  final ShimmerConfig? shimmerConfig;
  
  /// Physics for the PageView
  final ScrollPhysics? physics;
  
  /// Page controller for the reels
  final PageController? pageController;
  
  /// Whether to enable pull to refresh
  final bool enablePullToRefresh;
  
  /// Pull to refresh callback
  final Future<void> Function()? onRefresh;
  
  /// Whether to enable infinite scroll
  final bool enableInfiniteScroll;
  
  /// Infinite scroll callback (load more reels)
  final Future<List<String>> Function()? onLoadMore;
  
  /// Threshold for triggering load more (from the end)
  final int loadMoreThreshold;
  
  /// Whether to keep screen awake while playing videos
  final bool keepScreenAwake;
    /// Video player configuration
  final VideoPlayerConfig videoPlayerConfig;
  
  /// UI Colors and styling
  final Color accentColor;
  final Color textColor;
  
  /// Action buttons configuration
  final bool showFollowButton;
  final bool showBookmarkButton;
  final bool showDownloadButton;
  final bool showMoreButton;
  final bool showBottomControls;
  
  /// Caption configuration
  final int maxCaptionLines;
  
  /// Custom actions for more menu
  final List<CustomAction> customActions;
  
  /// Callback functions
  final void Function(ReelModel)? onCommentTap;
  final void Function(ReelModel)? onShareTap;
  final void Function(ReelModel)? onDownloadTap;
  final void Function(String)? onHashtagTap;
  const ReelConfig({
    this.backgroundColor = Colors.black,
    this.showProgressIndicator = true,
    this.progressIndicatorConfig = const ProgressIndicatorConfig(),
    this.showControlsOverlay = true,
    this.controlsAutoHideDuration = const Duration(seconds: 3),
    this.enableCaching = true,
    this.cacheConfig = const CacheConfig(),
    this.enableAnalytics = false,
    this.preloadConfig = const PreloadConfig(),
    this.errorWidgetBuilder,
    this.loadingWidgetBuilder,
    this.showShimmerWhileLoading = true,
    this.shimmerConfig,
    this.physics,
    this.pageController,
    this.enablePullToRefresh = false,
    this.onRefresh,
    this.enableInfiniteScroll = false,
    this.onLoadMore,
    this.loadMoreThreshold = 3,
    this.keepScreenAwake = true,
    this.videoPlayerConfig = const VideoPlayerConfig(),
    this.accentColor = Colors.red,
    this.textColor = Colors.white,
    this.showFollowButton = true,
    this.showBookmarkButton = true,
    this.showDownloadButton = true,
    this.showMoreButton = true,
    this.showBottomControls = false,
    this.maxCaptionLines = 3,
    this.customActions = const [],
    this.onCommentTap,
    this.onShareTap,
    this.onDownloadTap,
    this.onHashtagTap,
  });
  ReelConfig copyWith({
    Color? backgroundColor,
    bool? showProgressIndicator,
    ProgressIndicatorConfig? progressIndicatorConfig,
    bool? showControlsOverlay,
    Duration? controlsAutoHideDuration,
    bool? enableCaching,
    CacheConfig? cacheConfig,
    bool? enableAnalytics,
    PreloadConfig? preloadConfig,
    Widget Function(BuildContext context, String error)? errorWidgetBuilder,
    Widget Function(BuildContext context)? loadingWidgetBuilder,
    bool? showShimmerWhileLoading,
    ShimmerConfig? shimmerConfig,
    ScrollPhysics? physics,
    PageController? pageController,
    bool? enablePullToRefresh,
    Future<void> Function()? onRefresh,
    bool? enableInfiniteScroll,
    Future<List<String>> Function()? onLoadMore,
    int? loadMoreThreshold,
    bool? keepScreenAwake,
    VideoPlayerConfig? videoPlayerConfig,
    Color? accentColor,
    Color? textColor,
    bool? showFollowButton,
    bool? showBookmarkButton,
    bool? showDownloadButton,
    bool? showMoreButton,
    bool? showBottomControls,
    int? maxCaptionLines,
    List<CustomAction>? customActions,
    void Function(ReelModel)? onCommentTap,
    void Function(ReelModel)? onShareTap,
    void Function(ReelModel)? onDownloadTap,
    void Function(String)? onHashtagTap,
  }) {
    return ReelConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showProgressIndicator: showProgressIndicator ?? this.showProgressIndicator,
      progressIndicatorConfig: progressIndicatorConfig ?? this.progressIndicatorConfig,
      showControlsOverlay: showControlsOverlay ?? this.showControlsOverlay,
      controlsAutoHideDuration: controlsAutoHideDuration ?? this.controlsAutoHideDuration,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheConfig: cacheConfig ?? this.cacheConfig,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      preloadConfig: preloadConfig ?? this.preloadConfig,
      errorWidgetBuilder: errorWidgetBuilder ?? this.errorWidgetBuilder,
      loadingWidgetBuilder: loadingWidgetBuilder ?? this.loadingWidgetBuilder,
      showShimmerWhileLoading: showShimmerWhileLoading ?? this.showShimmerWhileLoading,
      shimmerConfig: shimmerConfig ?? this.shimmerConfig,
      physics: physics ?? this.physics,
      pageController: pageController ?? this.pageController,
      enablePullToRefresh: enablePullToRefresh ?? this.enablePullToRefresh,
      onRefresh: onRefresh ?? this.onRefresh,
      enableInfiniteScroll: enableInfiniteScroll ?? this.enableInfiniteScroll,
      onLoadMore: onLoadMore ?? this.onLoadMore,
      loadMoreThreshold: loadMoreThreshold ?? this.loadMoreThreshold,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      videoPlayerConfig: videoPlayerConfig ?? this.videoPlayerConfig,
      accentColor: accentColor ?? this.accentColor,
      textColor: textColor ?? this.textColor,
      showFollowButton: showFollowButton ?? this.showFollowButton,
      showBookmarkButton: showBookmarkButton ?? this.showBookmarkButton,
      showDownloadButton: showDownloadButton ?? this.showDownloadButton,
      showMoreButton: showMoreButton ?? this.showMoreButton,
      showBottomControls: showBottomControls ?? this.showBottomControls,
      maxCaptionLines: maxCaptionLines ?? this.maxCaptionLines,
      customActions: customActions ?? this.customActions,
      onCommentTap: onCommentTap ?? this.onCommentTap,
      onShareTap: onShareTap ?? this.onShareTap,
      onDownloadTap: onDownloadTap ?? this.onDownloadTap,
      onHashtagTap: onHashtagTap ?? this.onHashtagTap,
    );
  }
}

/// Configuration for the progress indicator
class ProgressIndicatorConfig {
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final EdgeInsets margin;
  final bool showTimeLabels;
  final TextStyle? timeLabelStyle;

  const ProgressIndicatorConfig({
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white24,
    this.height = 2.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.showTimeLabels = false,
    this.timeLabelStyle,
  });
}

/// Configuration for caching
class CacheConfig {
  /// Maximum cache size in bytes (default: 100MB)
  final int maxCacheSize;
  
  /// Cache duration (default: 7 days)
  final Duration cacheDuration;
  
  /// Number of videos to preload (default: 2)
  final int preloadCount;
  
  /// Whether to cache thumbnails
  final bool cacheThumbnails;
  
  /// Custom cache directory name
  final String? cacheDirectoryName;

  const CacheConfig({
    this.maxCacheSize = 100 * 1024 * 1024, // 100MB
    this.cacheDuration = const Duration(days: 7),
    this.preloadCount = 2,
    this.cacheThumbnails = true,
    this.cacheDirectoryName,
  });
}

/// Configuration for preloading
class PreloadConfig {
  /// Number of videos to preload ahead
  final int preloadAhead;
  
  /// Number of videos to preload behind
  final int preloadBehind;
  
  /// Whether to preload on WiFi only
  final bool preloadOnWiFiOnly;
  
  /// Maximum videos to keep preloaded
  final int maxPreloaded;

  const PreloadConfig({
    this.preloadAhead = 2,
    this.preloadBehind = 1,
    this.preloadOnWiFiOnly = false,
    this.maxPreloaded = 5,
  });
}

/// Configuration for shimmer effect
class ShimmerConfig {
  final Color baseColor;
  final Color highlightColor;
  final Duration period;
  final ShimmerDirection direction;

  const ShimmerConfig({
    this.baseColor = const Color(0xFF1A1A1A),
    this.highlightColor = const Color(0xFF3A3A3A),
    this.period = const Duration(milliseconds: 1500),
    this.direction = ShimmerDirection.ltr,
  });
}

/// Shimmer animation direction
enum ShimmerDirection {
  ltr,
  rtl,
  ttb,
  btt,
}

/// Configuration for video player
class VideoPlayerConfig {
  /// Whether to show video controls
  final bool showControls;
  
  /// Whether to allow fullscreen
  final bool allowFullScreen;
  
  /// Whether to show video title
  final bool showTitle;
  
  /// Whether to show subtitle
  final bool showSubtitle;
  
  /// Aspect ratio for the video player
  final double? aspectRatio;
  
  /// Video fit mode
  final BoxFit videoFit;
  
  /// Whether to start video muted
  final bool startMuted;
  
  /// Default volume (0.0 to 1.0)
  final double defaultVolume;
  
  /// Video playback speed options
  final List<double> playbackSpeeds;
  
  /// Default playback speed
  final double defaultPlaybackSpeed;
  
  /// Whether to show playback speed controls
  final bool showPlaybackSpeedControls;
  
  /// Buffer configuration
  final VideoBufferConfig bufferConfig;

  const VideoPlayerConfig({
    this.showControls = false,
    this.allowFullScreen = false,
    this.showTitle = false,
    this.showSubtitle = false,
    this.aspectRatio,
    this.videoFit = BoxFit.cover,
    this.startMuted = false,
    this.defaultVolume = 1.0,
    this.playbackSpeeds = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
    this.defaultPlaybackSpeed = 1.0,
    this.showPlaybackSpeedControls = false,
    this.bufferConfig = const VideoBufferConfig(),
  });
}

/// Configuration for video buffering
class VideoBufferConfig {
  /// Minimum buffer duration
  final Duration minBufferDuration;
  
  /// Maximum buffer duration
  final Duration maxBufferDuration;
  
  /// Buffer duration for rebuffering
  final Duration bufferForPlaybackDuration;
  
  /// Buffer duration after rebuffering
  final Duration bufferForPlaybackAfterRebufferDuration;

  const VideoBufferConfig({
    this.minBufferDuration = const Duration(seconds: 15),
    this.maxBufferDuration = const Duration(seconds: 50),
    this.bufferForPlaybackDuration = const Duration(milliseconds: 2500),
    this.bufferForPlaybackAfterRebufferDuration = const Duration(seconds: 5),
  });
}
