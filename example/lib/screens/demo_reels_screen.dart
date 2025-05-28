import 'package:flutter/material.dart';
import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';

class DemoReelsScreen extends StatefulWidget {
  final List<ReelModel> reels;
  final String title;
  final ReelConfig? config;

  const DemoReelsScreen({
    super.key,
    required this.reels,
    required this.title,
    this.config,
  });

  @override
  State<DemoReelsScreen> createState() => _DemoReelsScreenState();
}

class _DemoReelsScreenState extends State<DemoReelsScreen> {
  final ReelController _controller = ReelController();
  int _currentIndex = 0;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: AwesomeReels(
        reels: widget.reels,
        controller: _controller,
        config:
            widget.config?.copyWith(showDownloadButton: false) ?? ReelConfig(),
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
          print('Video completed: ${reel.id}');
        },
        onVideoError: (reel, error) {
          _showSnackBar('Error playing video: $error');
        },
      ),
    );
  }

  void _showInfoDialog() {
    final currentReel = widget.reels[_currentIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Reel Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                'Creator', currentReel.user?.displayName ?? 'Unknown'),
            _buildInfoRow('Username', '@${currentReel.user?.username}'),
            _buildInfoRow('Likes', '${currentReel.likesCount}'),
            _buildInfoRow('Comments', '${currentReel.commentsCount}'),
            _buildInfoRow('Shares', '${currentReel.sharesCount}'),
            _buildInfoRow('Views', '${currentReel.views}'),
            _buildInfoRow('Duration', '${currentReel.duration! ~/ 1000}s'),
            if (currentReel.location != null)
              _buildInfoRow('Location', currentReel.location!),
            if (currentReel.hashtags.isNotEmpty)
              _buildInfoRow('Hashtags', currentReel.hashtags.join(', ')),
            if (currentReel.musicTitle != null)
              _buildInfoRow('Music', currentReel.musicTitle!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog(ReelModel reel) {
    final TextEditingController commentController = TextEditingController();

    print('Commenting on reel: ${reel.id}');
    print('Reel user: ${reel.user?.displayName}');

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
