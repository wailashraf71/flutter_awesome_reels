import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../controllers/reel_controller.dart';
import '../utils/reel_utils.dart';
import 'reel_actions.dart';
import 'reel_progress_indicator.dart';

/// Overlay widget that displays over the video with user info, actions, and controls
class ReelOverlay extends StatefulWidget {
  final ReelModel reel;
  final ReelConfig config;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onFollow;
  final VoidCallback? onBlock;
  final VoidCallback? onCompleted;
  final ReelController controller;

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
    required this.controller,
  });

  @override
  State<ReelOverlay> createState() => _ReelOverlayState();
}

class _ReelOverlayState extends State<ReelOverlay> {
  void _showLikeAnimation() {
    if (mounted) {
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => Center(
          child: Icon(
            Icons.favorite,
            color: Colors.red,
            size: 100,
          ),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(milliseconds: 500), () {
        entry.remove();
      });
    }
  }

  Widget _buildLikeButton() {
    final isLiked = widget.reel.isLiked;
    return GestureDetector(
      onTap: () {
        widget.controller.toggleLike(widget.reel.id);
        if (!isLiked) {
          _showLikeAnimation();
        }
      },
      child: Column(
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : widget.config.textColor,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            widget.reel.likesCount.toString(),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: widget.onTap,
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
                  child: _buildUserInfo(context),
                ),

                // Actions on the right
                Positioned(
                  bottom: 80,
                  right: 12,
                  child: ReelActions(
                    reel: widget.reel,
                    config: widget.config,
                    onLike: widget.onLike,
                    onShare: widget.onShare,
                    onComment: widget.onComment,
                    onFollow: widget.onFollow,
                    onBlock: widget.onBlock,
                  ),
                ),

                // Bottom controls
                if (widget.config.showBottomControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControls(context),
                  ), // Loading indicator (only show if video controller exists but video not ready)
                if (widget.controller.currentVideoController != null &&
                    !widget.controller.currentVideoController!.value
                        .isInitialized &&
                    !widget.controller.hasError)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                // Error overlay
                if (widget.controller.hasError) _buildErrorOverlay(context),

                // Buffering indicator
                if (widget.controller.isBuffering)
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
                              widget.config.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buffering...',
                            style: TextStyle(
                              color: widget.config.textColor,
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
                    reel: widget.reel,
                    config: widget.config,
                  ),
                ),

                // Like button
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      _buildLikeButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildUserInfo(BuildContext context) {
    if (widget.reel.user == null) {
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
              backgroundImage: widget.reel.user!.profilePictureUrl != null
                  ? NetworkImage(widget.reel.user!.profilePictureUrl!)
                  : null,
              backgroundColor: widget.config.accentColor,
              child: widget.reel.user!.profilePictureUrl == null
                  ? Icon(
                      Icons.person,
                      color: widget.config.textColor,
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
                    widget.reel.user!.username,
                    style: TextStyle(
                      color: widget.config.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (widget.reel.user!.displayName != null)
                    Text(
                      widget.reel.user!.displayName!,
                      style: TextStyle(
                        color: widget.config.textColor.withAlpha(192),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.config.showFollowButton &&
                !(widget.reel.user?.isFollowing ?? true))
              OutlinedButton(
                onPressed: () => _handleFollow(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.config.followButtonColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'Follow',
                  style: TextStyle(
                    color: widget.config.followButtonColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12), // Caption
        if (widget.reel.caption?.isNotEmpty == true)
          Text(
            widget.reel.caption!,
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: widget.config.maxCaptionLines,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 8),

        // Hashtags
        if (widget.reel.hashtags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.reel.hashtags
                .map((hashtag) {
                  return GestureDetector(
                    onTap: () => _handleHashtagTap(context, hashtag),
                    child: Text(
                      '#$hashtag',
                      style: TextStyle(
                        color: widget.config.accentColor,
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
        if (widget.reel.musicTitle != null)
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: widget.config.textColor.withAlpha(192),
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.reel.musicTitle!,
                  style: TextStyle(
                    color: widget.config.textColor.withAlpha(192),
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

  Widget _buildBottomControls(BuildContext context) {
    final isPlaying =
        widget.controller.currentVideoController?.value.isPlaying ?? false;

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
            onPressed: () => widget.controller.togglePlayPause(),
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.config.textColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 8),

          // Progress bar
          Expanded(
            child: ReelProgressIndicator(
              reel: widget.reel,
              config: widget.config,
              showThumb: true,
            ),
          ),

          const SizedBox(width: 8), // Duration
          Text(
            ReelUtils.formatDurationFromMilliseconds(
                widget.reel.duration?.inMilliseconds),
            style: TextStyle(
              color: widget.config.textColor.withAlpha(192),
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 8),

          // Mute button
          IconButton(
            onPressed: () => widget.controller.toggleMute(),
            icon: Icon(
              widget.controller.isMuted ? Icons.volume_off : Icons.volume_up,
              color: widget.config.textColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
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
                widget.controller.errorMessage ?? 'Unknown error occurred',
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
                    onPressed: () => widget.controller.clearError(),
                    child: Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => widget.controller.retry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.config.accentColor,
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

  void _handleFollow(BuildContext context) {
    if (widget.reel.user?.id == null) return;

    // Implement follow functionality
    widget.controller.followUser(widget.reel.user!.id);

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Following ${widget.reel.user!.username}'),
        duration: const Duration(seconds: 2),
        backgroundColor: widget.config.accentColor,
      ),
    );
  }

  void _handleHashtagTap(BuildContext context, String hashtag) {
    // Navigate to hashtag page or trigger callback
    if (widget.config.onHashtagTap != null) {
      widget.config.onHashtagTap!(hashtag);
    }
  }
}
