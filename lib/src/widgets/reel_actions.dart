import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../controllers/reel_controller.dart';
import '../utils/reel_utils.dart';

/// Widget that displays action buttons (like, comment, share, etc.) on the right side
class ReelActions extends StatefulWidget {
  final ReelModel reel;
  final ReelConfig config;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onFollow;
  final VoidCallback? onBlock;

  const ReelActions({
    Key? key,
    required this.reel,
    required this.config,
    this.onLike,
    this.onShare,
    this.onComment,
    this.onFollow,
    this.onBlock,
  }) : super(key: key);

  @override
  State<ReelActions> createState() => _ReelActionsState();
}

class _ReelActionsState extends State<ReelActions>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _pulseAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _likeAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReelController>(
      builder: (context, controller, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Like button
            _buildActionButton(
              icon:
                  widget.reel.isLiked ? Icons.favorite : Icons.favorite_border,
              iconColor:
                  widget.reel.isLiked ? Colors.red : widget.config.textColor,
              count: widget.reel.likesCount,
              onTap: () => _handleLike(controller),
              animation: _likeAnimation,
            ),

            const SizedBox(height: 16),

            // Comment button
            _buildActionButton(
              icon: Icons.comment,
              iconColor: widget.config.textColor,
              count: widget.reel.commentsCount,
              onTap: () => _handleComment(controller),
            ),

            const SizedBox(height: 16),

            // Share button
            _buildActionButton(
              icon: Icons.share,
              iconColor: widget.config.textColor,
              count: widget.reel.sharesCount,
              onTap: () => _handleShare(controller),
            ),

            const SizedBox(height: 16),

            // Bookmark button
            if (widget.config.showBookmarkButton)
              _buildActionButton(
                icon: widget.reel.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                iconColor: widget.reel.isBookmarked
                    ? widget.config.accentColor
                    : widget.config.textColor,
                onTap: () => _handleBookmark(controller),
              ),

            if (widget.config.showBookmarkButton) const SizedBox(height: 16),

            // Download button
            if (widget.config.showDownloadButton)
              _buildActionButton(
                icon: Icons.download,
                iconColor: widget.config.textColor,
                onTap: () => _handleDownload(controller),
              ),

            if (widget.config.showDownloadButton) const SizedBox(height: 16),

            // More options button
            if (widget.config.showMoreButton)
              _buildActionButton(
                icon: Icons.more_vert,
                iconColor: widget.config.textColor,
                onTap: () => _showMoreOptions(context, controller),
              ),

            if (widget.config.showMoreButton)
              const SizedBox(
                  height: 16), // Creator avatar (spinning music note style)
            if (widget.reel.musicTitle != null) _buildMusicAvatar(),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    int? count,
    required VoidCallback onTap,
    Animation<double>? animation,
  }) {
    Widget iconWidget = Icon(
      icon,
      color: iconColor,
      size: 28,
    );

    if (animation != null && !_isDisposed) {
      // iconWidget = AnimatedBuilder(
      //   animation: animation,
      //   builder: (context, child) {
      //     return Transform.scale(
      //       scale: animation.value,
      //       child: iconWidget,
      //     );
      //   },
      // );
      iconWidget = Transform.scale(
        scale: animation.value,
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black26,
              ),
              child: iconWidget,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(height: 4),
              Text(
                ReelUtils.formatCount(count),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMusicAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _pulseAnimationController.value * 2 * 3.14159,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    widget.config.accentColor,
                    widget.config.accentColor.withOpacity(0.7),
                  ],
                ),
                border: Border.all(
                  color: widget.config.textColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.music_note,
                color: widget.config.textColor,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLike(ReelController controller) {
    controller.toggleLike(widget.reel.id);

    if (!widget.reel.isLiked) {
      if (mounted) {
        _likeAnimationController.forward().then((_) {
          if (mounted) _likeAnimationController.reverse();
        });
        _showFloatingHeart();
      }
    }
    if (widget.onLike != null) widget.onLike!();
  }

  void _handleComment(ReelController controller) {
    if (widget.config.onCommentTap != null) {
      widget.config.onCommentTap!(widget.reel);
    } else {
      _showCommentsBottomSheet(context, controller);
    }
    if (widget.onComment != null) widget.onComment!();
  }

  void _handleShare(ReelController controller) {
    controller.incrementShare(widget.reel.id);

    if (widget.config.onShareTap != null) {
      widget.config.onShareTap!(widget.reel);
    } else {
      // Default share implementation - can be customized by the app
      debugPrint('Sharing reel: ${widget.reel.videoUrl}');
    }
    if (widget.onShare != null) widget.onShare!();
  }

  void _handleBookmark(ReelController controller) {
    controller.toggleBookmark(widget.reel.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.reel.isBookmarked
              ? 'Removed from bookmarks'
              : 'Added to bookmarks',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: widget.config.accentColor,
      ),
    );
  }

  void _handleDownload(ReelController controller) {
    if (widget.config.onDownloadTap != null) {
      widget.config.onDownloadTap!(widget.reel);
    } else {
      controller.downloadReel(widget.reel);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download started...'),
          duration: const Duration(seconds: 2),
          backgroundColor: widget.config.accentColor,
        ),
      );
    }
  }

  void _showFloatingHeart() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    late AnimationController animationController;

    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Positioned(
            left: position.dx + 20,
            top: position.dy - (50 * animation.value),
            child: Opacity(
              opacity: 1.0 - animation.value,
              child: Transform.scale(
                scale: 0.5 + (0.5 * animation.value),
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(overlayEntry);

    animationController.forward().then((_) {
      overlayEntry.remove();
      animationController.dispose();
    });
  }

  void _showCommentsBottomSheet(
      BuildContext context, ReelController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        ReelUtils.formatCount(widget.reel.commentsCount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 10, // Placeholder
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.config.accentColor,
                          child: Text('U${index + 1}'),
                        ),
                        title: Text('User ${index + 1}'),
                        subtitle:
                            Text('This is a sample comment #${index + 1}'),
                        trailing: IconButton(
                          icon: Icon(Icons.favorite_border),
                          onPressed: () {},
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                    top: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: widget.config.accentColor,
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMoreOptions(BuildContext context, ReelController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _handleReport(controller);
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Block user'),
              onTap: () {
                Navigator.pop(context);
                _handleBlock(controller);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copy link'),
              onTap: () {
                Navigator.pop(context);
                _handleCopyLink(controller);
              },
            ),
            if (widget.config.customActions.isNotEmpty)
              ...widget.config.customActions.map((action) => ListTile(
                    leading: Icon(action.icon),
                    title: Text(action.title),
                    onTap: () {
                      Navigator.pop(context);
                      action.onTap(widget.reel);
                    },
                  )),
          ],
        ),
      ),
    );
  }

  void _handleReport(ReelController controller) {
    // Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Content reported'),
        backgroundColor: widget.config.accentColor,
      ),
    );
  }

  void _handleBlock(ReelController controller) {
    if (widget.reel.user?.id == null) return;

    // Implement block functionality
    controller.blockUser(widget.reel.user!.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User blocked'),
        backgroundColor: widget.config.accentColor,
      ),
    );
    if (widget.onBlock != null) widget.onBlock!();
  }

  void _handleCopyLink(ReelController controller) {
    // Implement copy link functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: widget.config.accentColor,
      ),
    );
  }

  void _handleFollow(ReelController controller) {
    if (widget.reel.user?.id == null) return;
    controller.followUser(widget.reel.user!.id);
    if (widget.onFollow != null) widget.onFollow!();
  }
}
