import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../controllers/reel_controller.dart';
import '../utils/reel_utils.dart';
import 'reel_actions.dart';
import 'reel_progress_indicator.dart';

/// Overlay widget that displays over the video with user info, actions, and controls
class ReelOverlay extends StatelessWidget {
  final ReelModel reel;
  final ReelConfig config;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onFollow;
  final VoidCallback? onBlock;
  final VoidCallback? onCompleted;

  const ReelOverlay({
    super.key,
    required this.reel,
    required this.config,
    this.onTap,
    this.onLike,
    this.onShare,
    this.onComment,
    this.onFollow,
    this.onBlock,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReelController>();
    return Obx(() => GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withAlpha(100),
                  Colors.black.withAlpha(150),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Main content area
                Positioned(
                  bottom: 80,
                  left: 16,
                  right: 80,
                  child: _buildUserInfo(context, controller),
                ),

                // Actions on the right
                Positioned(
                  bottom: 80,
                  right: 12,
                  child: ReelActions(
                    reel: reel,
                    config: config,
                    onLike: onLike,
                    onShare: onShare,
                    onComment: onComment,
                    onFollow: onFollow,
                    onBlock: onBlock,
                  ),
                ),

                // Bottom controls
                if (config.showBottomControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControls(context, controller),
                  ),

                // Loading indicator
                if (controller.isLoading)
                  Center(
                    child: Lottie.asset('assets/reel-loading.json'),
                  ),

                // Error overlay
                if (controller.hasError)
                  _buildErrorOverlay(context, controller),

                // Buffering indicator
                if (controller.isBuffering)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              config.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buffering...',
                            style: TextStyle(
                              color: config.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Progress indicator at bottom (always visible, no padding)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ReelProgressIndicator(
                    reel: reel,
                    config: config,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildUserInfo(BuildContext context, ReelController controller) {
    if (reel.user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info row
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: reel.user!.profilePictureUrl != null
                  ? NetworkImage(reel.user!.profilePictureUrl!)
                  : null,
              backgroundColor: config.accentColor,
              child: reel.user!.profilePictureUrl == null
                  ? Icon(
                      Icons.person,
                      color: config.textColor,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel.user!.username,
                    style: TextStyle(
                      color: config.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (reel.user!.displayName != null)
                    Text(
                      reel.user!.displayName!,
                      style: TextStyle(
                        color: config.textColor.withAlpha(192),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (config.showFollowButton && !(reel.user?.isFollowing ?? true))
              OutlinedButton(
                onPressed: () => _handleFollow(context, controller),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: config.accentColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'Follow',
                  style: TextStyle(
                    color: config.accentColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12), // Caption
        if (reel.caption?.isNotEmpty == true)
          Text(
            reel.caption!,
            style: TextStyle(
              color: config.textColor,
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: config.maxCaptionLines,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 8),

        // Hashtags
        if (reel.hashtags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: reel.hashtags
                .map((hashtag) {
                  return GestureDetector(
                    onTap: () => _handleHashtagTap(context, hashtag),
                    child: Text(
                      '#$hashtag',
                      style: TextStyle(
                        color: config.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                })
                .take(5)
                .toList(),
          ),

        const SizedBox(height: 8),

        // Music info
        if (reel.musicTitle != null)
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: config.textColor.withAlpha(192),
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  reel.musicTitle!,
                  style: TextStyle(
                    color: config.textColor.withAlpha(192),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context, ReelController controller) {
    final isPlaying =
        controller.currentVideoController?.value.isPlaying ?? false;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Row(
        children: [
          // Play/Pause button
          IconButton(
            onPressed: () => controller.togglePlayPause(),
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: config.textColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 8),

          // Progress bar
          Expanded(
            child: ReelProgressIndicator(
              reel: reel,
              config: config,
              showThumb: true,
            ),
          ),

          const SizedBox(width: 8), // Duration
          Text(
            ReelUtils.formatDurationFromMilliseconds(reel.duration),
            style: TextStyle(
              color: config.textColor.withAlpha(192),
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 8),

          // Mute button
          IconButton(
            onPressed: () => controller.toggleMute(),
            icon: Icon(
              controller.isMuted ? Icons.volume_off : Icons.volume_up,
              color: config.textColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context, ReelController controller) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage ?? 'Unknown error occurred',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => controller.clearError(),
                    child: Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => controller.retry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.accentColor,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFollow(BuildContext context, ReelController controller) {
    if (reel.user?.id == null) return;

    // Implement follow functionality
    controller.followUser(reel.user!.id);

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Following ${reel.user!.username}'),
        duration: const Duration(seconds: 2),
        backgroundColor: config.accentColor,
      ),
    );
  }

  void _handleHashtagTap(BuildContext context, String hashtag) {
    // Navigate to hashtag page or trigger callback
    if (config.onHashtagTap != null) {
      config.onHashtagTap!(hashtag);
    }
  }
}
