import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../services/cache_manager.dart';
import 'dart:io';

/// Controller for managing reel playback and state with Instagram-like behavior
class ReelController extends GetxController {
  late PageController _pageController;
  late ReelConfig _config;

  final RxList<ReelModel> _reels = <ReelModel>[].obs;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _preloadedVideos = {};
  final Set<String> _activeVideoIds = {}; // Track unique active videos

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

  // Scroll-based playing
  final RxDouble _pageScrollProgress = 0.0.obs;
  final RxBool _canPlayNext = false.obs;

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

    // Pause current video
    await _pauseCurrentVideo();

    // Update index and current reel
    _currentIndex.value = index;
    _currentReel.value = _reels[index];

    // Initialize and start new video
    if (_currentReel.value != null) {
      await _initializeVideo(_currentReel.value!);
      await _startPlayback(_currentReel.value!);
    }

    // Preload adjacent videos
    _preloadAdjacentVideos();

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

  /// Get video controller for specific reel (async initialization)
  Future<VideoPlayerController?> getVideoController(String reelId) async {
    if (_videoControllers.containsKey(reelId)) {
      return _videoControllers[reelId];
    }

    final reel = _reels.firstWhereOrNull((r) => r.id == reelId);
    if (reel == null) return null;

    return await _initializeVideo(reel);
  }

  /// Get video controller for a specific reel (sync)
  VideoPlayerController? getVideoControllerForReel(String reelId) {
    return _videoControllers[reelId];
  }

  /// Initialize video for a reel
  Future<VideoPlayerController?> _initializeVideo(ReelModel reel) async {
    try {
      // Clear any previous error
      _error.value = null;

      // Check if already initialized
      if (_videoControllers.containsKey(reel.id)) {
        final existing = _videoControllers[reel.id]!;
        if (existing.value.isInitialized) {
          _activeVideoIds.add(reel.id);
          return existing;
        }
      }

      VideoPlayerController controller;

      // Use cached file if available
      if (config.enableCaching) {
        final cachedPath =
            await CacheManager.instance.getCachedFilePath(reel.videoUrl);
        if (cachedPath != null) {
          controller = VideoPlayerController.file(File(cachedPath));
        } else {
          controller =
              VideoPlayerController.networkUrl(Uri.parse(reel.videoUrl));
          // Cache in background
          CacheManager.instance.downloadAndCache(reel.videoUrl);
        }
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(reel.videoUrl));
      }

      // Initialize controller
      await controller.initialize();
      await controller.setLooping(reel.shouldLoop);
      await controller.setVolume(_isMuted.value ? 0.0 : _volume.value);

      // Add listener for state changes
      controller.addListener(() => _onVideoStateChanged(reel.id, controller));

      _videoControllers[reel.id] = controller;
      _activeVideoIds.add(reel.id);
      _preloadedVideos[reel.id] = true;

      return controller;
    } catch (e) {
      _error.value = 'Failed to load video: $e';
      return null;
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

  /// Preload adjacent videos
  void _preloadAdjacentVideos() {
    final currentIdx = _currentIndex.value;
    final preloadAhead = config.preloadConfig.preloadAhead;
    final preloadBehind = config.preloadConfig.preloadBehind;

    // Preload previous videos
    for (int i =
            (currentIdx - preloadBehind).clamp(0, _reels.length - 1).round();
        i < currentIdx;
        i++) {
      final reel = _reels[i];
      if (!_preloadedVideos.containsKey(reel.id)) {
        _initializeVideo(reel);
      }
    }

    // Preload next videos
    for (int i = currentIdx + 1;
        i <= (currentIdx + preloadAhead).clamp(0, _reels.length - 1).round();
        i++) {
      final reel = _reels[i];
      if (!_preloadedVideos.containsKey(reel.id)) {
        _initializeVideo(reel);
      }
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
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _preloadedVideos.clear();
    _activeVideoIds.clear();
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
  }  /// Retry failed operation with intelligent re-caching
  Future<void> retry() async {
    _error.value = null;
    final currentReel = _currentReel.value;
    if (currentReel != null) {
      // Clear failed cached files
      if (config.enableCaching) {
        await CacheManager.instance.removeCachedUrl(currentReel.videoUrl);
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
        debugPrint('Video init failed (attempt ${currentRetry + 1}/$maxRetries): $e');
        await Future.delayed(Duration(milliseconds: 500 * (currentRetry + 1)));
        return await _initializeVideoWithRetry(reel, maxRetries: maxRetries, currentRetry: currentRetry + 1);
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
}
