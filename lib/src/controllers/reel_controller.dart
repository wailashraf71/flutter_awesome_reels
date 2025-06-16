import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' hide VideoFormat;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../services/cache_manager.dart';
import '../services/streaming_service.dart';
import 'dart:io';

/// Controller for managing reel playback and state with Instagram-like behavior
class ReelController extends GetxController {
  final List<ReelModel> _reels;
  late final ReelConfig _config;
  late PageController _pageController;

  final RxList<ReelModel> _reelsList = <ReelModel>[].obs;
  // Video controllers for each reel
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, DateTime> _controllerAccessTimes = {};
  final Map<String, bool> _preloadedVideos = {};
  final Set<String> _activeVideoIds = {}; // Track unique active videos
  final int _maxCachedControllers = 3;

  // Streaming service instance
  final StreamingService _streamingService = StreamingService();

  final RxInt _currentIndex = 0.obs;
  final RxBool _isInitialized = false.obs;
  final RxBool _isDisposed = false.obs;
  final RxBool _isVisible = true.obs;
  final Rx<ReelModel?> _currentReel = Rx<ReelModel?>(null);

  // State properties
  final RxBool _isMuted = false.obs;
  final RxDouble _volume = 1.0.obs;
  final RxBool _isPlaying = false.obs;
  final RxBool _isBuffering = false.obs;
  final Rx<Duration> _currentPosition = Duration.zero.obs;
  final Rx<Duration> _totalDuration = Duration.zero.obs;
  final RxnString _error = RxnString();

  // Scroll-based playing
  final RxDouble _pageScrollProgress = 0.0.obs;
  final RxBool _canPlayNext = false.obs;

  // Playtime tracking
  DateTime? _playStartTime;
  Duration _accumulatedPlayTime = Duration.zero;

  ReelController({
    required List<ReelModel> reels,
    required ReelConfig config,
  }) : _reels = reels {
    _config = config;
    _reelsList.clear();
    _reelsList.addAll(reels);
    _currentReel.value = reels.isNotEmpty ? reels[0] : null;
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_reels.isEmpty) return;

    // Initialize page controller
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
    );

    // Initialize first video
    if (_reels.isNotEmpty) {
      await _initializeCurrentVideo();
    }

    _isInitialized.value = true;
  }

  Future<void> _initializeCurrentVideo() async {
    final currentReel = _currentReel.value;
    if (currentReel == null) return;

    try {
      await initializeVideoForReel(currentReel.id);
      await _startPlayback(currentReel);
      _preloadAdjacentVideos(currentReel);
    } catch (e) {
      _error.value = 'Failed to initialize video: $e';
    }
  }

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
  double get pageScrollProgress => _pageScrollProgress.value;

  /// Additional getters for compatibility
  bool get isLoading =>
      !_isInitialized.value ||
      (_currentReel.value != null && currentVideoController == null);
  bool get hasError => _error.value != null;
  String? get errorMessage => _error.value;

  /// Get current video controller with unique instance guarantee
  VideoPlayerController? get currentVideoController {
    final reel = _currentReel.value;
    if (reel == null) return null;

    final controller = _videoControllers[reel.id];
    if (controller != null && _activeVideoIds.contains(reel.id)) {
      return controller;
    }
    return null;
  }

  /// Get video controller for specific reel
  VideoPlayerController? getVideoControllerForReel(String reelId) {
    return _videoControllers[reelId];
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

    // Initialize page controller with scroll listener
    _pageController = config.pageController ??
        PageController(initialPage: _currentIndex.value);

    // Add scroll listener for progress tracking
    _pageController.addListener(_onPageScroll);

    // Initialize cache manager if enabled
    if (config.enableCaching) {
      await CacheManager.instance.initialize();
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
      await _initializeCurrentVideo();
    }

    _isInitialized.value = true;
  }

  /// Handle page scroll for Instagram-like behavior
  void _onPageScroll() {
    if (!_pageController.hasClients) return;

    final page = _pageController.page ?? 0.0;
    final currentPageIndex = page.round();
    final scrollOffset = (page - currentPageIndex).abs();

    _pageScrollProgress.value = scrollOffset;

    // Update can play next based on scroll progress
    _canPlayNext.value = scrollOffset > 0.95; // 95% scrolled to play next video

    // Check if page changed
    if (currentPageIndex != _currentIndex.value &&
        currentPageIndex >= 0 &&
        currentPageIndex < _reels.length) {
      _onPageChanged(currentPageIndex);
    }
  }

  /// Navigate to next reel
  Future<void> nextReel() async {
    if (_currentIndex.value < _reels.length - 1 && _canPlayNext.value) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to previous reel
  Future<void> previousReel() async {
    if (_currentIndex.value > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Page change handler
  Future<void> onPageChanged(int index) async {
    await _onPageChanged(index);
  }

  /// Handle page change
  Future<void> _onPageChanged(int index) async {
    if (index == _currentIndex.value) return;

    // Pause previous video
    final previousReel = _reels[_currentIndex.value];
    final previousController = _videoControllers[previousReel.id];
    if (previousController != null && previousController.value.isInitialized) {
      await previousController.pause();
      _activeVideoIds.remove(previousReel.id);
    }

    // Update index and current reel
    _currentIndex.value = index;
    _currentReel.value = _reels[index];

    // Initialize and start new video
    if (_currentReel.value != null) {
      await _initializeCurrentVideo();
    }

    // Reset scroll progress
    _pageScrollProgress.value = 0.0;
    _canPlayNext.value = false;
  }

  /// Play current video (Instagram-like behavior)
  Future<void> play() async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      // Ensure only one video plays at a time
      await _pauseAllVideosExceptCurrent();

      await controller.play();
      _isPlaying.value = true;
      _playStartTime ??= DateTime.now();
    }
  }

  /// Pause current video
  Future<void> pause() async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
      _isPlaying.value = false;
      if (_playStartTime != null) {
        _accumulatedPlayTime += DateTime.now().difference(_playStartTime!);
        _playStartTime = null;
      }
    }
  }

  /// Pause all videos except current (unique instance guarantee)
  Future<void> _pauseAllVideosExceptCurrent() async {
    final currentReelId = _currentReel.value?.id;

    for (final entry in _videoControllers.entries) {
      if (entry.key != currentReelId && entry.value.value.isInitialized) {
        await entry.value.pause();
        _activeVideoIds.remove(entry.key);
      }
    }
  }

  /// Pause current video
  Future<void> _pauseCurrentVideo() async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
      _isPlaying.value = false;

      // Remove from active videos
      if (_currentReel.value != null) {
        _activeVideoIds.remove(_currentReel.value!.id);
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
    }
  }

  /// Initialize video for a reel
  Future<VideoPlayerController?> _initializeVideo(ReelModel reel) async {
    try {
      // Check if already initialized
      if (_videoControllers[reel.id] != null) {
        final existing = _videoControllers[reel.id]!;
        if (existing.value.isInitialized) {
          _controllerAccessTimes[reel.id] = DateTime.now();
          return existing;
        }
      }

      // Clean up old controllers if we have too many
      if (_videoControllers.length >= _maxCachedControllers) {
        await _cleanupOldControllers();
      }

      // Create video player controller
      final controller = await _streamingService.createVideoPlayerController(
        reel,
        config.videoPlayerConfig.streamingConfig,
      );

      // Add listener for state changes
      controller.addListener(() => _onVideoStateChanged(reel.id, controller));

      // Store controller
      _videoControllers[reel.id] = controller;
      _controllerAccessTimes[reel.id] = DateTime.now();
      _activeVideoIds.add(reel.id);
      _preloadedVideos[reel.id] = true;

      return controller;
    } catch (e) {
      _error.value = 'Failed to load video: $e';
      return null;
    }
  }

  /// Clean up old controllers
  Future<void> _cleanupOldControllers() async {
    if (_videoControllers.isEmpty) return;

    // Sort controllers by access time
    final sortedControllers = _controllerAccessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Keep the most recently accessed controllers
    final controllersToRemove = sortedControllers
        .take((_videoControllers.length - _maxCachedControllers + 1)
            .clamp(0, _videoControllers.length))
        .map((e) => e.key)
        .toList();

    // Dispose and remove old controllers
    for (final id in controllersToRemove) {
      final controller = _videoControllers.remove(id);
      if (controller != null) {
        await controller.dispose();
      }
      _controllerAccessTimes.remove(id);
      _activeVideoIds.remove(id);
      _preloadedVideos.remove(id);
    }
  }

  /// Initialize standard video player
  Future<VideoPlayerController?> _initializeStandardPlayer(
      ReelModel reel) async {
    try {
      // Check if already initialized
      if (_videoControllers.containsKey(reel.id)) {
        final existing = _videoControllers[reel.id]!;
        if (existing.value.isInitialized) {
          _activeVideoIds.add(reel.id);
          return existing;
        }
      }

      // Clean up old controllers if we have too many
      if (_videoControllers.length >= _maxCachedControllers) {
        final oldest = _controllerAccessTimes.entries
            .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
            .key;
        _videoControllers[oldest]?.dispose();
        _videoControllers.remove(oldest);
        _controllerAccessTimes.remove(oldest);
      }

      VideoPlayerController controller;
      final videoUrl = reel.effectiveVideoUrl;

      // Use cached file if available
      if (config.enableCaching) {
        final cachedPath =
            await CacheManager.instance.getCachedFilePath(videoUrl);
        if (cachedPath != null) {
          controller = VideoPlayerController.file(File(cachedPath));
        } else {
          controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          // Cache in background
          CacheManager.instance.downloadAndCache(videoUrl);
        }
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }

      // Initialize controller
      await controller.initialize();
      await controller.setLooping(reel.shouldLoop);
      await controller.setVolume(_isMuted.value ? 0.0 : _volume.value);

      // Add listener for state changes
      controller.addListener(() => _onVideoStateChanged(reel.id, controller));

      _videoControllers[reel.id] = controller;
      _controllerAccessTimes[reel.id] = DateTime.now();
      _activeVideoIds.add(reel.id);
      _preloadedVideos[reel.id] = true;

      return controller;
    } catch (e) {
      debugPrint('Failed to initialize standard player: $e');
      rethrow;
    }
  }

  /// Determine optimal format for the current reel
  Future<VideoFormat> _determineOptimalFormat(VideoSource videoSource) async {
    final streamingConfig = config.videoPlayerConfig.streamingConfig;

    switch (streamingConfig.preferredFormat) {
      case PreferredStreamingFormat.hls:
        return videoSource.hasFormat(VideoFormat.hls)
            ? VideoFormat.hls
            : videoSource.format;
      case PreferredStreamingFormat.dash:
        return videoSource.hasFormat(VideoFormat.dash)
            ? VideoFormat.dash
            : videoSource.format;
      case PreferredStreamingFormat.mp4:
        return videoSource.hasFormat(VideoFormat.mp4)
            ? VideoFormat.mp4
            : videoSource.format;
      case PreferredStreamingFormat.auto:
        // Auto-select based on platform and availability
        if (Platform.isIOS && videoSource.hasFormat(VideoFormat.hls)) {
          return VideoFormat.hls;
        }
        if (Platform.isAndroid && videoSource.hasFormat(VideoFormat.dash)) {
          return VideoFormat.dash;
        }
        if (videoSource.hasFormat(VideoFormat.hls)) {
          return VideoFormat.hls;
        }
        return videoSource.format;
    }
  }

  /// Handle video state changes
  void _onVideoStateChanged(String reelId, VideoPlayerController controller) {
    if (_isDisposed.value) return;

    // Update state only for current reel
    if (_currentReel.value?.id == reelId) {
      _isBuffering.value = controller.value.isBuffering;
      _currentPosition.value = controller.value.position;
      _totalDuration.value = controller.value.duration;

      // Handle errors
      if (controller.value.hasError) {
        _error.value = controller.value.errorDescription;
      } else if (_error.value != null) {
        _error.value = null;
      }
    }
  }

  /// Start playback for a reel
  Future<void> _startPlayback(ReelModel reel) async {
    final controller = _videoControllers[reel.id];
    if (controller != null && controller.value.isInitialized) {
      // Ensure unique playback
      await _pauseAllVideosExceptCurrent();

      _activeVideoIds.add(reel.id);
      await controller.play();
      _isPlaying.value = true;
      _playStartTime = DateTime.now();
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume.value = volume.clamp(0.0, 1.0);
    _isMuted.value = _volume.value == 0.0;

    // Apply to all controllers
    for (final controller in _videoControllers.values) {
      if (controller.value.isInitialized) {
        await controller.setVolume(_volume.value);
      }
    }
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted.value = !_isMuted.value;
    final volume = _isMuted.value ? 0.0 : 1.0;
    await setVolume(volume);
  }

  /// Add reel to list
  void addReel(ReelModel reel) {
    _reels.add(reel);
  }

  /// Add multiple reels
  void addReels(List<ReelModel> reels) {
    _reels.addAll(reels);
  }

  /// Remove reel
  void removeReel(String reelId) {
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index != -1) {
      _reels.removeAt(index);

      // Dispose controller if exists
      final controller = _videoControllers.remove(reelId);
      controller?.dispose();
      _preloadedVideos.remove(reelId);
      _activeVideoIds.remove(reelId);

      // Adjust current index if necessary
      if (_currentIndex.value >= _reels.length) {
        _currentIndex.value = (_reels.length - 1).clamp(0, _reels.length - 1);
      }
    }
  }

  /// Clear all reels
  void clearReels() {
    _reels.clear();
    _disposeAllControllers();
    _currentIndex.value = 0;
    _currentReel.value = null;
  }

  /// Update reel
  void updateReel(String reelId, ReelModel updatedReel) {
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index != -1) {
      _reels[index] = updatedReel;
      if (_currentReel.value?.id == reelId) {
        _currentReel.value = updatedReel;
      }
    }
  }

  /// Toggle like for a reel
  Future<void> toggleLike(String reelId) async {
    final reel = _reels.firstWhereOrNull((r) => r.id == reelId);
    if (reel != null) {
      final newLikeState = !reel.isLiked;
      final newCount = newLikeState ? reel.likesCount + 1 : reel.likesCount - 1;

      final updatedReel = reel.copyWith(
        isLiked: newLikeState,
        likesCount: newCount,
      );

      updateReel(reelId, updatedReel);
    }
  }

  /// Share reel
  Future<void> shareReel(String reelId, String shareType) async {
    final reel = _reels.firstWhereOrNull((r) => r.id == reelId);
    if (reel != null) {
      final newCount = reel.sharesCount + 1;
      final updatedReel = reel.copyWith(sharesCount: newCount);
      updateReel(reelId, updatedReel);
    }
  }

  /// Follow/unfollow user
  Future<void> toggleFollow(String userId, String reelId) async {
    final reelIndex = _reels.indexWhere((r) => r.id == reelId);
    if (reelIndex != -1) {
      final reel = _reels[reelIndex];
      if (reel.user?.id == userId) {
        final currentFollowState = reel.user?.isFollowing ?? false;
        final newFollowState = !currentFollowState;

        final updatedUser = reel.user?.copyWith(isFollowing: newFollowState);
        final updatedReel = reel.copyWith(user: updatedUser);
        updateReel(reelId, updatedReel);
      }
    }
  }

  /// Dispose all video controllers
  void _disposeAllControllers() {
    // Dispose video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();

    // Clear active videos and preloaded videos
    _activeVideoIds.clear();
    _preloadedVideos.clear();
    _controllerAccessTimes.clear();
  }

  /// Get total accumulated playtime
  Duration get totalPlayTime {
    Duration total = _accumulatedPlayTime;
    if (_playStartTime != null) {
      total += DateTime.now().difference(_playStartTime!);
    }
    return total;
  }

  /// Refresh the reels
  Future<void> refresh() async {
    // Reset and reload current reel
    final currentReel = _currentReel.value;
    if (currentReel != null) {
      await _pauseCurrentVideo();
      await _initializeVideo(currentReel);
      await _startPlayback(currentReel);
    }
  }

  /// Clear error state
  void clearError() {
    _error.value = null;
  }

  /// Retry failed operation with intelligent re-caching
  Future<void> retry() async {
    _error.value = null;
    final currentReel = _currentReel.value;
    if (currentReel != null) {
      // Clear failed cached files
      if (config.enableCaching) {
        await CacheManager.instance.removeCachedUrl(
            currentReel.videoSource?.getUrlForFormat(currentReel.videoFormat) ??
                '');
      }

      // Dispose existing controller if any
      final existingController = _videoControllers[currentReel.id];
      if (existingController != null) {
        await existingController.dispose();
        _videoControllers.remove(currentReel.id);
      }

      // Re-initialize with fresh attempt
      await _initializeVideoWithRetry(currentReel, maxRetries: 3);
      await _startPlayback(currentReel);
    }
  }

  /// Initialize video with retry logic
  Future<VideoPlayerController?> _initializeVideoWithRetry(
    ReelModel reel, {
    int maxRetries = 2,
    int currentRetry = 0,
  }) async {
    try {
      return await _initializeVideo(reel);
    } catch (e) {
      if (currentRetry < maxRetries) {
        debugPrint(
            'Video init failed (attempt ${currentRetry + 1}/$maxRetries): $e');
        await Future.delayed(Duration(milliseconds: 500 * (currentRetry + 1)));
        return await _initializeVideoWithRetry(reel,
            maxRetries: maxRetries, currentRetry: currentRetry + 1);
      } else {
        _error.value = 'Failed to load video after $maxRetries attempts';
        return null;
      }
    }
  }

  /// Follow/unfollow user
  Future<void> followUser(String userId) async {
    final currentReel = _currentReel.value;
    if (currentReel != null) {
      await toggleFollow(userId, currentReel.id);
    }
  }

  /// Increment share count
  Future<void> incrementShare(String reelId) async {
    await shareReel(reelId, 'share');
  }

  /// Block user
  Future<void> blockUser(String userId) async {
    // Implementation for blocking user
    debugPrint('User $userId blocked');
  }

  /// Download reel
  Future<void> downloadReel(ReelModel reel) async {
    // Implementation for downloading reel
    debugPrint('Downloading reel: ${reel.id}');
  }

  /// Position stream (mock implementation)
  Stream<Duration> get positionStream {
    return Stream.periodic(
        const Duration(milliseconds: 100), (_) => _currentPosition.value);
  }

  /// Was playing before seek (for progress indicator)
  bool get wasPlayingBeforeSeek => _isPlaying.value;

  @override
  void onClose() {
    _isDisposed.value = true;

    // Disable wakelock
    if (config.keepScreenAwake) {
      WakelockPlus.disable();
    }

    // Dispose video controllers
    _disposeAllControllers();

    // Dispose page controller
    if (!_pageController.hasClients) {
      _pageController.dispose();
    }

    super.onClose();
  }

  Future<void> initializeVideoForReel(String reelId) async {
    if (_isDisposed.value) return;

    final reel = _reels.firstWhere(
      (r) => r.id == reelId,
      orElse: () => throw Exception('Reel not found'),
    );

    if (_videoControllers.containsKey(reelId)) {
      _controllerAccessTimes[reelId] = DateTime.now();
      return;
    }

    // Clean up old controllers if we're at the limit
    if (_videoControllers.length >= _maxCachedControllers) {
      _cleanupOldControllers();
    }

    final controller = await _createVideoController(reel.effectiveVideoUrl);

    if (_isDisposed.value) {
      controller.dispose();
      return;
    }

    _videoControllers[reelId] = controller;
    _controllerAccessTimes[reelId] = DateTime.now();

    // Add listener for state changes
    controller.addListener(() {
      if (_isDisposed.value) return;

      if (controller.value.hasError) {
        debugPrint('Video error: ${controller.value.errorDescription}');
      }
    });

    // Preload adjacent videos
    _preloadAdjacentVideos(reel);
  }

  Future<VideoPlayerController> _createVideoController(String url) async {
    if (config.enableCaching) {
      final cachedPath = await CacheManager.instance.getCachedFilePath(url);
      if (cachedPath != null) {
        return VideoPlayerController.file(File(cachedPath));
      }
    }
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }

  void _preloadAdjacentVideos(ReelModel currentReel) {
    final preloadRange = config.preloadRange ?? 1;
    final currentIndex = _reels.indexWhere((r) => r.id == currentReel.id);

    for (var i = 1; i <= preloadRange; i++) {
      final nextIndex = currentIndex + i;
      final prevIndex = currentIndex - i;

      if (nextIndex < _reels.length) {
        initializeVideoForReel(_reels[nextIndex].id);
      }
      if (prevIndex >= 0) {
        initializeVideoForReel(_reels[prevIndex].id);
      }
    }
  }
}
