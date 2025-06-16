import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' hide VideoFormat;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';

/// Simplified controller to prevent codec overload crashes
class ReelController extends GetxController {
  List<ReelModel> _reels = [];
  late ReelConfig _config;
  PageController? _pageController;

  final RxList<ReelModel> _reelsList = <ReelModel>[].obs;

  // Keep track of active and preloaded controllers
  VideoPlayerController? _currentVideoController;
  final Map<int, VideoPlayerController?> _preloadedControllers = {};
  int _currentVideoIndex = -1;

  // Track initialization state
  final RxBool _isVideoInitializing = false.obs;
  final Map<int, bool> _initializedVideoIndices = {};

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

  // Last frame of the current video (used for smooth transitions)
  final Rx<ImageProvider?> _lastVideoFrame = Rx<ImageProvider?>(null);

  ReelController({
    List<ReelModel>? reels,
    ReelConfig? config,
  }) {
    _reels = reels ?? [];
    _config = config ?? ReelConfig();
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('ReelController initialized');
  }

  // Getters
  List<ReelModel> get reels => _reels;
  ReelConfig get config => _config;
  PageController? get pageController => _pageController;

  // Observable getters
  RxList<ReelModel> get reelsList => _reelsList;
  RxInt get currentIndex => _currentIndex;
  RxBool get isInitialized => _isInitialized;
  RxBool get isDisposed => _isDisposed;
  RxBool get isVisible => _isVisible;
  Rx<ReelModel?> get currentReel => _currentReel;
  RxBool get isMuted => _isMuted;
  RxDouble get volume => _volume;
  RxBool get isPlaying => _isPlaying;
  RxBool get isBuffering => _isBuffering;
  Rx<Duration> get currentPosition => _currentPosition;
  Rx<Duration> get totalDuration => _totalDuration;
  RxnString get error => _error;
  RxDouble get pageScrollProgress => _pageScrollProgress;
  RxBool get canPlayNext => _canPlayNext;
  bool get isVideoInitializing => _isVideoInitializing.value;
  Rx<ImageProvider?> get lastVideoFrame => _lastVideoFrame;

  /// Check if a video at a specific index is already initialized
  bool isVideoAlreadyInitialized(int index) {
    return _initializedVideoIndices.containsKey(index) &&
           _initializedVideoIndices[index] == true;
  }

  /// Get current video controller (only one at a time)
  VideoPlayerController? get currentVideoController {
    final currentIndex = _currentIndex.value;
    if (_currentVideoIndex != currentIndex) return null;
    return _currentVideoController;
  }

  /// Get video controller for specific reel
  VideoPlayerController? getVideoControllerForReel(ReelModel reel) {
    final reelIndex = _reels.indexOf(reel);
    if (reelIndex == -1) return null;

    // Return the active controller if this is the current reel
    if (_currentVideoIndex == reelIndex && _currentVideoController != null) {
      return _currentVideoController;
    }

    // Return a preloaded controller if available
    return _preloadedControllers[reelIndex];
  }

  /// Initialize the controller
  Future<void> initialize({
    List<ReelModel>? reels,
    ReelConfig? config,
    int initialIndex = 0,
  }) async {
    try {
      _error.value = null;
      _isInitialized.value = false;

      _reels = reels ?? [];
      _config = config ?? ReelConfig();

      if (_reels.isEmpty) {
        throw Exception('No reels provided');
      }

      _reelsList.value = List.from(_reels);
      _currentIndex.value = initialIndex.clamp(0, _reels.length - 1);
      _currentReel.value = _reels[_currentIndex.value];

      // Reset initialization tracking
      _initializedVideoIndices.clear();

      // Clear any preloaded controllers
      await _disposeAllControllers();

      // Initialize page controller
      _pageController = PageController(initialPage: _currentIndex.value);

      // Initialize current video
      await _initializeCurrentVideo();

      // Preload adjacent videos for smoother transitions
      _preloadAdjacentVideos(_currentIndex.value);

      _isInitialized.value = true;
      // Enable wakelock if needed
      WakelockPlus.enable();

      debugPrint('ReelController initialized with ${_reels.length} reels');
    } catch (e) {
      _error.value = e.toString();
      debugPrint('ReelController initialization error: $e');
      rethrow;
    }
  }

  /// Initialize current video
  Future<void> _initializeCurrentVideo() async {
    final currentReel = _currentReel.value;
    if (currentReel == null) return;

    final currentIndex = _currentIndex.value;

    // Check if this video is already preloaded
    if (_preloadedControllers.containsKey(currentIndex) &&
        _preloadedControllers[currentIndex] != null &&
        _preloadedControllers[currentIndex]!.value.isInitialized) {

      // Use the preloaded controller
      debugPrint('Using preloaded controller for index $currentIndex');

      // Dispose previous active controller
      if (_currentVideoController != null && _currentVideoIndex != currentIndex) {
        // Save current controller to preloaded cache before replacing
        if (_currentVideoIndex >= 0 && _currentVideoIndex < _reels.length) {
          _preloadedControllers[_currentVideoIndex] = _currentVideoController;
        } else {
          await _currentVideoController!.dispose();
        }
      }

      // Activate the preloaded controller
      _currentVideoController = _preloadedControllers[currentIndex];
      _currentVideoIndex = currentIndex;
      _initializedVideoIndices[currentIndex] = true;

      // Remove from preloaded since it's now active
      _preloadedControllers.remove(currentIndex);

      await _startPlayback(currentReel);
      return;
    }

    try {
      _isVideoInitializing.value = true;
      _error.value = null;

      // Save current controller to preloaded cache before replacing
      if (_currentVideoController != null && _currentVideoIndex != currentIndex) {
        if (_currentVideoIndex >= 0 && _currentVideoIndex < _reels.length) {
          _preloadedControllers[_currentVideoIndex] = _currentVideoController;
          _currentVideoController = null;
        } else {
          await _disposeCurrentController();
        }
      }

      // Create new controller
      final controller = await _createVideoController(currentReel);
      if (controller != null) {
        _currentVideoController = controller;
        _currentVideoIndex = currentIndex;
        _initializedVideoIndices[currentIndex] = true;

        await _startPlayback(currentReel);
      }
    } catch (e) {
      _error.value = e.toString();
      debugPrint('Error initializing current video: $e');
    } finally {
      _isVideoInitializing.value = false;
    }
  }

  /// Preload adjacent videos for smoother transitions
  Future<void> _preloadAdjacentVideos(int currentIndex) async {
    // Preload next video if available
    if (currentIndex < _reels.length - 1) {
      final nextIndex = currentIndex + 1;
      _preloadVideo(nextIndex);
    }

    // Preload previous video if available
    if (currentIndex > 0) {
      final prevIndex = currentIndex - 1;
      _preloadVideo(prevIndex);
    }
  }

  /// Dispose all controllers (active and preloaded)
  Future<void> _disposeAllControllers() async {
    // Dispose active controller
    await _disposeCurrentController();

    // Dispose all preloaded controllers
    for (final controller in _preloadedControllers.values) {
      if (controller != null) {
        try {
          await controller.pause();
          await controller.dispose();
        } catch (e) {
          debugPrint('Error disposing preloaded controller: $e');
        }
      }
    }

    _preloadedControllers.clear();
  }

  /// Dispose current video controller
  Future<void> _disposeCurrentController() async {
    if (_currentVideoController != null) {
      try {
        await _currentVideoController!.pause();
        await _currentVideoController!.dispose();
      } catch (e) {
        debugPrint('Error disposing video controller: $e');
      } finally {
        _currentVideoController = null;
        _currentVideoIndex = -1;
      }
    }
  }

  /// Create video controller
  Future<VideoPlayerController?> _createVideoController(ReelModel reel) async {
    try {
      final videoSource = reel.videoSource;
      final videoUrl = reel.videoUrl;

      VideoPlayerController controller;

      if (videoSource != null) {
        final url = videoSource.getUrlForFormat(VideoFormat.mp4);
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else if (videoUrl != null) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        throw Exception('No video source available');
      }

      await controller.initialize();
      await controller.setLooping(reel.shouldLoop);
      await controller.setVolume(_isMuted.value ? 0.0 : _volume.value);

      return controller;
    } catch (e) {
      debugPrint('Error creating video controller: $e');
      return null;
    }
  }

  /// Start playback for current reel
  Future<void> _startPlayback(ReelModel reel) async {
    if (_currentVideoController == null) return;

    try {
      if (_config.autoPlay && _isVisible.value) {
        await _currentVideoController!.play();
        _isPlaying.value = true;
        _playStartTime = DateTime.now();
      }

      // Setup listeners
      _currentVideoController!.addListener(_onVideoControllerUpdate);
    } catch (e) {
      debugPrint('Error starting playback: $e');
    }
  }

  /// Video controller update listener
  void _onVideoControllerUpdate() {
    if (_currentVideoController == null) return;

    final controller = _currentVideoController!;
    _currentPosition.value = controller.value.position;
    _totalDuration.value = controller.value.duration;
    _isBuffering.value = controller.value.isBuffering;

    if (controller.value.hasError) {
      _error.value = controller.value.errorDescription;
    }
  }

  /// Navigate to next reel
  Future<void> nextPage() async {
    if (_pageController == null || _currentIndex.value >= _reels.length - 1)
      return;
    await _pageController!.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Navigate to previous reel
  Future<void> previousPage() async {
    if (_pageController == null || _currentIndex.value <= 0) return;
    await _pageController!.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Handle page change
  Future<void> onPageChanged(int index) async {
    if (index == _currentIndex.value) return;

    _currentIndex.value = index;
    _currentReel.value = _reels[index];

    // Switch to the new video immediately - either preloaded or initialize new
    await _initializeCurrentVideo();

    // Preload adjacent videos for smooth future transitions
    _preloadAdjacentVideos(index);
  }

  /// Preload a video at a specific index without making it active
  Future<void> _preloadVideo(int index) async {
    if (index < 0 || index >= _reels.length ||
        isVideoAlreadyInitialized(index) ||
        _preloadedControllers.containsKey(index)) {
      return;
    }

    try {
      debugPrint('Preloading video at index $index');
      final reel = _reels[index];
      final controller = await _createVideoController(reel);

      if (controller != null) {
        _preloadedControllers[index] = controller;
        _initializedVideoIndices[index] = true;
        debugPrint('Successfully preloaded video at index $index');
      }
    } catch (e) {
      debugPrint('Error preloading video at index $index: $e');
    }
  }

  /// Play current video
  Future<void> play() async {
    if (_currentVideoController == null) return;

    try {
      await _currentVideoController!.play();
      _isPlaying.value = true;
      _playStartTime = DateTime.now();
    } catch (e) {
      debugPrint('Error playing video: $e');
    }
  }

  /// Pause current video
  Future<void> pause() async {
    if (_currentVideoController == null) return;

    try {
      await _currentVideoController!.pause();
      _isPlaying.value = false;
      _updateAccumulatedPlayTime();
    } catch (e) {
      debugPrint('Error pausing video: $e');
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

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    if (_currentVideoController == null) return;

    try {
      await _currentVideoController!.seekTo(position);
    } catch (e) {
      debugPrint('Error seeking video: $e');
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume.value = volume.clamp(0.0, 1.0);

    if (_currentVideoController != null) {
      await _currentVideoController!
          .setVolume(_isMuted.value ? 0.0 : _volume.value);
    }
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted.value = !_isMuted.value;

    if (_currentVideoController != null) {
      await _currentVideoController!
          .setVolume(_isMuted.value ? 0.0 : _volume.value);
    }
  }

  /// Set visibility
  void setVisibility(bool visible) {
    _isVisible.value = visible;

    if (!visible) {
      pause();
    } else if (_config.autoPlay) {
      play();
    }
  }

  /// Set app visibility (simplified)
  void setAppVisibility(bool visible) {
    setVisibility(visible);
  }

  /// Check if a specific reel is currently active
  bool isReelActive(ReelModel reel) {
    final reelIndex = _reels.indexOf(reel);
    return reelIndex != -1 && _currentVideoIndex == reelIndex;
  }

  /// Initialize video for specific reel (index-based)
  Future<void> initializeVideoForReel(ReelModel reel) async {
    final reelIndex = _reels.indexOf(reel);
    if (reelIndex == -1) {
      debugPrint('Reel not found in list');
      return;
    }

    if (_currentIndex.value != reelIndex) {
      _currentIndex.value = reelIndex;
      _currentReel.value = reel;
      await _initializeCurrentVideo();
    }
  }

  /// Toggle like (no-op implementation)
  void toggleLike([ReelModel? reel]) {
    // Simplified - no like functionality
    debugPrint('Like toggled');
  }

  /// Increment share (no-op implementation)
  void incrementShare([ReelModel? reel]) {
    // Simplified - no share functionality
    debugPrint('Share incremented');
  }

  /// Download reel (no-op implementation)
  void downloadReel([ReelModel? reel]) {
    // Simplified - no download functionality
    debugPrint('Download requested');
  }

  /// Block user (no-op implementation)
  void blockUser([String? userId]) {
    // Simplified - no block functionality
    debugPrint('User blocked');
  }

  /// Follow user (no-op implementation)
  void followUser([String? userId]) {
    // Simplified - no follow functionality
    debugPrint('User followed');
  }

  /// Clear error
  void clearError() {
    _error.value = null;
  }

  /// Retry
  Future<void> retry() async {
    await retryCurrentVideo();
  }

  /// Retry current video initialization
  Future<void> retryCurrentVideo() async {
    final currentReel = _currentReel.value;
    if (currentReel != null) {
      clearError();
      // Remove from initialized tracking to force a fresh init
      _initializedVideoIndices.remove(_currentIndex.value);
      await _initializeCurrentVideo();
    }
  }

  /// Check if has error
  bool get hasError => _error.value != null;

  /// Get error message
  String? get errorMessage => _error.value;

  /// Get position stream (simplified)
  Stream<Duration> get positionStream => _currentPosition.stream;
  /// Was playing before seek
  bool get wasPlayingBeforeSeek => _isPlaying.value;

  /// Refresh (no-op)
  void refresh() {
    debugPrint('Refresh called');
  }

  /// Update accumulated play time
  void _updateAccumulatedPlayTime() {
    if (_playStartTime != null) {
      _accumulatedPlayTime += DateTime.now().difference(_playStartTime!);
      _playStartTime = null;
    }
  }

  /// Get accumulated play time for current reel
  Duration getAccumulatedPlayTime() {
    Duration total = _accumulatedPlayTime;
    if (_playStartTime != null && _isPlaying.value) {
      total += DateTime.now().difference(_playStartTime!);
    }
    return total;
  }

  @override
  void onClose() {
    dispose();
    super.onClose();
  }

  /// Dispose controller
  @override
  void dispose() {
    if (_isDisposed.value) return;

    _isDisposed.value = true;
    _updateAccumulatedPlayTime();

    // Dispose all controllers
    _disposeAllControllers();

    // Dispose page controller
    _pageController?.dispose();
    _pageController = null;

    // Disable wakelock
    WakelockPlus.disable();

    debugPrint('ReelController disposed');

    super.dispose();
  }
}
