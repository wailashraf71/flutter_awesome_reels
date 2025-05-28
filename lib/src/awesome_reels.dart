import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/reel_model.dart';
import 'models/reel_config.dart';
import 'controllers/reel_controller.dart';
import 'widgets/reel_video_player.dart';
import 'widgets/reel_overlay.dart';

/// The main AwesomeReels widget for displaying vertical video reels
class AwesomeReels extends StatefulWidget {
  /// List of reel models to display
  final List<ReelModel> reels;

  /// Configuration for the reels widget
  final ReelConfig config;

  /// Initial page index
  final int initialIndex;

  /// Callback when page changes
  final void Function(int index, ReelModel reel)? onPageChanged;

  /// Callback when video tapped
  final void Function(ReelModel reel, Duration position)? onVideoTapped;

  /// Callback when like button tapped
  final void Function(ReelModel reel, bool isLiked)? onLikeTapped;

  /// Callback when comment button tapped
  final void Function(ReelModel reel)? onCommentTapped;

  /// Callback when share button tapped
  final void Function(ReelModel reel)? onShareTapped;

  /// Callback when follow button tapped
  final void Function(ReelModel reel, bool isFollowing)? onFollowTapped;

  /// Callback when user profile tapped
  final void Function(ReelModel reel)? onUserProfileTapped;

  /// Custom overlay builder
  final Widget Function(
          BuildContext context, ReelModel reel, ReelController controller)?
      overlayBuilder;

  /// Custom error widget builder
  final Widget Function(BuildContext context, ReelModel reel, String error)?
      errorBuilder;

  /// Custom loading widget builder
  final Widget Function(BuildContext context, ReelModel reel)? loadingBuilder;

  final ReelController? controller;
  final void Function(int index)? onReelChanged;
  final void Function(ReelModel reel)? onReelLiked;
  final void Function(ReelModel reel)? onReelShared;
  final void Function(ReelModel reel)? onReelCommented;
  final void Function(ReelUser user)? onUserFollowed;
  final void Function(ReelUser user)? onUserBlocked;
  final void Function(ReelModel reel)? onVideoCompleted;
  final void Function(ReelModel reel, Object error)? onVideoError;

  const AwesomeReels({
    Key? key,
    required this.reels,
    this.config = const ReelConfig(),
    this.initialIndex = 0,
    this.controller,
    this.onReelChanged,
    this.onReelLiked,
    this.onReelShared,
    this.onReelCommented,
    this.onUserFollowed,
    this.onUserBlocked,
    this.onVideoCompleted,
    this.onVideoError,
    this.onPageChanged,
    this.onVideoTapped,
    this.onLikeTapped,
    this.onCommentTapped,
    this.onShareTapped,
    this.onFollowTapped,
    this.onUserProfileTapped,
    this.overlayBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<AwesomeReels> createState() => _AwesomeReelsState();
}

class _AwesomeReelsState extends State<AwesomeReels>
    with AutomaticKeepAliveClientMixin {
  late ReelController _controller;
  bool _isInitialized = false;
  bool _isExternalController = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isExternalController = widget.controller != null;
    _controller = widget.controller ?? ReelController();
    _initializeController();
  }

  @override
  void didUpdateWidget(AwesomeReels oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize if reels or config changed
    if (widget.reels != oldWidget.reels || widget.config != oldWidget.config) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    _controller = ReelController();

    try {
      await _controller.initialize(
        reels: widget.reels,
        config: widget.config,
        initialIndex: widget.initialIndex,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing AwesomeReels: $e');
    }
  }

  @override
  void dispose() {
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return ChangeNotifierProvider<ReelController>.value(
      value: _controller,
      child: Container(
        color: widget.config.backgroundColor,
        child: widget.config.enablePullToRefresh
            ? RefreshIndicator(
                onRefresh: () async {
                  await _controller.refresh();
                },
                child: _buildPageView(),
              )
            : _buildPageView(),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _controller.pageController,
      scrollDirection: Axis.vertical,
      physics: widget.config.physics,
      itemCount: widget.reels.length,
      onPageChanged: (index) {
        _controller.onPageChanged(index);
        if (widget.onReelChanged != null) {
          widget.onReelChanged!(index);
        }
      },
      itemBuilder: (context, index) {
        if (index >= widget.reels.length) return const SizedBox.shrink();
        final reel = widget.reels[index];
        return _buildReelItem(reel, index);
      },
    );
  }

  Widget _buildReelItem(ReelModel reel, int index) {
    return Consumer<ReelController>(
      builder: (context, controller, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ReelVideoPlayer(
              reel: reel,
              controller: controller,
              config: widget.config,
              onTap: (position) {
                if (widget.onVideoTapped != null) {
                  widget.onVideoTapped!(reel, position);
                }
              },
              errorBuilder: (context, reel, error) {
                if (widget.onVideoError != null) {
                  widget.onVideoError!(reel, error);
                }
                return widget.errorBuilder?.call(context, reel, error) ??
                    const SizedBox.shrink();
              },
              loadingBuilder: widget.loadingBuilder,
            ),
            if (widget.overlayBuilder != null)
              widget.overlayBuilder!(context, reel, controller)
            else
              ReelOverlay(
                reel: reel,
                config: widget.config,
                onTap: () {
                  if (widget.onVideoTapped != null) {
                    final controller = context.read<ReelController>();
                    widget.onVideoTapped!(reel, controller.currentPosition);
                  }
                },
                onLike: () => widget.onReelLiked?.call(reel),
                onShare: () => widget.onReelShared?.call(reel),
                onComment: () => widget.onReelCommented?.call(reel),
                onFollow: () => widget.onUserFollowed?.call(reel.user!),
                onBlock: () => widget.onUserBlocked?.call(reel.user!),
                onCompleted: () => widget.onVideoCompleted?.call(reel),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.config.loadingWidgetBuilder != null) {
      return widget.config.loadingWidgetBuilder!(context);
    }

    if (widget.config.showShimmerWhileLoading) {
      return _buildShimmerEffect();
    }

    return Container(
      color: widget.config.backgroundColor,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    final shimmerConfig = widget.config.shimmerConfig ?? const ShimmerConfig();

    return Container(
      color: widget.config.backgroundColor,
      child: Stack(
        children: [
          // Background shimmer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  shimmerConfig.baseColor,
                  shimmerConfig.highlightColor,
                  shimmerConfig.baseColor,
                ],
                stops: const [0.4, 0.5, 0.6],
                begin: _getShimmerAlignment(shimmerConfig.direction, true),
                end: _getShimmerAlignment(shimmerConfig.direction, false),
              ),
            ),
          ),

          // Overlay elements
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: List.generate(
                  4,
                  (index) => Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: shimmerConfig.highlightColor,
                          shape: BoxShape.circle,
                        ),
                      )),
            ),
          ),

          Positioned(
            bottom: 32,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: shimmerConfig.highlightColor,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: shimmerConfig.highlightColor,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 200,
                  height: 14,
                  color: shimmerConfig.highlightColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Alignment _getShimmerAlignment(ShimmerDirection direction, bool isBegin) {
    switch (direction) {
      case ShimmerDirection.ltr:
        return isBegin ? Alignment.centerLeft : Alignment.centerRight;
      case ShimmerDirection.rtl:
        return isBegin ? Alignment.centerRight : Alignment.centerLeft;
      case ShimmerDirection.ttb:
        return isBegin ? Alignment.topCenter : Alignment.bottomCenter;
      case ShimmerDirection.btt:
        return isBegin ? Alignment.bottomCenter : Alignment.topCenter;
    }
  }
}

/// Extension methods for AwesomeReels
extension AwesomeReelsExtension on AwesomeReels {
  /// Create AwesomeReels from video URLs
  static AwesomeReels fromUrls(
    List<String> videoUrls, {
    ReelConfig config = const ReelConfig(),
    int initialIndex = 0,
    void Function(int index, ReelModel reel)? onPageChanged,
    void Function(ReelModel reel, Duration position)? onVideoTapped,
  }) {
    final reels = videoUrls.asMap().entries.map((entry) {
      return ReelModel(
        id: 'reel_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
        videoUrl: entry.value,
      );
    }).toList();

    return AwesomeReels(
      reels: reels,
      config: config,
      initialIndex: initialIndex,
      onPageChanged: onPageChanged,
      onVideoTapped: onVideoTapped,
    );
  }
}
