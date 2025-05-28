import 'package:flutter_awesome_reels/src/services/analytics_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../services/cache_manager.dart';
import 'dart:io';

/// Controller for managing reel playback and state
class ReelController extends GetxController {
  late PageController _pageController;
  late ReelConfig _config;

  final RxList<ReelModel> _reels = <ReelModel>[].obs;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _preloadedVideos = {};

  final RxInt _currentIndex = 0.obs;
  final RxBool _isInitialized = false.obs;
  final RxBool _isDisposed = false.obs;
  final Rxn<ReelModel> _currentReel = Rxn<ReelModel>();

  // State properties
  final RxBool _isMuted = false.obs;
  final RxDouble _volume = 1.0.obs;
  final RxBool _isPlaying = false.obs;
  final RxBool _isBuffering = false.obs;
  final Rx<Duration> _currentPosition = Duration.zero.obs;
  final Rx<Duration> _totalDuration = Duration.zero.obs;
  final RxnString _error = RxnString();

  // Playtime tracking
  DateTime? _playStartTime;
  Duration _accumulatedPlayTime = Duration.zero;

  // Getters
  PageController get pageController => _pageController;
  ReelConfig get config => _config;
  List<ReelModel> get reels => List.unmodifiable(_reels);
  int get currentIndex => _currentIndex.value;
  bool get isInitialized => _isInitialized.value;
  ReelModel? get currentReel => _currentReel.value;
  bool get isMuted => _isMuted.value;
  double get volume => _volume.value;
  bool get isPlaying => _isPlaying.value;
  bool get isBuffering => _isBuffering.value;
  Duration get currentPosition => _currentPosition.value;
  Duration get totalDuration => _totalDuration.value;
  String? get error => _error.value;

  /// Get current video controller
  VideoPlayerController? get currentVideoController {
    return _currentReel.value != null
        ? _videoControllers[_currentReel.value!.id]
        : null;
  }

  /// Initialize the controller
  Future<void> initialize({
    required List<ReelModel> reels,
    required ReelConfig config,
    int initialIndex = 0,
  }) async {
    if (_isInitialized.value) return;

    _config = config;
    _reels.clear();
    _reels.addAll(reels);
    _currentIndex.value = initialIndex.clamp(0, _reels.length - 1);

    // Initialize page controller
    _pageController = config.pageController ??
        PageController(initialPage: _currentIndex.value);    // Initialize cache manager if enabled
    if (config.enableCaching) {
      await CacheManager.instance.initialize(config.cacheConfig);
    }

    // Keep screen awake if configured
    if (config.keepScreenAwake) {
      WakelockPlus.enable();
    }

    // Set current reel
    if (_reels.isNotEmpty) {
      _currentReel.value = _reels[_currentIndex.value];
    }

    // Initialize current video
    if (_currentReel.value != null) {
      await _initializeVideo(_currentReel.value!);
      await _startPlayback(_currentReel.value!);
    }

    // Preload adjacent videos
    _preloadAdjacentVideos();

    _isInitialized.value = true;
  }

  /// Add new reels to the list
  void addReels(List<ReelModel> newReels) {
    _reels.addAll(newReels);
  }

  /// Insert reels at specific index
  void insertReelsAt(int index, List<ReelModel> newReels) {
    _reels.insertAll(index, newReels);

    // Adjust current index if necessary
    if (index <= _currentIndex.value) {
      _currentIndex.value += newReels.length;
    }
  }

  /// Remove reel at specific index
  void removeReelAt(int index) {
    if (index < 0 || index >= _reels.length) return;

    final reel = _reels[index];

    // Dispose video controller
    _disposeVideoController(reel.id);

    // Remove from list
    _reels.removeAt(index);

    // Adjust current index if necessary
    if (index < _currentIndex.value) {
      _currentIndex.value--;
    } else if (index == _currentIndex.value && _reels.isNotEmpty) {
      _currentIndex.value = _currentIndex.value.clamp(0, _reels.length - 1);
      _currentReel.value = _reels[_currentIndex.value];
      _initializeVideo(_currentReel.value!);
    }
  }

  /// Navigate to specific page
  Future<void> animateToPage(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (!_isInitialized.value || index < 0 || index >= _reels.length) return;

    await _pageController.animateToPage(
      index,
      duration: duration,
      curve: curve,
    );
  }

  /// Jump to specific page
  void jumpToPage(int index) {
    if (!_isInitialized.value || index < 0 || index >= _reels.length) return;

    _pageController.jumpToPage(index);
  }

  /// Handle page change
  Future<void> onPageChanged(int index) async {
    if (_isDisposed.value || index < 0 || index >= _reels.length) return;
    final previousIndex = _currentIndex.value;
    _currentIndex.value = index;
    _currentReel.value = _reels[index];
    // Reset playtime tracking for new reel
    _playStartTime = null;
    _accumulatedPlayTime = Duration.zero;

    // Stop previous video
    if (previousIndex != index && previousIndex < _reels.length) {
      await _stopPlayback(_reels[previousIndex]);
    }

    // Start new video
    await _initializeVideo(_currentReel.value!);
    await _startPlayback(_currentReel.value!);

    // Preload adjacent videos
    _preloadAdjacentVideos();

    // Load more if near end
    if (config.enableInfiniteScroll &&
        config.onLoadMore != null &&
        index >= _reels.length - config.loadMoreThreshold) {
      try {
        final newUrls = await config.onLoadMore!();
        final newReels = newUrls
            .map((url) => ReelModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  videoUrl: url,
                ))
            .toList();
        addReels(newReels);
      } catch (e) {
        debugPrint('Error loading more reels: $e');
      }
    }
  }

  /// Play current video
  Future<void> play() async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
      _isPlaying.value = true;
      // Track play start time
      _playStartTime ??= DateTime.now();
      // Track analytics
      if (config.enableAnalytics && _currentReel.value != null) {
        AnalyticsService.instance.trackVideoResumed(
          _currentReel.value!.id,
          controller.value.position,
        );
      }
    }
  }

  /// Pause current video
  Future<void> pause() async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
      _isPlaying.value = false;
      // Accumulate playtime
      if (_playStartTime != null) {
        _accumulatedPlayTime += DateTime.now().difference(_playStartTime!);
        _playStartTime = null;
      }
      // Track analytics
      if (config.enableAnalytics && _currentReel.value != null) {
        AnalyticsService.instance.trackVideoPaused(
          _currentReel.value!.id,
          controller.value.position,
        );
      }
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(position);

      // Track analytics
      if (config.enableAnalytics && _currentReel.value != null) {
        AnalyticsService.instance.trackVideoSeeked(
          _currentReel.value!.id,
          position,
          controller.value.duration,
        );
      }
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume.value = volume.clamp(0.0, 1.0);
    _isMuted.value = _volume.value == 0.0;

    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(_volume.value);
    }
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    if (_isMuted.value) {
      await setVolume(_config.videoPlayerConfig.defaultVolume);
    } else {
      await setVolume(0.0);
    }
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.setPlaybackSpeed(speed);
    }
  }

  /// Initialize video for a reel
  Future<void> _initializeVideo(ReelModel reel) async {
    if (_videoControllers.containsKey(reel.id)) return;
    try {
      _error.value = null;
      // Get video URL (from cache if available)
      String videoUrl = reel.videoUrl;
      if (config.enableCaching) {
        final cachedPath =
            await CacheManager.instance.getCachedFilePath(reel.videoUrl);
        if (cachedPath != null) {
          videoUrl = cachedPath;
        }
      }
      // Create video controller
      VideoPlayerController controller;
      if (videoUrl.startsWith('http')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else if (File(videoUrl).existsSync()) {
        controller = VideoPlayerController.file(File(videoUrl));
      } else {
        controller = VideoPlayerController.asset(videoUrl);
      }
      await controller.initialize();
      await controller.setLooping(reel.shouldLoop);
      await controller.setVolume(_isMuted.value ? 0.0 : _volume.value);
      controller.addListener(() {
        if (!_isDisposed.value && _currentReel.value?.id == reel.id) {
          _currentPosition.value = controller.value.position;
          _totalDuration.value = controller.value.duration;
          _isBuffering.value = controller.value.isBuffering;
          if (controller.value.hasError) {
            _error.value = controller.value.errorDescription;
          }
        }
      });
      _videoControllers[reel.id] = controller;
      if (config.enableAnalytics) {
        await AnalyticsService.instance.startReelSession(reel.id);
      }
      // Only keep current, previous, and next controllers
      _releaseNonAdjacentControllers();
    } catch (e) {
      _error.value = 'Failed to initialize video: $e';
      debugPrint(_error.value);
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackVideoError(
          reel.id,
          Duration.zero,
          e.toString(),
        );
      }
    }
  }

  /// Release controllers that are not current, previous, or next
  void _releaseNonAdjacentControllers() {
    final keepIds = <String>{};
    if (_currentIndex.value > 0)
      keepIds.add(_reels[_currentIndex.value - 1].id);
    keepIds.add(_reels[_currentIndex.value].id);
    if (_currentIndex.value < _reels.length - 1)
      keepIds.add(_reels[_currentIndex.value + 1].id);
    final toRemove =
        _videoControllers.keys.where((id) => !keepIds.contains(id)).toList();
    for (final id in toRemove) {
      _videoControllers[id]?.pause();
      _videoControllers[id]?.dispose();
      _videoControllers.remove(id);
    }
  }

  /// Start playback for a reel
  Future<void> _startPlayback(ReelModel reel) async {
    if (!reel.shouldAutoplay) return;

    final controller = _videoControllers[reel.id];
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
      _isPlaying.value = true;

      // Track analytics
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackVideoStarted(
          reel.id,
          Duration.zero,
        );
      }
    }
  }

  /// Stop playback for a reel
  Future<void> _stopPlayback(ReelModel reel) async {
    final controller = _videoControllers[reel.id];
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
      await controller.seekTo(Duration.zero);

      // End analytics session
      if (config.enableAnalytics) {
        await AnalyticsService.instance.endReelSession(reel.id);
      }
    }
  }

  /// Preload adjacent videos
  void _preloadAdjacentVideos() {
    final preloadConfig = config.preloadConfig;

    // Preload videos ahead
    for (int i = 1; i <= preloadConfig.preloadAhead; i++) {
      final index = _currentIndex.value + i;
      if (index < _reels.length) {
        _preloadVideo(_reels[index]);
      }
    }

    // Preload videos behind
    for (int i = 1; i <= preloadConfig.preloadBehind; i++) {
      final index = _currentIndex.value - i;
      if (index >= 0) {
        _preloadVideo(_reels[index]);
      }
    }
  }

  /// Preload a specific video
  void _preloadVideo(ReelModel reel) {
    if (_preloadedVideos[reel.id] == true ||
        _videoControllers.containsKey(reel.id)) {
      return;
    }

    _preloadedVideos[reel.id] = true;
    // Cache video if caching is enabled
    if (config.enableCaching) {
      CacheManager.instance.downloadAndCache(reel.videoUrl).catchError((e) {
        debugPrint('Error preloading video ${reel.id}: $e');
        return null;
      });
    }
  }

  /// Dispose video controller
  void _disposeVideoController(String reelId) {
    final controller = _videoControllers.remove(reelId);
    controller?.dispose();
    _preloadedVideos.remove(reelId);
  }

  /// Refresh the reels list
  Future<void> refresh() async {
    if (config.onRefresh != null) {
      try {
        await config.onRefresh!();
      } catch (e) {
        debugPrint('Error refreshing reels: $e');
      }
    }  }

  /// Get video controller for a reel (async for proper initialization)
  Future<VideoPlayerController?> getVideoController(String reelId, String videoUrl) async {
    // Check if controller already exists
    if (_videoControllers.containsKey(reelId)) {
      final controller = _videoControllers[reelId];
      if (controller != null && controller.value.isInitialized) {
        return controller;
      }
    }

    try {
      // Use cache manager if enabled
      String? cachedPath;
      if (config.enableCaching) {
        cachedPath = await CacheManager.instance.getCachedFilePath(videoUrl);
        if (cachedPath == null) {
          // Download and cache in background
          CacheManager.instance.downloadAndCache(videoUrl);
        }
      }

      // Create new controller
      final controller = cachedPath != null 
          ? VideoPlayerController.file(File(cachedPath))
          : VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      // Initialize controller
      await controller.initialize();
      
      // Set volume based on mute state
      await controller.setVolume(_isMuted.value ? 0.0 : _volume.value);

      // Store controller
      _videoControllers[reelId] = controller;
      
      // Clean up old controllers if needed
      _cleanupOldControllers();

      return controller;
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
      return null;
    }
  }

  /// Clean up old video controllers to prevent memory leaks
  void _cleanupOldControllers() {
    if (_videoControllers.length <= 3) return;

    final currentReelId = _currentReel.value?.id;
    final controllersToRemove = <String>[];

    // Keep current and adjacent controllers only
    for (final entry in _videoControllers.entries) {
      final reelId = entry.key;
      
      // Don't remove current reel controller
      if (reelId == currentReelId) continue;
      
      // Check if it's an adjacent reel
      final reelIndex = _reels.indexWhere((r) => r.id == reelId);
      final currentIndex = _currentIndex.value;
      
      if (reelIndex == -1 || 
          (reelIndex < currentIndex - 1 || reelIndex > currentIndex + 1)) {
        controllersToRemove.add(reelId);
      }
    }

    // Remove old controllers
    for (final reelId in controllersToRemove) {
      final controller = _videoControllers.remove(reelId);
      controller?.dispose();
    }
  }

  /// Check if video is initialized for a reel
  bool isVideoInitialized(String reelId) {
    final controller = _videoControllers[reelId];
    return controller?.value.isInitialized ?? false;
  }

  /// Get current playback position as percentage
  double get positionPercentage {
    if (_totalDuration.value.inMilliseconds == 0) return 0.0;
    return _currentPosition.value.inMilliseconds /
        _totalDuration.value.inMilliseconds;
  }

  /// Stream for listening to position changes
  Stream<Duration> get positionStream async* {
    while (!_isDisposed.value) {
      yield _currentPosition.value;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Check if there are any errors
  bool get hasError => _error.value != null;

  /// Get error message
  String? get errorMessage => _error.value;

  /// Check if the player is currently loading
  bool get isLoading => _isBuffering.value;

  /// Check if was playing before seek (for resuming after seek)
  bool get wasPlayingBeforeSeek => _isPlaying.value;

  /// Clear current error
  void clearError() {
    _error.value = null;
  }

  /// Retry after error
  Future<void> retry() async {
    if (_currentReel.value != null) {
      clearError();

      // Dispose current controller
      _disposeVideoController(_currentReel.value!.id);

      // Re-initialize
      await _initializeVideo(_currentReel.value!);
      await _startPlayback(_currentReel.value!);
    }
  }

  /// Toggle like for a reel
  Future<void> toggleLike(String reelId) async {
    final reelIndex = _reels.indexWhere((r) => r.id == reelId);
    if (reelIndex != -1) {
      final reel = _reels[reelIndex];
      final newLikeState = !reel.isLiked;
      final newCount = newLikeState ? reel.likesCount + 1 : reel.likesCount - 1;

      _reels[reelIndex] = reel.copyWith(
        isLiked: newLikeState,
        likesCount: newCount,
      );

      // Update current reel if it's the same
      if (_currentReel.value?.id == reelId) {
        _currentReel.value = _reels[reelIndex];
      }

      // Track analytics
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackLike(
          reelId,
          _currentPosition.value,
          newLikeState,
        );
      }
    }
  }

  /// Increment share count for a reel
  Future<void> incrementShare(String reelId) async {
    final reelIndex = _reels.indexWhere((r) => r.id == reelId);
    if (reelIndex != -1) {
      final reel = _reels[reelIndex];
      _reels[reelIndex] = reel.copyWith(
        sharesCount: reel.sharesCount + 1,
      );

      // Update current reel if it's the same
      if (_currentReel.value?.id == reelId) {
        _currentReel.value = _reels[reelIndex];
      }

      // Track analytics
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackShare(
          reelId,
          _currentPosition.value,
          'general',
        );
      }
    }
  }

  /// Toggle bookmark for a reel
  Future<void> toggleBookmark(String reelId) async {
    final reelIndex = _reels.indexWhere((r) => r.id == reelId);
    if (reelIndex != -1) {
      final reel = _reels[reelIndex];
      _reels[reelIndex] = reel.copyWith(
        isBookmarked: !reel.isBookmarked,
      );

      // Update current reel if it's the same
      if (_currentReel.value?.id == reelId) {
        _currentReel.value = _reels[reelIndex];
      }
    }
  }

  /// Follow a user
  Future<void> followUser(String userId) async {
    // Update all reels by this user
    for (int i = 0; i < _reels.length; i++) {
      final reel = _reels[i];
      if (reel.user?.id == userId) {
        _reels[i] = reel.copyWith(
          user: reel.user?.copyWith(isFollowing: true),
        );
      }
    }

    // Update current reel if it's by this user
    if (_currentReel.value?.user?.id == userId) {
      _currentReel.value = _reels[_currentIndex.value];
    }

    // Track analytics
    if (config.enableAnalytics && _currentReel.value != null) {
      AnalyticsService.instance.trackFollow(
        _currentReel.value!.id,
        _currentPosition.value,
        true,
      );
    }
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    // Remove all reels by this user
    _reels.removeWhere((reel) => reel.user?.id == userId);

    // Adjust current index if necessary
    _currentIndex.value = _currentIndex.value.clamp(0, _reels.length - 1);
    if (_reels.isNotEmpty) {
      _currentReel.value = _reels[_currentIndex.value];
      await _initializeVideo(_currentReel.value!);
      await _startPlayback(_currentReel.value!);
    }
  }

  /// Download a reel
  Future<void> downloadReel(ReelModel reel) async {
    if (config.enableCaching) {
      await CacheManager.instance.downloadAndCache(reel.videoUrl);
    }
  }

  /// Get total playtime for current reel
  Duration get currentReelPlayTime {
    if (_playStartTime != null) {
      return _accumulatedPlayTime + DateTime.now().difference(_playStartTime!);
    }
    return _accumulatedPlayTime;
  }

  @override
  void dispose() {
    if (_isDisposed.value) return;
    _isDisposed.value = true;
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    // Disable wakelock
    if (config.keepScreenAwake) {
      WakelockPlus.disable();
    }
    // Clear playtime tracking
    _playStartTime = null;
    _accumulatedPlayTime = Duration.zero;
    super.dispose();
  }
}
