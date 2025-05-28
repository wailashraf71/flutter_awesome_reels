/// Analytics data model for tracking reel interactions and performance
class ReelAnalytics {
  /// Unique session ID for this analytics session
  final String sessionId;
  
  /// Reel ID being tracked
  final String reelId;
  
  /// User ID (if available)
  final String? userId;
  
  /// Device information
  final DeviceInfo deviceInfo;
  
  /// Playback events
  final List<PlaybackEvent> playbackEvents;
  
  /// Interaction events
  final List<InteractionEvent> interactionEvents;
  
  /// Performance metrics
  final PerformanceMetrics performanceMetrics;
  
  /// Session start time
  final DateTime sessionStartTime;
  
  /// Session end time
  final DateTime? sessionEndTime;

  ReelAnalytics({
    required this.sessionId,
    required this.reelId,
    this.userId,
    required this.deviceInfo,
    this.playbackEvents = const [],
    this.interactionEvents = const [],
    required this.performanceMetrics,
    required this.sessionStartTime,
    this.sessionEndTime,
  });

  /// Convert to JSON for sending to analytics service
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'reelId': reelId,
      'userId': userId,
      'deviceInfo': deviceInfo.toJson(),
      'playbackEvents': playbackEvents.map((e) => e.toJson()).toList(),
      'interactionEvents': interactionEvents.map((e) => e.toJson()).toList(),
      'performanceMetrics': performanceMetrics.toJson(),
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'sessionEndTime': sessionEndTime?.toIso8601String(),
    };
  }

  factory ReelAnalytics.fromJson(Map<String, dynamic> json) {
    return ReelAnalytics(
      sessionId: json['sessionId'],
      reelId: json['reelId'],
      userId: json['userId'],
      deviceInfo: DeviceInfo.fromJson(json['deviceInfo']),
      playbackEvents: (json['playbackEvents'] as List<dynamic>)
          .map((e) => PlaybackEvent.fromJson(e))
          .toList(),
      interactionEvents: (json['interactionEvents'] as List<dynamic>)
          .map((e) => InteractionEvent.fromJson(e))
          .toList(),
      performanceMetrics: PerformanceMetrics.fromJson(json['performanceMetrics']),
      sessionStartTime: DateTime.parse(json['sessionStartTime']),
      sessionEndTime: json['sessionEndTime'] != null 
          ? DateTime.parse(json['sessionEndTime']) 
          : null,
    );
  }

  /// Create a copy with updated values
  ReelAnalytics copyWith({
    String? sessionId,
    String? reelId,
    String? userId,
    DeviceInfo? deviceInfo,
    List<PlaybackEvent>? playbackEvents,
    List<InteractionEvent>? interactionEvents,
    PerformanceMetrics? performanceMetrics,
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
  }) {
    return ReelAnalytics(
      sessionId: sessionId ?? this.sessionId,
      reelId: reelId ?? this.reelId,
      userId: userId ?? this.userId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      playbackEvents: playbackEvents ?? this.playbackEvents,
      interactionEvents: interactionEvents ?? this.interactionEvents,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionEndTime: sessionEndTime ?? this.sessionEndTime,
    );
  }
}

/// Device information for analytics
class DeviceInfo {
  final String platform;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String? screenResolution;
  final String? networkType;
  final double? batteryLevel;

  DeviceInfo({
    required this.platform,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    this.screenResolution,
    this.networkType,
    this.batteryLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'screenResolution': screenResolution,
      'networkType': networkType,
      'batteryLevel': batteryLevel,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'],
      deviceModel: json['deviceModel'],
      osVersion: json['osVersion'],
      appVersion: json['appVersion'],
      screenResolution: json['screenResolution'],
      networkType: json['networkType'],
      batteryLevel: json['batteryLevel']?.toDouble(),
    );
  }
}

/// Playback event types
enum PlaybackEventType {
  started,
  paused,
  resumed,
  completed,
  seeked,
  buffering,
  error,
  qualityChanged,
  volumeChanged,
  speedChanged,
}

/// Playback event data
class PlaybackEvent {
  final PlaybackEventType type;
  final DateTime timestamp;
  final Duration position;
  final Duration? duration;
  final Map<String, dynamic>? metadata;

  PlaybackEvent({
    required this.type,
    required this.timestamp,
    required this.position,
    this.duration,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'position': position.inMilliseconds,
      'duration': duration?.inMilliseconds,
      'metadata': metadata,
    };
  }

  factory PlaybackEvent.fromJson(Map<String, dynamic> json) {
    return PlaybackEvent(
      type: PlaybackEventType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      position: Duration(milliseconds: json['position']),
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration']) 
          : null,
      metadata: json['metadata'],
    );
  }
}

/// Interaction event types
enum InteractionEventType {
  like,
  unlike,
  comment,
  share,
  follow,
  unfollow,
  tap,
  doubleTap,
  longPress,
  swipeUp,
  swipeDown,
  swipeLeft,
  swipeRight,
  volumeToggle,
  fullscreenEnter,
  fullscreenExit,
}

/// Interaction event data
class InteractionEvent {
  final InteractionEventType type;
  final DateTime timestamp;
  final Duration videoPosition;
  final Map<String, dynamic>? metadata;

  InteractionEvent({
    required this.type,
    required this.timestamp,
    required this.videoPosition,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'videoPosition': videoPosition.inMilliseconds,
      'metadata': metadata,
    };
  }

  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    return InteractionEvent(
      type: InteractionEventType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      videoPosition: Duration(milliseconds: json['videoPosition']),
      metadata: json['metadata'],
    );
  }
}

/// Performance metrics for the reel
class PerformanceMetrics {
  /// Time taken to start playing the video
  final Duration? timeToFirstFrame;
  
  /// Time taken to load the video
  final Duration? loadTime;
  
  /// Number of buffering events
  final int bufferingCount;
  
  /// Total buffering time
  final Duration totalBufferingTime;
  
  /// Average bitrate
  final double? averageBitrate;
  
  /// Dropped frames count
  final int droppedFrames;
  
  /// Total frames
  final int totalFrames;
  
  /// Memory usage in bytes
  final int? memoryUsage;
  
  /// CPU usage percentage
  final double? cpuUsage;
  
  /// Network usage in bytes
  final int networkUsage;
  
  /// Cache hit ratio
  final double? cacheHitRatio;

  PerformanceMetrics({
    this.timeToFirstFrame,
    this.loadTime,
    this.bufferingCount = 0,
    this.totalBufferingTime = Duration.zero,
    this.averageBitrate,
    this.droppedFrames = 0,
    this.totalFrames = 0,
    this.memoryUsage,
    this.cpuUsage,
    this.networkUsage = 0,
    this.cacheHitRatio,
  });

  Map<String, dynamic> toJson() {
    return {
      'timeToFirstFrame': timeToFirstFrame?.inMilliseconds,
      'loadTime': loadTime?.inMilliseconds,
      'bufferingCount': bufferingCount,
      'totalBufferingTime': totalBufferingTime.inMilliseconds,
      'averageBitrate': averageBitrate,
      'droppedFrames': droppedFrames,
      'totalFrames': totalFrames,
      'memoryUsage': memoryUsage,
      'cpuUsage': cpuUsage,
      'networkUsage': networkUsage,
      'cacheHitRatio': cacheHitRatio,
    };
  }

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      timeToFirstFrame: json['timeToFirstFrame'] != null 
          ? Duration(milliseconds: json['timeToFirstFrame']) 
          : null,
      loadTime: json['loadTime'] != null 
          ? Duration(milliseconds: json['loadTime']) 
          : null,
      bufferingCount: json['bufferingCount'] ?? 0,
      totalBufferingTime: Duration(milliseconds: json['totalBufferingTime'] ?? 0),
      averageBitrate: json['averageBitrate']?.toDouble(),
      droppedFrames: json['droppedFrames'] ?? 0,
      totalFrames: json['totalFrames'] ?? 0,
      memoryUsage: json['memoryUsage'],
      cpuUsage: json['cpuUsage']?.toDouble(),
      networkUsage: json['networkUsage'] ?? 0,
      cacheHitRatio: json['cacheHitRatio']?.toDouble(),
    );
  }

  PerformanceMetrics copyWith({
    Duration? timeToFirstFrame,
    Duration? loadTime,
    int? bufferingCount,
    Duration? totalBufferingTime,
    double? averageBitrate,
    int? droppedFrames,
    int? totalFrames,
    int? memoryUsage,
    double? cpuUsage,
    int? networkUsage,
    double? cacheHitRatio,
  }) {
    return PerformanceMetrics(
      timeToFirstFrame: timeToFirstFrame ?? this.timeToFirstFrame,
      loadTime: loadTime ?? this.loadTime,
      bufferingCount: bufferingCount ?? this.bufferingCount,
      totalBufferingTime: totalBufferingTime ?? this.totalBufferingTime,
      averageBitrate: averageBitrate ?? this.averageBitrate,
      droppedFrames: droppedFrames ?? this.droppedFrames,
      totalFrames: totalFrames ?? this.totalFrames,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      networkUsage: networkUsage ?? this.networkUsage,
      cacheHitRatio: cacheHitRatio ?? this.cacheHitRatio,
    );
  }

  /// Calculate frame drop rate
  double get frameDropRate {
    if (totalFrames == 0) return 0.0;
    return droppedFrames / totalFrames;
  }

  /// Check if performance is good based on metrics
  bool get isPerformanceGood {
    return frameDropRate < 0.05 && // Less than 5% frame drops
           bufferingCount < 3 && // Less than 3 buffering events
           totalBufferingTime.inSeconds < 5; // Less than 5 seconds total buffering
  }
}
