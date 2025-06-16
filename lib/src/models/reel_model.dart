import 'package:flutter/foundation.dart';

/// Represents a single reel item with all its metadata

/// Enum for video streaming formats
enum VideoFormat {
  mp4,
  hls,
  dash,
}

/// Extension for VideoFormat enum
extension VideoFormatExtension on VideoFormat {
  String get name {
    switch (this) {
      case VideoFormat.mp4:
        return 'mp4';
      case VideoFormat.hls:
        return 'hls';
      case VideoFormat.dash:
        return 'dash';
    }
  }

  static VideoFormat fromString(String format) {
    switch (format.toLowerCase()) {
      case 'mp4':
        return VideoFormat.mp4;
      case 'hls':
        return VideoFormat.hls;
      case 'dash':
        return VideoFormat.dash;
      default:
        return VideoFormat.hls; // Default to HLS
    }
  }
}

/// Video source configuration for different streaming formats
class VideoSource {
  /// Primary video URL (HLS by default)
  final String url;
  
  /// Video format type
  final VideoFormat format;
  
  /// Alternative video sources for different formats
  final Map<VideoFormat, String>? alternativeSources;
  
  /// Video quality/resolution
  final String? quality;
  
  /// Bitrate in kbps
  final int? bitrate;
  
  /// Video dimensions
  final Size? dimensions;

  const VideoSource({
    required this.url,
    this.format = VideoFormat.hls,
    this.alternativeSources,
    this.quality,
    this.bitrate,
    this.dimensions,
  });

  /// Get URL for specific format
  String getUrlForFormat(VideoFormat format) {
    if (this.format == format) return url;
    return alternativeSources?[format] ?? url;
  }

  /// Check if format is available
  bool hasFormat(VideoFormat format) {
    return this.format == format || alternativeSources?.containsKey(format) == true;
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'format': format.name,
      'alternativeSources': alternativeSources?.map((k, v) => MapEntry(k.name, v)),
      'quality': quality,
      'bitrate': bitrate,
      'dimensions': dimensions != null ? {'width': dimensions!.width, 'height': dimensions!.height} : null,
    };
  }

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    return VideoSource(
      url: json['url'],
      format: VideoFormatExtension.fromString(json['format'] ?? 'hls'),
      alternativeSources: json['alternativeSources']?.map<VideoFormat, String>(
        (k, v) => MapEntry(VideoFormatExtension.fromString(k), v),
      ),
      quality: json['quality'],
      bitrate: json['bitrate'],
      dimensions: json['dimensions'] != null 
        ? Size(json['dimensions']['width'], json['dimensions']['height'])
        : null,
    );
  }

  VideoSource copyWith({
    String? url,
    VideoFormat? format,
    Map<VideoFormat, String>? alternativeSources,
    String? quality,
    int? bitrate,
    Size? dimensions,
  }) {
    return VideoSource(
      url: url ?? this.url,
      format: format ?? this.format,
      alternativeSources: alternativeSources ?? this.alternativeSources,
      quality: quality ?? this.quality,
      bitrate: bitrate ?? this.bitrate,
      dimensions: dimensions ?? this.dimensions,
    );
  }
}

class ReelModel {
  /// Unique identifier for the reel
  final String id;

  /// Video URL (can be network URL or local file path) - Deprecated, use videoSource instead
  @Deprecated('Use videoSource instead for better streaming support')
  final String? videoUrl;

  /// Video source configuration with streaming support
  final VideoSource? videoSource;

  /// Thumbnail image URL
  final String? thumbnailUrl;

  /// Video duration in milliseconds
  final Duration? duration;

  /// User information
  final ReelUser? user;

  /// Reel caption/description
  final String? caption;

  /// Number of likes
  final int likesCount;

  /// Number of comments
  final int commentsCount;

  /// Number of shares
  final int sharesCount;

  /// Whether current user has liked this reel
  final bool isLiked;

  /// Whether current user has bookmarked this reel
  final bool isBookmarked;

  /// Whether current user is following the creator
  final bool isFollowing;

  /// Custom data that can be used by the app
  final Map<String, dynamic>? customData;

  /// Audio information
  final ReelAudio? audio;

  /// Video quality/resolution
  final String? quality;

  /// Tags associated with the reel
  final List<String>? tags;

  /// Hashtags extracted from caption or manually added
  List<String> get hashtags => tags ?? [];

  /// Music title from audio info
  String? get musicTitle => audio?.title;

  /// Whether the video should loop
  final bool shouldLoop;

  /// Whether the video should autoplay
  final bool shouldAutoplay;

  final int views;
  final String? location;

  const ReelModel({
    required this.id,
    @Deprecated('Use videoSource instead for better streaming support')
    this.videoUrl,
    this.videoSource,
    this.thumbnailUrl,
    this.duration,
    this.user,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.customData,
    this.audio,
    this.quality,
    this.tags,
    this.shouldLoop = true,
    this.shouldAutoplay = true,
    this.views = 0,
    this.location,
  }) : assert(videoUrl != null || videoSource != null, 'Either videoUrl or videoSource must be provided');

  /// Constructor for HLS streaming (recommended)
  ReelModel.hls({
    required this.id,
    required String hlsUrl,
    Map<VideoFormat, String>? alternativeSources,
    this.thumbnailUrl,
    this.duration,
    this.user,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.customData,
    this.audio,
    this.quality,
    this.tags,
    this.shouldLoop = true,
    this.shouldAutoplay = true,
    this.views = 0,
    this.location,
  }) : videoUrl = null,
       videoSource = VideoSource(
         url: hlsUrl,
         format: VideoFormat.hls,
         alternativeSources: alternativeSources,
       );

  /// Constructor for DASH streaming
   ReelModel.dash({
    required this.id,
    required String dashUrl,
    Map<VideoFormat, String>? alternativeSources,
    this.thumbnailUrl,
    this.duration,
    this.user,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.customData,
    this.audio,
    this.quality,
    this.tags,
    this.shouldLoop = true,
    this.shouldAutoplay = true,
    this.views = 0,
    this.location,
  }) : videoUrl = null,
       videoSource = VideoSource(
         url: dashUrl,
         format: VideoFormat.dash,
         alternativeSources: alternativeSources,
       );

  /// Constructor for MP4 streaming
  ReelModel.mp4({
    required this.id,
    required String mp4Url,
    Map<VideoFormat, String>? alternativeSources,
    this.thumbnailUrl,
    this.duration,
    this.user,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.customData,
    this.audio,
    this.quality,
    this.tags,
    this.shouldLoop = true,
    this.shouldAutoplay = true,
    this.views = 0,
    this.location,
  }) : videoUrl = null,
       videoSource = VideoSource(
         url: mp4Url,
         format: VideoFormat.mp4,
         alternativeSources: alternativeSources,
       );

  /// Get the effective video URL (backward compatibility)
  String get effectiveVideoUrl => videoSource?.url ?? videoUrl!;

  /// Get the video format
  VideoFormat get videoFormat => videoSource?.format ?? VideoFormat.mp4;

  /// Check if streaming format is available
  bool hasStreamingFormat(VideoFormat format) {
    return videoSource?.hasFormat(format) ?? (format == VideoFormat.mp4 && videoUrl != null);
  }

  /// Get URL for specific format
  String? getUrlForFormat(VideoFormat format) {
    if (videoSource != null) {
      return videoSource!.getUrlForFormat(format);
    }
    // Fallback for legacy videoUrl
    return format == VideoFormat.mp4 ? videoUrl : null;
  }

  /// Create a copy of this reel with updated values
  ReelModel copyWith({
    String? id,
    @Deprecated('Use videoSource instead for better streaming support')
    String? videoUrl,
    VideoSource? videoSource,
    String? thumbnailUrl,
    Duration? duration,
    ReelUser? user,
    String? caption,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isBookmarked,
    bool? isFollowing,
    Map<String, dynamic>? customData,
    ReelAudio? audio,
    String? quality,
    List<String>? tags,
    bool? shouldLoop,
    bool? shouldAutoplay,
    int? views,
    String? location,
  }) {
    return ReelModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      videoSource: videoSource ?? this.videoSource,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      user: user ?? this.user,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFollowing: isFollowing ?? this.isFollowing,
      customData: customData ?? this.customData,
      audio: audio ?? this.audio,
      quality: quality ?? this.quality,
      tags: tags ?? this.tags,
      shouldLoop: shouldLoop ?? this.shouldLoop,
      shouldAutoplay: shouldAutoplay ?? this.shouldAutoplay,
      views: views ?? this.views,
      location: location ?? this.location,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl, // Keep for backward compatibility
      'videoSource': videoSource?.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'user': user?.toJson(),
      'caption': caption,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'isFollowing': isFollowing,
      'customData': customData,
      'audio': audio?.toJson(),
      'quality': quality,
      'tags': tags,
      'shouldLoop': shouldLoop,
      'shouldAutoplay': shouldAutoplay,
      'views': views,
      'location': location,
    };
  }

  /// Create from JSON
  factory ReelModel.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility
    VideoSource? videoSource;
    String? videoUrl;
    
    if (json['videoSource'] != null) {
      videoSource = VideoSource.fromJson(json['videoSource']);
    } else if (json['videoUrl'] != null) {
      // Legacy support - convert videoUrl to VideoSource
      videoUrl = json['videoUrl'];
      videoSource = VideoSource(
        url: json['videoUrl'],
        format: VideoFormat.mp4, // Default to MP4 for legacy URLs
      );
    }
    
    return ReelModel(
      id: json['id'],
      videoSource: videoSource,
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      user: json['user'] != null ? ReelUser.fromJson(json['user']) : null,
      caption: json['caption'],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      customData: json['customData'],
      audio: json['audio'] != null ? ReelAudio.fromJson(json['audio']) : null,
      quality: json['quality'],
      tags: json['tags']?.cast<String>(),
      shouldLoop: json['shouldLoop'] ?? true,
      shouldAutoplay: json['shouldAutoplay'] ?? true,
      views: json['views'] ?? 0,
      location: json['location'],
    );
  }

  @override
  String toString() {
    return 'ReelModel(id: $id, videoUrl: ${effectiveVideoUrl}, format: ${videoFormat.name}, user: ${user?.username})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReelModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents user information for a reel
class ReelUser {
  final String id;
  final String username;
  final String? displayName;
  final String? profilePictureUrl;
  final bool isVerified;
  final bool isFollowing;
  final int followersCount;
  final int followingCount;

  const ReelUser({
    required this.id,
    required this.username,
    this.displayName,
    this.profilePictureUrl,
    this.isVerified = false,
    this.isFollowing = false,
    this.followersCount = 0,
    this.followingCount = 0,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'isVerified': isVerified,
      'isFollowing': isFollowing,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  factory ReelUser.fromJson(Map<String, dynamic> json) {
    return ReelUser(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName'],
      profilePictureUrl: json['profilePictureUrl'],
      isVerified: json['isVerified'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }

  /// Create a copy of this user with updated values
  ReelUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? profilePictureUrl,
    bool? isVerified,
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
  }) {
    return ReelUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isVerified: isVerified ?? this.isVerified,
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  @override
  String toString() => 'ReelUser(id: $id, username: $username)';
}

/// Represents audio information for a reel
class ReelAudio {
  final String? title;
  final String? artist;
  final String? coverUrl;
  final String? audioUrl;
  final int? duration;

  const ReelAudio({
    this.title,
    this.artist,
    this.coverUrl,
    this.audioUrl,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'duration': duration,
    };
  }

  factory ReelAudio.fromJson(Map<String, dynamic> json) {
    return ReelAudio(
      title: json['title'],
      artist: json['artist'],
      coverUrl: json['coverUrl'],
      audioUrl: json['audioUrl'],
      duration: json['duration'],
    );
  }

  @override
  String toString() => 'ReelAudio(title: $title, artist: $artist)';
}

//Size
class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);

  @override
  String toString() => 'Size(width: $width, height: $height)';

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      json['width']?.toDouble() ?? 0.0,
      json['height']?.toDouble() ?? 0.0,
    );
  }
}

