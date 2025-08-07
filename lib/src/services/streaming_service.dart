import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' hide VideoFormat;

import '../models/reel_config.dart';
import '../models/reel_model.dart';
import '../services/cache_manager.dart';

/// Service for handling advanced video streaming with HLS, DASH, and MP4 support
class StreamingService {
  static final StreamingService _instance = StreamingService._internal();

  factory StreamingService() => _instance;

  StreamingService._internal();

  static StreamingService get instance => _instance;

  /// Create a video player controller for streaming
  Future<VideoPlayerController> createVideoPlayerController(
    ReelModel reel,
    StreamingConfig config,
  ) async {
    try {
      final videoSource = reel.videoSource;
      if (videoSource == null) {
        throw Exception('No video source provided');
      }

      // Determine optimal format
      final format = await _determineOptimalFormat(videoSource, config);
      final url = videoSource.getUrlForFormat(format);

      // Check cache first
      if (config.enableCaching) {
        final cachedPath = CacheManager.instance.getCachedFilePath(url);
        if (cachedPath != null) {
          final controller = VideoPlayerController.file(File(cachedPath));
          await _initializeController(controller, reel, config);
          return controller;
        }
      }

      // Create controller based on format
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: config.drmHeaders ?? {},
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Initialize controller
      await _initializeController(controller, reel, config);

      // Cache in background if enabled
      if (config.enableCaching) {
        Future.microtask(() => CacheManager.instance.downloadAndCache(url));
      }

      return controller;
    } catch (e) {
      debugPrint('Error creating video controller: $e');
      rethrow;
    }
  }

  Future<void> _initializeController(
    VideoPlayerController controller,
    ReelModel reel,
    StreamingConfig config,
  ) async {
    await controller.initialize();
    await controller.setLooping(reel.shouldLoop);
    await controller.setVolume(config.initialVolume);

    if (config.enableAdaptiveBitrate) {
      await controller.setPlaybackSpeed(1.0);
    }
  }

  Future<VideoFormat> _determineOptimalFormat(
    VideoSource videoSource,
    StreamingConfig config,
  ) async {
    // First check preferred format
    switch (config.preferredFormat) {
      case PreferredStreamingFormat.hls:
        if (videoSource.hasFormat(VideoFormat.hls)) {
          return VideoFormat.hls;
        }
        break;
      case PreferredStreamingFormat.dash:
        if (videoSource.hasFormat(VideoFormat.dash)) {
          return VideoFormat.dash;
        }
        break;
      case PreferredStreamingFormat.mp4:
        if (videoSource.hasFormat(VideoFormat.mp4)) {
          return VideoFormat.mp4;
        }
        break;
      case PreferredStreamingFormat.auto:
        // Auto-select based on platform and network conditions
        final isLowBandwidth = await _isLowBandwidth();
        final isMobile = await _isMobileNetwork();

        if (isLowBandwidth || isMobile) {
          // Prefer MP4 for low bandwidth or mobile networks
          if (videoSource.hasFormat(VideoFormat.mp4)) {
            return VideoFormat.mp4;
          }
        } else {
          // Prefer adaptive formats for good bandwidth
          if (Platform.isIOS && videoSource.hasFormat(VideoFormat.hls)) {
            return VideoFormat.hls;
          }
          if (Platform.isAndroid && videoSource.hasFormat(VideoFormat.dash)) {
            return VideoFormat.dash;
          }
        }
        break;
    }

    // Fallback to available formats in order of preference
    if (videoSource.hasFormat(VideoFormat.hls)) {
      return VideoFormat.hls;
    }
    if (videoSource.hasFormat(VideoFormat.dash)) {
      return VideoFormat.dash;
    }
    if (videoSource.hasFormat(VideoFormat.mp4)) {
      return VideoFormat.mp4;
    }

    // Return default format if nothing else is available
    return videoSource.format;
  }

  Future<bool> _isLowBandwidth() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isEmpty;
    } catch (e) {
      return true;
    }
  }

  Future<bool> _isMobileNetwork() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return connectivityResults.contains(ConnectivityResult.mobile);
    } catch (e) {
      return false;
    }
  }

  /// Check if streaming format is supported on current platform
  bool isFormatSupported(VideoFormat format) {
    switch (format) {
      case VideoFormat.hls:
        return Platform.isIOS || Platform.isAndroid;
      case VideoFormat.dash:
        return Platform.isAndroid; // DASH is primarily supported on Android
      case VideoFormat.mp4:
        return true; // MP4 is universally supported
    }
  }

  /// Get recommended formats for current platform
  List<VideoFormat> getRecommendedFormats() {
    if (Platform.isIOS) {
      return [VideoFormat.hls, VideoFormat.mp4];
    } else if (Platform.isAndroid) {
      return [VideoFormat.hls, VideoFormat.dash, VideoFormat.mp4];
    } else {
      return [VideoFormat.mp4];
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
