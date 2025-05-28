import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../services/cache_manager.dart';
import '../services/analytics_service.dart';

/// Controller for managing reel playback and state
class ReelController extends ChangeNotifier {
  late PageController _pageController;
  late ReelConfig _config;
  
  final List<ReelModel> _reels = [];
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _preloadedVideos = {};
  
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isDisposed = false;
  ReelModel? _currentReel;
  
  // State properties
  bool _isMuted = false;
  double _volume = 1.0;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _error;

  // Getters
  PageController get pageController => _pageController;
  ReelConfig get config => _config;
  List<ReelModel> get reels => List.unmodifiable(_reels);
  int get currentIndex => _currentIndex;
  bool get isInitialized => _isInitialized;
  ReelModel? get currentReel => _currentReel;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get error => _error;
  
  /// Get current video controller
  VideoPlayerController? get currentVideoController {
    return _currentReel != null ? _videoControllers[_currentReel!.id] : null;
  }

  /// Initialize the controller
  Future<void> initialize({
    required List<ReelModel> reels,
    required ReelConfig config,
    int initialIndex = 0,
  }) async {
    if (_isInitialized) return;
    
    _config = config;
    _reels.clear();
    _reels.addAll(reels);
    _currentIndex = initialIndex.clamp(0, _reels.length - 1);
    
    // Initialize page controller
    _pageController = config.pageController ?? 
        PageController(initialPage: _currentIndex);
    
    // Initialize cache manager if enabled
    if (config.enableCaching) {
      await CacheManager.instance.initialize(config.cacheConfig);
    }
    
    // Initialize analytics if enabled
    if (config.enableAnalytics) {
      await AnalyticsService.instance.initialize(enabled: true);
    }
    
    // Keep screen awake if configured
    if (config.keepScreenAwake) {
      WakelockPlus.enable();
    }
    
    // Set current reel
    if (_reels.isNotEmpty) {
      _currentReel = _reels[_currentIndex];
    }
    
    // Initialize current video
    if (_currentReel != null) {
      await _initializeVideo(_currentReel!);
      await _startPlayback(_currentReel!);
    }
    
    // Preload adjacent videos
    _preloadAdjacentVideos();
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Add new reels to the list
  void addReels(List<ReelModel> newReels) {
    _reels.addAll(newReels);
    notifyListeners();
  }

  /// Insert reels at specific index
  void insertReelsAt(int index, List<ReelModel> newReels) {
    _reels.insertAll(index, newReels);
    
    // Adjust current index if necessary
    if (index <= _currentIndex) {
      _currentIndex += newReels.length;
    }
    
    notifyListeners();
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
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _reels.isNotEmpty) {
      _currentIndex = _currentIndex.clamp(0, _reels.length - 1);
      _currentReel = _reels[_currentIndex];
      _initializeVideo(_currentReel!);
    }
    
    notifyListeners();
  }

  /// Navigate to specific page
  Future<void> animateToPage(int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (!_isInitialized || index < 0 || index >= _reels.length) return;
    
    await _pageController.animateToPage(
      index,
      duration: duration,
      curve: curve,
    );
  }

  /// Jump to specific page
  void jumpToPage(int index) {
    if (!_isInitialized || index < 0 || index >= _reels.length) return;
    
    _pageController.jumpToPage(index);
  }

  /// Handle page change
  Future<void> onPageChanged(int index) async {
    if (_isDisposed || index < 0 || index >= _reels.length) return;
    
    final previousIndex = _currentIndex;
    _currentIndex = index;
    _currentReel = _reels[index];
    
    // Stop previous video
    if (previousIndex != index && previousIndex < _reels.length) {
      await _stopPlayback(_reels[previousIndex]);
    }
    
    // Start new video
    await _initializeVideo(_currentReel!);
    await _startPlayback(_currentReel!);
    
    // Preload adjacent videos
    _preloadAdjacentVideos();
    
    // Load more if near end
    if (config.enableInfiniteScroll && 
        config.onLoadMore != null && 
        index >= _reels.length - config.loadMoreThreshold) {
      try {
        final newUrls = await config.onLoadMore!();
        final newReels = newUrls.map((url) => ReelModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          videoUrl: url,
        )).toList();
        addReels(newReels);
      } catch (e) {
        debugPrint('Error loading more reels: $e');
      }
    }
    
    notifyListeners();
  }

  /// Play current video
  Future<void> play() async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
      _isPlaying = true;
      
      // Track analytics
      if (config.enableAnalytics && _currentReel != null) {
        AnalyticsService.instance.trackVideoResumed(
          _currentReel!.id,
          controller.value.position,
        );
      }
      
      notifyListeners();
    }
  }

  /// Pause current video
  Future<void> pause() async {
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
      _isPlaying = false;
      
      // Track analytics
      if (config.enableAnalytics && _currentReel != null) {
        AnalyticsService.instance.trackVideoPaused(
          _currentReel!.id,
          controller.value.position,
        );
      }
      
      notifyListeners();
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
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
      if (config.enableAnalytics && _currentReel != null) {
        AnalyticsService.instance.trackVideoSeeked(
          _currentReel!.id,
          position,
          controller.value.duration,
        );
      }
      
      notifyListeners();
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    _isMuted = _volume == 0.0;
    
    final controller = currentVideoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(_volume);
    }
    
    notifyListeners();
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    if (_isMuted) {
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
      notifyListeners();
    }
  }

  /// Initialize video for a reel
  Future<void> _initializeVideo(ReelModel reel) async {
    if (_videoControllers.containsKey(reel.id)) return;
    
    try {
      _error = null;
      
      // Get video URL (from cache if available)
      String videoUrl = reel.videoUrl;
      if (config.enableCaching) {
        final cachedPath = await CacheManager.instance.getCachedFilePath(reel.videoUrl);
        if (cachedPath != null) {
          videoUrl = cachedPath;
        }
      }
      
      // Create video controller
      VideoPlayerController controller;
      if (videoUrl.startsWith('http')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        controller = VideoPlayerController.asset(videoUrl);
      }
      
      // Initialize controller
      await controller.initialize();
      
      // Configure controller
      await controller.setLooping(reel.shouldLoop);
      await controller.setVolume(_isMuted ? 0.0 : _volume);
      
      // Add listener for position updates
      controller.addListener(() {
        if (!_isDisposed && _currentReel?.id == reel.id) {
          _currentPosition = controller.value.position;
          _totalDuration = controller.value.duration;
          _isBuffering = controller.value.isBuffering;
          
          if (controller.value.hasError) {
            _error = controller.value.errorDescription;
          }
          
          notifyListeners();
        }
      });
      
      _videoControllers[reel.id] = controller;
      
      // Start analytics session
      if (config.enableAnalytics) {
        await AnalyticsService.instance.startReelSession(reel.id);
      }
      
    } catch (e) {
      _error = 'Failed to initialize video: $e';
      debugPrint(_error);
      
      // Track error in analytics
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackVideoError(
          reel.id,
          Duration.zero,
          e.toString(),
        );
      }
      
      notifyListeners();
    }
  }

  /// Start playback for a reel
  Future<void> _startPlayback(ReelModel reel) async {
    if (!reel.shouldAutoplay) return;
    
    final controller = _videoControllers[reel.id];
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
      _isPlaying = true;
      
      // Track analytics
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackVideoStarted(
          reel.id,
          Duration.zero,
        );
      }
      
      notifyListeners();
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
      final index = _currentIndex + i;
      if (index < _reels.length) {
        _preloadVideo(_reels[index]);
      }
    }
    
    // Preload videos behind
    for (int i = 1; i <= preloadConfig.preloadBehind; i++) {
      final index = _currentIndex - i;
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
    }
  }

  /// Get video controller for a specific reel
  VideoPlayerController? getVideoController(String reelId) {
    return _videoControllers[reelId];
  }

  /// Check if video is initialized for a reel
  bool isVideoInitialized(String reelId) {
    final controller = _videoControllers[reelId];
    return controller?.value.isInitialized ?? false;
  }
  /// Get current playback position as percentage
  double get positionPercentage {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  /// Stream for listening to position changes
  Stream<Duration> get positionStream async* {
    while (!_isDisposed) {
      yield _currentPosition;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Check if there are any errors
  bool get hasError => _error != null;

  /// Get error message
  String? get errorMessage => _error;

  /// Check if the player is currently loading
  bool get isLoading => _isBuffering;

  /// Check if was playing before seek (for resuming after seek)
  bool get wasPlayingBeforeSeek => _isPlaying;

  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Retry after error
  Future<void> retry() async {
    if (_currentReel != null) {
      clearError();
      
      // Dispose current controller
      _disposeVideoController(_currentReel!.id);
      
      // Re-initialize
      await _initializeVideo(_currentReel!);
      await _startPlayback(_currentReel!);
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
      if (_currentReel?.id == reelId) {
        _currentReel = _reels[reelIndex];
      }
      
      // Track analytics
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackLike(
          reelId,
          _currentPosition,
          newLikeState,
        );
      }
      
      notifyListeners();
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
      if (_currentReel?.id == reelId) {
        _currentReel = _reels[reelIndex];
      }
      
      // Track analytics
      if (config.enableAnalytics) {
        AnalyticsService.instance.trackShare(
          reelId,
          _currentPosition,
          'general',
        );
      }
      
      notifyListeners();
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
      if (_currentReel?.id == reelId) {
        _currentReel = _reels[reelIndex];
      }
      
      notifyListeners();
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
    if (_currentReel?.user?.id == userId) {
      _currentReel = _reels[_currentIndex];
    }
    
    // Track analytics
    if (config.enableAnalytics && _currentReel != null) {
      AnalyticsService.instance.trackFollow(
        _currentReel!.id,
        _currentPosition,
        true,
      );
    }
    
    notifyListeners();
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    // Remove all reels by this user
    _reels.removeWhere((reel) => reel.user?.id == userId);
    
    // Adjust current index if necessary
    _currentIndex = _currentIndex.clamp(0, _reels.length - 1);
    if (_reels.isNotEmpty) {
      _currentReel = _reels[_currentIndex];
      await _initializeVideo(_currentReel!);
      await _startPlayback(_currentReel!);
    }
    
    notifyListeners();
  }

  /// Download a reel
  Future<void> downloadReel(ReelModel reel) async {
    if (config.enableCaching) {
      await CacheManager.instance.downloadAndCache(reel.videoUrl);
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    
    // Disable wakelock
    if (config.keepScreenAwake) {
      WakelockPlus.disable();
    }
    
    super.dispose();
  }
}
