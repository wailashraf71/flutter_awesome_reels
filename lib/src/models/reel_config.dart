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

/// Main configuration class for reels
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
  final CacheConfig? cacheConfig;

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
  final Color progressColor;

  /// Action buttons configuration
  final bool showFollowButton;
  final bool showBookmarkButton;
  final bool showDownloadButton;
  final bool showMoreButton;
  final bool showBottomControls;

  /// Button organization - move to more menu
  final bool bookmarkInMoreMenu;
  final bool downloadInMoreMenu;

  /// Follow button styling
  final Color followButtonColor;
  final Color followingButtonColor;

  /// Caption configuration
  final int maxCaptionLines;

  /// Custom actions for more menu
  final List<CustomAction> customActions;

  /// Callback functions
  final void Function(ReelModel)? onCommentTap;
  final void Function(ReelModel)? onShareTap;
  final void Function(ReelModel)? onDownloadTap;
  final void Function(String)? onHashtagTap;

  /// New fields
  final int? preloadRange;
  final bool autoPlay;
  final bool loop;
  final double volume;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final Function(Duration)? onSeek;
  final double progressBarPadding;

  const ReelConfig({
    this.backgroundColor = Colors.black,
    this.showProgressIndicator = true,
    this.progressIndicatorConfig = const ProgressIndicatorConfig(),
    this.showControlsOverlay = true,
    this.controlsAutoHideDuration = const Duration(seconds: 3),
    this.enableCaching = true,
    this.cacheConfig,
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
    this.progressColor = Colors.white,
    this.showFollowButton = true,
    this.showBookmarkButton = true,
    this.showDownloadButton = true,
    this.showMoreButton = true,
    this.showBottomControls = false,
    this.bookmarkInMoreMenu = true,
    this.downloadInMoreMenu = true,
    this.followButtonColor = Colors.white,
    this.followingButtonColor = Colors.white70,
    this.maxCaptionLines = 3,
    this.customActions = const [],
    this.onCommentTap,
    this.onShareTap,
    this.onDownloadTap,
    this.onHashtagTap,
    this.preloadRange = 1,
    this.autoPlay = true,
    this.loop = true,
    this.volume = 1.0,
    this.onPlay,
    this.onPause,
    this.onSeek,
    this.progressBarPadding = 10.0,
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
    Color? progressColor,
    bool? showFollowButton,
    bool? showBookmarkButton,
    bool? showDownloadButton,
    bool? showMoreButton,
    bool? showBottomControls,
    bool? bookmarkInMoreMenu,
    bool? downloadInMoreMenu,
    Color? followButtonColor,
    Color? followingButtonColor,
    int? maxCaptionLines,
    List<CustomAction>? customActions,
    void Function(ReelModel)? onCommentTap,
    void Function(ReelModel)? onShareTap,
    void Function(ReelModel)? onDownloadTap,
    void Function(String)? onHashtagTap,
    int? preloadRange,
    bool? autoPlay,
    bool? loop,
    double? volume,
    VoidCallback? onPlay,
    VoidCallback? onPause,
    Function(Duration)? onSeek,
    double? progressBarPadding,
  }) {
    return ReelConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showProgressIndicator:
          showProgressIndicator ?? this.showProgressIndicator,
      progressIndicatorConfig:
          progressIndicatorConfig ?? this.progressIndicatorConfig,
      showControlsOverlay: showControlsOverlay ?? this.showControlsOverlay,
      controlsAutoHideDuration:
          controlsAutoHideDuration ?? this.controlsAutoHideDuration,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheConfig: cacheConfig ?? this.cacheConfig,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      preloadConfig: preloadConfig ?? this.preloadConfig,
      errorWidgetBuilder: errorWidgetBuilder ?? this.errorWidgetBuilder,
      loadingWidgetBuilder: loadingWidgetBuilder ?? this.loadingWidgetBuilder,
      showShimmerWhileLoading:
          showShimmerWhileLoading ?? this.showShimmerWhileLoading,
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
      progressColor: progressColor ?? this.progressColor,
      showFollowButton: showFollowButton ?? this.showFollowButton,
      showBookmarkButton: showBookmarkButton ?? this.showBookmarkButton,
      showDownloadButton: showDownloadButton ?? this.showDownloadButton,
      showMoreButton: showMoreButton ?? this.showMoreButton,
      showBottomControls: showBottomControls ?? this.showBottomControls,
      bookmarkInMoreMenu: bookmarkInMoreMenu ?? this.bookmarkInMoreMenu,
      downloadInMoreMenu: downloadInMoreMenu ?? this.downloadInMoreMenu,
      followButtonColor: followButtonColor ?? this.followButtonColor,
      followingButtonColor: followingButtonColor ?? this.followingButtonColor,
      maxCaptionLines: maxCaptionLines ?? this.maxCaptionLines,
      customActions: customActions ?? this.customActions,
      onCommentTap: onCommentTap ?? this.onCommentTap,
      onShareTap: onShareTap ?? this.onShareTap,
      onDownloadTap: onDownloadTap ?? this.onDownloadTap,
      onHashtagTap: onHashtagTap ?? this.onHashtagTap,
      preloadRange: preloadRange ?? this.preloadRange,
      autoPlay: autoPlay ?? this.autoPlay,
      loop: loop ?? this.loop,
      volume: volume ?? this.volume,
      onPlay: onPlay ?? this.onPlay,
      onPause: onPause ?? this.onPause,
      onSeek: onSeek ?? this.onSeek,
      progressBarPadding: progressBarPadding ?? this.progressBarPadding,
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

/// Enum for preferred streaming format
enum PreferredStreamingFormat {
  hls,
  dash,
  mp4,
  auto, // Automatically choose best format
}

/// Extension for PreferredStreamingFormat
extension PreferredStreamingFormatExtension on PreferredStreamingFormat {
  String get name {
    switch (this) {
      case PreferredStreamingFormat.hls:
        return 'hls';
      case PreferredStreamingFormat.dash:
        return 'dash';
      case PreferredStreamingFormat.mp4:
        return 'mp4';
      case PreferredStreamingFormat.auto:
        return 'auto';
    }
  }
}

/// Configuration for streaming
class StreamingConfig {
  /// Preferred streaming format (default: HLS)
  final PreferredStreamingFormat preferredFormat;

  /// Enable adaptive bitrate streaming
  final bool enableAdaptiveBitrate;

  /// Enable low latency streaming for HLS
  final bool enableLowLatency;

  /// Maximum bitrate for streaming (in kbps)
  final int? maxBitrate;

  /// Minimum bitrate for streaming (in kbps)
  final int? minBitrate;

  /// Enable subtitle support
  final bool enableSubtitles;

  /// Enable audio track selection
  final bool enableAudioTrackSelection;

  /// Enable quality selection
  final bool enableQualitySelection;

  /// Fallback to MP4 if streaming fails
  final bool fallbackToMp4;

  /// Network timeout for streaming (in seconds)
  final int networkTimeout;

  /// Retry attempts for failed streams
  final int retryAttempts;

  /// Enable DRM support
  final bool enableDrm;

  /// DRM configuration
  final Map<String, String>? drmHeaders;

  /// Enable caching
  final bool enableCaching;

  /// Initial volume
  final double initialVolume;

  const StreamingConfig({
    this.preferredFormat = PreferredStreamingFormat.auto,
    this.enableAdaptiveBitrate = true,
    this.enableLowLatency = false,
    this.maxBitrate,
    this.minBitrate,
    this.enableSubtitles = true,
    this.enableAudioTrackSelection = true,
    this.enableQualitySelection = true,
    this.fallbackToMp4 = true,
    this.networkTimeout = 30,
    this.retryAttempts = 3,
    this.enableDrm = false,
    this.drmHeaders,
    this.enableCaching = true,
    this.initialVolume = 1.0,
  });

  StreamingConfig copyWith({
    PreferredStreamingFormat? preferredFormat,
    bool? enableAdaptiveBitrate,
    bool? enableLowLatency,
    int? maxBitrate,
    int? minBitrate,
    bool? enableSubtitles,
    bool? enableAudioTrackSelection,
    bool? enableQualitySelection,
    bool? fallbackToMp4,
    int? networkTimeout,
    int? retryAttempts,
    bool? enableDrm,
    Map<String, String>? drmHeaders,
    bool? enableCaching,
    double? initialVolume,
  }) {
    return StreamingConfig(
      preferredFormat: preferredFormat ?? this.preferredFormat,
      enableAdaptiveBitrate:
          enableAdaptiveBitrate ?? this.enableAdaptiveBitrate,
      enableLowLatency: enableLowLatency ?? this.enableLowLatency,
      maxBitrate: maxBitrate ?? this.maxBitrate,
      minBitrate: minBitrate ?? this.minBitrate,
      enableSubtitles: enableSubtitles ?? this.enableSubtitles,
      enableAudioTrackSelection:
          enableAudioTrackSelection ?? this.enableAudioTrackSelection,
      enableQualitySelection:
          enableQualitySelection ?? this.enableQualitySelection,
      fallbackToMp4: fallbackToMp4 ?? this.fallbackToMp4,
      networkTimeout: networkTimeout ?? this.networkTimeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      enableDrm: enableDrm ?? this.enableDrm,
      drmHeaders: drmHeaders ?? this.drmHeaders,
      enableCaching: enableCaching ?? this.enableCaching,
      initialVolume: initialVolume ?? this.initialVolume,
    );
  }
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

  /// Streaming configuration
  final StreamingConfig streamingConfig;

  /// Enable hardware acceleration
  final bool enableHardwareAcceleration;

  /// Enable picture-in-picture mode
  final bool enablePictureInPicture;

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
    this.streamingConfig = const StreamingConfig(),
    this.enableHardwareAcceleration = true,
    this.enablePictureInPicture = false,
  });

  VideoPlayerConfig copyWith({
    bool? showControls,
    bool? allowFullScreen,
    bool? showTitle,
    bool? showSubtitle,
    double? aspectRatio,
    BoxFit? videoFit,
    bool? startMuted,
    double? defaultVolume,
    List<double>? playbackSpeeds,
    double? defaultPlaybackSpeed,
    bool? showPlaybackSpeedControls,
    VideoBufferConfig? bufferConfig,
    StreamingConfig? streamingConfig,
    bool? enableHardwareAcceleration,
    bool? enablePictureInPicture,
  }) {
    return VideoPlayerConfig(
      showControls: showControls ?? this.showControls,
      allowFullScreen: allowFullScreen ?? this.allowFullScreen,
      showTitle: showTitle ?? this.showTitle,
      showSubtitle: showSubtitle ?? this.showSubtitle,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      videoFit: videoFit ?? this.videoFit,
      startMuted: startMuted ?? this.startMuted,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      playbackSpeeds: playbackSpeeds ?? this.playbackSpeeds,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      showPlaybackSpeedControls:
          showPlaybackSpeedControls ?? this.showPlaybackSpeedControls,
      bufferConfig: bufferConfig ?? this.bufferConfig,
      streamingConfig: streamingConfig ?? this.streamingConfig,
      enableHardwareAcceleration:
          enableHardwareAcceleration ?? this.enableHardwareAcceleration,
      enablePictureInPicture:
          enablePictureInPicture ?? this.enablePictureInPicture,
    );
  }
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
