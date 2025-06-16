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
  int _currentIndex = 0;
  List<ReelModel> _reels = [];

  @override
  void initState() {
    super.initState();
    _controller = ReelController();
    _loadReels();
  }

  Future<void> _loadReels() async {
    // Simulate loading reels from an API
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _reels = widget.reels ?? SampleData.basicReels;
    });

    // Initialize controller with reels
    await _controller.initialize(
      reels: _reels,
      config: widget.config ?? ReelConfig(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _reels.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                setState(() {
                  _currentIndex = index;
                });
              },
              onReelLiked: (reel) {
                _showSnackBar(
                    '${reel.isLiked ? 'Liked' : 'Unliked'} ${reel.user?.displayName}\'s reel');
              },
              onReelShared: (reel) {
                _showSnackBar('Shared ${reel.user?.displayName}\'s reel');
              },
              onReelCommented: (reel) {
                _showCommentDialog(reel);
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
    );
  }

  void _showCommentDialog(ReelModel reel) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comment on ${reel.user?.displayName}\'s reel'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                _showSnackBar('Comment posted: ${commentController.text}');
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
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
      id: '1',
      videoSource: VideoSource(
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      ),
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
    ReelModel(
      id: '2',
      videoSource: VideoSource(
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      ),
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
      id: '3',
      videoSource: VideoSource(
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      ),
      user: const ReelUser(
        id: 'u3',
        username: 'charlie',
        displayName: 'Charlie Chaplin',
      ),
      likesCount: 300,
      commentsCount: 45,
      sharesCount: 20,
      tags: ['comedy', 'classic'],
      audio: const ReelAudio(title: 'Classic Comedy'),
      duration: const Duration(seconds: 15),
      isLiked: false,
      views: 5000,
      location: 'Hollywood',
    ),
  ];
}
