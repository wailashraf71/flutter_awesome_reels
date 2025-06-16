import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/reel_model.dart';

class ReelService {
  static final ReelService _instance = ReelService._internal();
  factory ReelService() => _instance;
  ReelService._internal();

  final _cache = <String, ReelModel>{};
  final _loadingStates = <String, bool>{};
  final _errorStates = <String, String>{};

  Future<List<ReelModel>> fetchReels({int page = 1, int limit = 10}) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data - In production, replace with actual API call
      final reels = _getMockReels(page, limit);

      // Cache the results
      for (final reel in reels) {
        _cache[reel.id] = reel;
      }

      return reels;
    } catch (e) {
      debugPrint('Error fetching reels: $e');
      rethrow;
    }
  }

  Future<ReelModel?> fetchReelById(String id) async {
    if (_cache.containsKey(id)) {
      return _cache[id];
    }

    try {
      _loadingStates[id] = true;
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Mock data - In production, replace with actual API call
      final reel = _getMockReel(id);
      if (reel != null) {
        _cache[id] = reel;
      }

      return reel;
    } catch (e) {
      _errorStates[id] = e.toString();
      rethrow;
    } finally {
      _loadingStates[id] = false;
    }
  }

  bool isLoading(String id) => _loadingStates[id] ?? false;
  String? getError(String id) => _errorStates[id];
  void clearError(String id) => _errorStates.remove(id);

  // Mock data methods
  List<ReelModel> _getMockReels(int page, int limit) {
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    return List.generate(
      limit,
      (index) => ReelModel(
        id: 'reel_${startIndex + index}',
        videoSource: VideoSource(
          url: _getMockVideoUrl(startIndex + index),
        ),
        user: ReelUser(
          id: 'user_${startIndex + index}',
          username: 'user${startIndex + index}',
          displayName: 'User ${startIndex + index}',
          isFollowing: index % 2 == 0,
        ),
        likesCount: 100 + index * 10,
        commentsCount: 20 + index * 5,
        sharesCount: 5 + index * 2,
        tags: ['tag${index + 1}', 'tag${index + 2}'],
        audio: ReelAudio(title: 'Audio ${startIndex + index}'),
        duration: Duration(seconds: 15 + (index % 5) * 5),
        isLiked: index % 3 == 0,
        views: 1000 + index * 100,
        location: 'Location ${startIndex + index}',
      ),
    );
  }

  ReelModel? _getMockReel(String id) {
    final index = int.tryParse(id.split('_').last) ?? 0;
    return ReelModel(
      id: id,
      videoSource: VideoSource(
        url: _getMockVideoUrl(index),
      ),
      user: ReelUser(
        id: 'user_$index',
        username: 'user$index',
        displayName: 'User $index',
        isFollowing: index % 2 == 0,
      ),
      likesCount: 100 + index * 10,
      commentsCount: 20 + index * 5,
      sharesCount: 5 + index * 2,
      tags: ['tag${index + 1}', 'tag${index + 2}'],
      audio: ReelAudio(title: 'Audio $index'),
      duration: Duration(seconds: 15 + (index % 5) * 5),
      isLiked: index % 3 == 0,
      views: 1000 + index * 100,
      location: 'Location $index',
    );
  }

  String _getMockVideoUrl(int index) {
    // Return different video URLs for variety
    final urls = [
      'https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd',
      'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      'https://moctobpltc-i.akamaihd.net/hls/live/571329/eight/playlist.m3u8',
      'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
    ];
    return urls[index % urls.length];
  }
}
