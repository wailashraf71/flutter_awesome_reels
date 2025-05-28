/// Represents a single reel item with all its metadata
class ReelModel {
  /// Unique identifier for the reel
  final String id;

  /// Video URL (can be network URL or local file path)
  final String videoUrl;

  /// Thumbnail image URL
  final String? thumbnailUrl;

  /// Video duration in milliseconds
  final int? duration;

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
    required this.videoUrl,
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
  });

  /// Create a copy of this reel with updated values
  ReelModel copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
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
      'videoUrl': videoUrl,
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
    return ReelModel(
      id: json['id'],
      videoUrl: json['videoUrl'],
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
    return 'ReelModel(id: $id, videoUrl: $videoUrl, user: ${user?.username})';
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
