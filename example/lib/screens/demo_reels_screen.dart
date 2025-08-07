import 'package:flutter/material.dart';
import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';

class DemoReelsScreen extends StatefulWidget {
  final List<ReelModel>? reels;
  final String title;
  final ReelConfig? config;

  const DemoReelsScreen({
    super.key,
    this.reels,
    required this.title,
    this.config,
  });

  @override
  State<DemoReelsScreen> createState() => _DemoReelsScreenState();
}

class _DemoReelsScreenState extends State<DemoReelsScreen> {
  late final ReelController _controller;
  List<ReelModel> _reels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = ReelController();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      // Use provided reels or create sample data
      _reels = widget.reels ?? SampleData.basicReels;

      if (_reels.isNotEmpty) {
        // Initialize controller with reels
        await _controller.initialize(
          reels: _reels,
          config: widget.config ?? ReelConfig(),
        );
      }
    } catch (e) {
      debugPrint('Error loading reels: $e');
      // Use sample data as fallback
      _reels = SampleData.basicReels;
      if (_reels.isNotEmpty) {
        await _controller.initialize(
          reels: _reels,
          config: widget.config ?? ReelConfig(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: Text('Loading...'))
              : _reels.isEmpty
                  ? const Center(child: Text('No reels available'))
                  : AwesomeReels(
                      reels: _reels,
                      controller: _controller,
                      config: widget.config?.copyWith(
                            showDownloadButton: false,
                            enablePullToRefresh: true,
                          ) ??
                          ReelConfig(
                            showDownloadButton: false,
                            enablePullToRefresh: true,
                          ),
                      onReelChanged: (index) {
                        debugPrint('Reel changed to index: $index');
                      },
                      onReelLiked: (reel) {
                        _showSnackBar(
                            '${reel.isLiked ? 'Liked' : 'Unliked'} ${reel.user?.displayName}\'s reel');
                      },
                      onReelShared: (reel) {
                        _showSnackBar(
                            'Shared ${reel.user?.displayName}\'s reel');
                      },
                      onReelCommented: (reel) {
                        // Show comment dialog or navigate to comments page
                      },
                      onUserFollowed: (user) {
                        _showSnackBar(
                            '${user.isFollowing ? 'Following' : 'Unfollowed'} ${user.displayName}');
                      },
                      onUserBlocked: (user) {
                        _showSnackBar('Blocked ${user.displayName}');
                      },
                      onVideoCompleted: (reel) {
                        debugPrint('Video completed: ${reel.id}');
                      },
                      onVideoError: (reel, error) {
                        _showSnackBar('Error playing video: $error');
                      },
                    ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.grey[800],
      ),
    );
  }
}

class SampleData {
  static final List<ReelModel> basicReels = [
    ReelModel(
      id: '4',
      videoSource: VideoSource(
          url:
              'https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd'),
      user: const ReelUser(
        id: 'u2',
        username: 'bob',
        displayName: 'Bob Builder',
        isFollowing: true,
      ),
      likesCount: 200,
      commentsCount: 30,
      sharesCount: 10,
      tags: ['adventure', 'travel'],
      audio: const ReelAudio(title: 'Adventure Tune'),
      duration: const Duration(seconds: 20),
      isLiked: true,
      views: 2500,
      location: 'Mountains',
    ),
    ReelModel(
      id: '1',
      videoSource: VideoSource(
          url:
              'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4'),
      user: const ReelUser(
        id: 'u3',
        username: 'charlie',
        displayName: 'Charlie Chaplin',
      ),
      likesCount: 4325,
      commentsCount: 45,
      sharesCount: 20,
      tags: ['comedy', 'classic'],
      audio: const ReelAudio(title: 'Classic Comedy'),
      duration: const Duration(seconds: 15),
      isLiked: false,
      views: 5000,
      location: 'Hollywood',
    ),
    ReelModel(
      id: '3',
      videoSource: VideoSource(
          url:
              'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8'),
      user: const ReelUser(
        id: 'u1',
        username: 'alice',
        displayName: 'Alice in Wonderland',
      ),
      likesCount: 120,
      commentsCount: 15,
      sharesCount: 5,
      tags: ['fun', 'bunny'],
      audio: const ReelAudio(title: 'Sample Music'),
      duration: const Duration(seconds: 10),
      isLiked: false,
      views: 1000,
      location: 'Wonderland',
    ),
  ];
}
