import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/reel_analytics.dart';

/// Service for collecting and reporting analytics data
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance =>
      _instance ??= AnalyticsService._internal();

  AnalyticsService._internal();

  bool _isEnabled = false;
  DeviceInfo? _deviceInfo;
  final Map<String, ReelAnalytics> _activeAnalytics = {};
  final List<ReelAnalytics> _pendingAnalytics = [];

  /// Callback for sending analytics data to external service
  Future<void> Function(ReelAnalytics analytics)? onAnalyticsReported;

  /// Callback for batch sending analytics data
  Future<void> Function(List<ReelAnalytics> analytics)?
      onBatchAnalyticsReported;

  /// Initialize the analytics service
  Future<void> initialize({
    bool enabled = true,
    Future<void> Function(ReelAnalytics analytics)? onAnalyticsReported,
    Future<void> Function(List<ReelAnalytics> analytics)?
        onBatchAnalyticsReported,
  }) async {
    _isEnabled = enabled;
    if (!_isEnabled) return;

    this.onAnalyticsReported = onAnalyticsReported;
    this.onBatchAnalyticsReported = onBatchAnalyticsReported;

    // Collect device information
    await _collectDeviceInfo();
  }

  /// Start tracking a reel session
  Future<void> startReelSession(String reelId, {String? userId}) async {
    if (!_isEnabled) return;

    final sessionId = _generateSessionId();
    final analytics = ReelAnalytics(
      sessionId: sessionId,
      reelId: reelId,
      userId: userId,
      deviceInfo: _deviceInfo!,
      performanceMetrics: PerformanceMetrics(),
      sessionStartTime: DateTime.now(),
    );

    _activeAnalytics[reelId] = analytics;
  }

  /// End tracking a reel session
  Future<void> endReelSession(String reelId) async {
    if (!_isEnabled) return;

    final analytics = _activeAnalytics.remove(reelId);
    if (analytics != null) {
      final updatedAnalytics = analytics.copyWith(
        sessionEndTime: DateTime.now(),
      );

      _pendingAnalytics.add(updatedAnalytics);

      // Report immediately if callback is provided
      if (onAnalyticsReported != null) {
        try {
          await onAnalyticsReported!(updatedAnalytics);
        } catch (e) {
          debugPrint('Error reporting analytics: $e');
        }
      }
    }
  }

  /// Track a playback event
  void trackPlaybackEvent(
    String reelId,
    PlaybackEventType type,
    Duration position, {
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    final analytics = _activeAnalytics[reelId];
    if (analytics != null) {
      final event = PlaybackEvent(
        type: type,
        timestamp: DateTime.now(),
        position: position,
        duration: duration,
        metadata: metadata,
      );

      final updatedEvents = List<PlaybackEvent>.from(analytics.playbackEvents)
        ..add(event);

      _activeAnalytics[reelId] = analytics.copyWith(
        playbackEvents: updatedEvents,
      );
    }
  }

  /// Track an interaction event
  void trackInteractionEvent(
    String reelId,
    InteractionEventType type,
    Duration videoPosition, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    final analytics = _activeAnalytics[reelId];
    if (analytics != null) {
      final event = InteractionEvent(
        type: type,
        timestamp: DateTime.now(),
        videoPosition: videoPosition,
        metadata: metadata,
      );

      final updatedEvents =
          List<InteractionEvent>.from(analytics.interactionEvents)..add(event);

      _activeAnalytics[reelId] = analytics.copyWith(
        interactionEvents: updatedEvents,
      );
    }
  }

  /// Update performance metrics
  void updatePerformanceMetrics(
    String reelId,
    PerformanceMetrics metrics,
  ) {
    if (!_isEnabled) return;

    final analytics = _activeAnalytics[reelId];
    if (analytics != null) {
      _activeAnalytics[reelId] = analytics.copyWith(
        performanceMetrics: metrics,
      );
    }
  }

  /// Track video started
  void trackVideoStarted(String reelId, Duration position) {
    trackPlaybackEvent(reelId, PlaybackEventType.started, position);
  }

  /// Track video paused
  void trackVideoPaused(String reelId, Duration position) {
    trackPlaybackEvent(reelId, PlaybackEventType.paused, position);
  }

  /// Track video resumed
  void trackVideoResumed(String reelId, Duration position) {
    trackPlaybackEvent(reelId, PlaybackEventType.resumed, position);
  }

  /// Track video completed
  void trackVideoCompleted(String reelId, Duration position) {
    trackPlaybackEvent(reelId, PlaybackEventType.completed, position);
  }

  /// Track video seeked
  void trackVideoSeeked(String reelId, Duration position, Duration? duration) {
    trackPlaybackEvent(reelId, PlaybackEventType.seeked, position,
        duration: duration);
  }

  /// Track buffering started
  void trackBufferingStarted(String reelId, Duration position) {
    trackPlaybackEvent(reelId, PlaybackEventType.buffering, position);
  }

  /// Track video error
  void trackVideoError(String reelId, Duration position, String error) {
    trackPlaybackEvent(
      reelId,
      PlaybackEventType.error,
      position,
      metadata: {'error': error},
    );
  }

  /// Track like action
  void trackLike(String reelId, Duration videoPosition, bool isLiked) {
    trackInteractionEvent(
      reelId,
      isLiked ? InteractionEventType.like : InteractionEventType.unlike,
      videoPosition,
      metadata: {'isLiked': isLiked},
    );
  }

  /// Track comment action
  void trackComment(String reelId, Duration videoPosition, String comment) {
    trackInteractionEvent(
      reelId,
      InteractionEventType.comment,
      videoPosition,
      metadata: {'comment': comment},
    );
  }

  /// Track share action
  void trackShare(String reelId, Duration videoPosition, String shareType) {
    trackInteractionEvent(
      reelId,
      InteractionEventType.share,
      videoPosition,
      metadata: {'shareType': shareType},
    );
  }

  /// Track follow action
  void trackFollow(String reelId, Duration videoPosition, bool isFollowing) {
    trackInteractionEvent(
      reelId,
      isFollowing ? InteractionEventType.follow : InteractionEventType.unfollow,
      videoPosition,
      metadata: {'isFollowing': isFollowing},
    );
  }

  /// Track tap gesture
  void trackTap(
      String reelId, Duration videoPosition, Map<String, dynamic>? metadata) {
    trackInteractionEvent(reelId, InteractionEventType.tap, videoPosition,
        metadata: metadata);
  }

  /// Track double tap gesture
  void trackDoubleTap(String reelId, Duration videoPosition) {
    trackInteractionEvent(
        reelId, InteractionEventType.doubleTap, videoPosition);
  }

  /// Track long press gesture
  void trackLongPress(String reelId, Duration videoPosition) {
    trackInteractionEvent(
        reelId, InteractionEventType.longPress, videoPosition);
  }

  /// Track swipe gestures
  void trackSwipe(String reelId, Duration videoPosition, String direction) {
    InteractionEventType eventType;
    switch (direction.toLowerCase()) {
      case 'up':
        eventType = InteractionEventType.swipeUp;
        break;
      case 'down':
        eventType = InteractionEventType.swipeDown;
        break;
      case 'left':
        eventType = InteractionEventType.swipeLeft;
        break;
      case 'right':
        eventType = InteractionEventType.swipeRight;
        break;
      default:
        return;
    }

    trackInteractionEvent(reelId, eventType, videoPosition,
        metadata: {'direction': direction});
  }

  /// Get current analytics for a reel
  ReelAnalytics? getReelAnalytics(String reelId) {
    return _activeAnalytics[reelId];
  }

  /// Get all pending analytics
  List<ReelAnalytics> getPendingAnalytics() {
    return List.from(_pendingAnalytics);
  }

  /// Clear pending analytics
  void clearPendingAnalytics() {
    _pendingAnalytics.clear();
  }

  /// Send batch analytics
  Future<void> sendBatchAnalytics() async {
    if (!_isEnabled || _pendingAnalytics.isEmpty) return;

    if (onBatchAnalyticsReported != null) {
      try {
        await onBatchAnalyticsReported!(_pendingAnalytics);
        _pendingAnalytics.clear();
      } catch (e) {
        debugPrint('Error sending batch analytics: $e');
      }
    }
  }

  /// Get analytics summary for a reel
  AnalyticsSummary getAnalyticsSummary(String reelId) {
    final analytics = _activeAnalytics[reelId];
    if (analytics == null) {
      return AnalyticsSummary.empty();
    }

    final playbackEvents = analytics.playbackEvents;
    final interactionEvents = analytics.interactionEvents;
    final performance = analytics.performanceMetrics;

    // Calculate metrics
    final totalPlayTime = _calculateTotalPlayTime(playbackEvents);
    final watchPercentage = _calculateWatchPercentage(playbackEvents);
    final interactionRate =
        _calculateInteractionRate(interactionEvents, totalPlayTime);
    final bufferingEvents = playbackEvents
        .where((e) => e.type == PlaybackEventType.buffering)
        .length;

    return AnalyticsSummary(
      totalPlayTime: totalPlayTime,
      watchPercentage: watchPercentage,
      interactionRate: interactionRate,
      bufferingEvents: bufferingEvents,
      performanceScore: _calculatePerformanceScore(performance),
      likesCount: interactionEvents
          .where((e) => e.type == InteractionEventType.like)
          .length,
      commentsCount: interactionEvents
          .where((e) => e.type == InteractionEventType.comment)
          .length,
      sharesCount: interactionEvents
          .where((e) => e.type == InteractionEventType.share)
          .length,
    );
  }

  /// Collect device information
  Future<void> _collectDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String platform;
      String? deviceModel;
      String? osVersion;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = 'Android';
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = 'iOS';
        deviceModel = iosInfo.model;
        osVersion = iosInfo.systemVersion;
      } else {
        platform = Platform.operatingSystem;
        deviceModel = null;
        osVersion = null;
      }

      _deviceInfo = DeviceInfo(
        platform: platform,
        deviceModel: deviceModel,
        osVersion: osVersion,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        screenResolution: null, // Can be set from MediaQuery if needed
        networkType: null, // Can be detected using connectivity_plus
        batteryLevel: null, // Can be detected using battery_plus
      );
    } catch (e) {
      debugPrint('Error collecting device info: $e');
      _deviceInfo = DeviceInfo(platform: Platform.operatingSystem);
    }
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'session_$random';
  }

  /// Calculate total play time from events
  Duration _calculateTotalPlayTime(List<PlaybackEvent> events) {
    Duration totalTime = Duration.zero;
    DateTime? playStartTime;

    for (final event in events) {
      switch (event.type) {
        case PlaybackEventType.started:
        case PlaybackEventType.resumed:
          playStartTime = event.timestamp;
          break;
        case PlaybackEventType.paused:
        case PlaybackEventType.completed:
          if (playStartTime != null) {
            totalTime += event.timestamp.difference(playStartTime);
            playStartTime = null;
          }
          break;
        default:
          break;
      }
    }

    // If still playing, add time until now
    if (playStartTime != null) {
      totalTime += DateTime.now().difference(playStartTime);
    }

    return totalTime;
  }

  /// Calculate watch percentage
  double _calculateWatchPercentage(List<PlaybackEvent> events) {
    final completedEvents =
        events.where((e) => e.type == PlaybackEventType.completed);
    if (completedEvents.isNotEmpty) return 100.0;

    // Find the furthest position reached
    Duration maxPosition = Duration.zero;
    for (final event in events) {
      if (event.position > maxPosition) {
        maxPosition = event.position;
      }
    }

    // Calculate percentage based on video duration (if available)
    final durationEvents = events.where((e) => e.duration != null);
    if (durationEvents.isNotEmpty) {
      final duration = durationEvents.first.duration!;
      return (maxPosition.inMilliseconds / duration.inMilliseconds * 100)
          .clamp(0.0, 100.0);
    }

    return 0.0;
  }

  /// Calculate interaction rate (interactions per minute of play time)
  double _calculateInteractionRate(
      List<InteractionEvent> interactions, Duration playTime) {
    if (playTime.inSeconds == 0) return 0.0;
    return interactions.length /
        (playTime.inMinutes > 0 ? playTime.inMinutes : 1.0);
  }

  /// Calculate performance score (0-100)
  double _calculatePerformanceScore(PerformanceMetrics metrics) {
    double score = 100.0;

    // Penalize for frame drops
    if (metrics.totalFrames > 0) {
      final frameDropRate = metrics.droppedFrames / metrics.totalFrames;
      score -= frameDropRate * 30; // Max 30 points deduction
    }

    // Penalize for buffering
    score -= metrics.bufferingCount * 5; // 5 points per buffering event
    score -= metrics.totalBufferingTime.inSeconds * 2; // 2 points per second

    // Penalize for slow load time
    if (metrics.loadTime != null) {
      final loadTimeSeconds = metrics.loadTime!.inSeconds;
      if (loadTimeSeconds > 5) {
        score -= (loadTimeSeconds - 5) * 3; // 3 points per second over 5s
      }
    }

    return score.clamp(0.0, 100.0);
  }

  /// Enable or disable analytics
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _activeAnalytics.clear();
      _pendingAnalytics.clear();
    }
  }

  /// Check if analytics is enabled
  bool get isEnabled => _isEnabled;
}

/// Analytics summary for a reel session
class AnalyticsSummary {
  final Duration totalPlayTime;
  final double watchPercentage;
  final double interactionRate;
  final int bufferingEvents;
  final double performanceScore;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  const AnalyticsSummary({
    required this.totalPlayTime,
    required this.watchPercentage,
    required this.interactionRate,
    required this.bufferingEvents,
    required this.performanceScore,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
  });

  factory AnalyticsSummary.empty() {
    return const AnalyticsSummary(
      totalPlayTime: Duration.zero,
      watchPercentage: 0.0,
      interactionRate: 0.0,
      bufferingEvents: 0,
      performanceScore: 0.0,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPlayTime': totalPlayTime.inMilliseconds,
      'watchPercentage': watchPercentage,
      'interactionRate': interactionRate,
      'bufferingEvents': bufferingEvents,
      'performanceScore': performanceScore,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
    };
  }

  @override
  String toString() {
    return 'AnalyticsSummary(playTime: ${totalPlayTime.inSeconds}s, watch: ${watchPercentage.toStringAsFixed(1)}%, interactions: ${interactionRate.toStringAsFixed(1)}/min, performance: ${performanceScore.toStringAsFixed(1)})';
  }
}
