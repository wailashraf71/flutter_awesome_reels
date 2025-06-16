import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../models/reel_model.dart';
import '../models/reel_config.dart';
import '../controllers/reel_controller.dart';
import '../utils/reel_utils.dart';

/// Widget that displays video progress indicator
class ReelProgressIndicator extends StatefulWidget {
  final ReelModel reel;
  final ReelConfig config;
  final bool showThumb;
  final bool showTime;
  final double height;
  final Function(Duration)? onSeek;
  final bool showThumbnail;

  const ReelProgressIndicator({
    super.key,
    required this.reel,
    required this.config,
    this.showThumb = false,
    this.showTime = false,
    this.height = 3.0,
    this.onSeek,
    this.showThumbnail = false,
  });

  @override
  State<ReelProgressIndicator> createState() => _ReelProgressIndicatorState();
}

class _ReelProgressIndicatorState extends State<ReelProgressIndicator>
    with SingleTickerProviderStateMixin {
  final RxBool _isDragging = false.obs;
  final RxnDouble _dragValue = RxnDouble();
  final RxBool _showThumbnail = false.obs;
  final RxnDouble _thumbnailPosition = RxnDouble();
  final Rx<Duration> _thumbnailTime = Rx<Duration>(Duration.zero);
  late AnimationController _heightAnimationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _heightAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heightAnimation = Tween<double>(
      begin: widget.height.toDouble(),
      end: (widget.height * 2.5).toDouble(),
    ).animate(CurvedAnimation(
      parent: _heightAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _heightAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReelController>();
    return Obx(() {
      final videoController = controller.currentVideoController;
      if (videoController == null || !videoController.value.isInitialized) {
        return const SizedBox.shrink();
      }

      return ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: videoController,
        builder: (context, value, child) {
          if (!value.isInitialized) {
            return const SizedBox.shrink();
          }

          final position = value.position;
          final duration = value.duration;

          if (duration.inMilliseconds <= 0) {
            return const SizedBox.shrink();
          }

          final progress = _isDragging.value
              ? (_dragValue.value ?? 0.0)
              : position.inMilliseconds / duration.inMilliseconds;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail preview
              if (widget.showThumbnail &&
                  _showThumbnail.value &&
                  _thumbnailPosition.value != null)
                _buildThumbnailPreview(
                  videoController,
                  _thumbnailPosition.value!,
                  _thumbnailTime.value,
                ),
              // Progress bar
              _buildProgressBar(
                controller,
                progress,
                duration,
                position,
              ),
              // Time indicators
              if (widget.showTime) ...[
                const SizedBox(height: 4),
                _buildTimeIndicators(position, duration),
              ],
            ],
          );
        },
      );
    });
  }

  Widget _buildThumbnailPreview(
    VideoPlayerController controller,
    double position,
    Duration time,
  ) {
    return Positioned(
      bottom: widget.height + 8,
      left: position - 60,
      child: Container(
        width: 120,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white30),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: widget.config.textColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ReelUtils.formatDuration(time),
                    style: TextStyle(
                      color: widget.config.textColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    ReelController controller,
    double progress,
    Duration duration,
    Duration position,
  ) {
    return Container(
      color: Colors.transparent,
      child: GestureDetector(
        onTapDown: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = details.localPosition;
          final width = box.size.width;
          final tapPosition = (localPosition.dx / width).clamp(0.0, 1.0);

          final newPosition = Duration(
            milliseconds: (tapPosition * duration.inMilliseconds).round(),
          );
          controller.seekTo(newPosition);
          if (widget.onSeek != null) {
            widget.onSeek!(newPosition);
          }
        },
        onHorizontalDragStart: (details) {
          _isDragging.value = true;
          _heightAnimationController.forward();
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = details.localPosition;
          final width = box.size.width;
          final dragPosition = (localPosition.dx / width).clamp(0.0, 1.0);
          _dragValue.value = dragPosition;

          if (widget.showThumbnail) {
            _showThumbnail.value = true;
            _thumbnailPosition.value = localPosition.dx;
            _thumbnailTime.value = Duration(
              milliseconds: (dragPosition * duration.inMilliseconds).round(),
            );
          }

          controller.pause();
        },
        onHorizontalDragUpdate: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = details.localPosition;
          final width = box.size.width;
          final dragPosition = (localPosition.dx / width).clamp(0.0, 1.0);
          _dragValue.value = dragPosition;

          if (widget.showThumbnail) {
            _thumbnailPosition.value = localPosition.dx;
            _thumbnailTime.value = Duration(
              milliseconds: (dragPosition * duration.inMilliseconds).round(),
            );
          }
        },
        onHorizontalDragEnd: (details) {
          final controller = Get.find<ReelController>();
          final videoController = controller.currentVideoController;
          if (videoController != null && _dragValue.value != null) {
            final newPosition = Duration(
              milliseconds:
                  (_dragValue.value! * duration.inMilliseconds).round(),
            );
            controller.seekTo(newPosition);
            if (widget.onSeek != null) {
              widget.onSeek!(newPosition);
            }
            Future.delayed(const Duration(milliseconds: 100), () {
              if (controller.wasPlayingBeforeSeek) {
                controller.play();
              }
            });
          }
          _isDragging.value = false;
          _dragValue.value = null;
          _showThumbnail.value = false;
          _thumbnailPosition.value = null;
          _heightAnimationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return Container(
              height: _heightAnimation.value,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(_heightAnimation.value / 2),
              ),
              child: Stack(
                children: [
                  // Progress fill
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.config.progressColor ?? Colors.white,
                        borderRadius:
                            BorderRadius.circular(_heightAnimation.value / 2),
                      ),
                    ),
                  ),

                  // Draggable thumb
                  if (widget.showThumb)
                    Positioned(
                      left: progress.clamp(0.0, 1.0) *
                              MediaQuery.of(context).size.width -
                          (_isDragging.value ? 12 : 8),
                      top: (_heightAnimation.value - 16) / 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isDragging.value ? 24 : 16,
                        height: _isDragging.value ? 24 : 16,
                        decoration: BoxDecoration(
                          color: widget.config.progressColor ?? Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeIndicators(Duration position, Duration duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ReelUtils.formatDuration(position),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: 12,
            ),
          ),
          Text(
            ReelUtils.formatDuration(duration),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Advanced progress indicator with buffering and chapters
class AdvancedReelProgressIndicator extends StatefulWidget {
  final ReelModel reel;
  final ReelConfig config;
  final List<Duration>? chapters;
  final bool showBuffering;

  const AdvancedReelProgressIndicator({
    super.key,
    required this.reel,
    required this.config,
    this.chapters,
    this.showBuffering = true,
  });

  @override
  State<AdvancedReelProgressIndicator> createState() =>
      _AdvancedReelProgressIndicatorState();
}

class _AdvancedReelProgressIndicatorState
    extends State<AdvancedReelProgressIndicator> {
  final RxBool _isDragging = false.obs;
  final RxnDouble _dragValue = RxnDouble();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReelController>();
    return Obx(() {
      final videoController = controller.currentVideoController;
      if (videoController == null) {
        return _buildLoadingProgress();
      }
      return StreamBuilder<Duration>(
        stream: controller.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = videoController.value.duration;
          final buffered = videoController.value.buffered;
          if (duration.inMilliseconds <= 0) {
            return _buildLoadingProgress();
          }
          final progress = _isDragging.value
              ? (_dragValue.value ?? 0.0)
              : position.inMilliseconds / duration.inMilliseconds;
          return Container(
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    color: Colors.white.withAlpha(128),
                  ),
                ),
                // Buffered progress
                if (widget.showBuffering)
                  _buildBufferedProgress(buffered, duration),
                // Chapter markers
                if (widget.chapters != null) _buildChapterMarkers(duration),
                // Progress track
                _buildProgressTrack(progress),
                // Interactive slider
                _buildInteractiveSlider(
                  controller,
                  progress,
                  duration,
                  position,
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBufferedProgress(
    List<DurationRange> buffered,
    Duration duration,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Stack(
          children: buffered.map((range) {
            final startPercent =
                range.start.inMilliseconds / duration.inMilliseconds;
            final endPercent =
                range.end.inMilliseconds / duration.inMilliseconds;
            final rangeWidth = (endPercent - startPercent) * width;

            return Positioned(
              left: startPercent * width,
              child: Container(
                width: rangeWidth,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: Colors.white.withAlpha(128),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChapterMarkers(Duration duration) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Stack(
          children: widget.chapters!.map((chapter) {
            final percent = chapter.inMilliseconds / duration.inMilliseconds;

            return Positioned(
              left: percent * width - 1,
              child: Container(
                width: 2,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: widget.config.accentColor,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProgressTrack(double progress) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            color: widget.config.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveSlider(
    ReelController controller,
    double progress,
    Duration duration,
    Duration position,
  ) {
    return Obx(() => SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 0,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: _isDragging.value ? 8.0 : 6.0,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: widget.config.accentColor,
            overlayColor: widget.config.accentColor.withAlpha(64),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              _isDragging.value = true;
              _dragValue.value = value;
            },
            onChangeStart: (value) {
              _isDragging.value = true;
              _dragValue.value = value;
              controller.pause();
            },
            onChangeEnd: (value) {
              final newPosition = Duration(
                milliseconds: (value * duration.inMilliseconds).round(),
              );
              controller.seekTo(newPosition);
              _isDragging.value = false;
              _dragValue.value = null;
              // Resume playback after seeking
              Future.delayed(const Duration(milliseconds: 100), () {
                if (controller.wasPlayingBeforeSeek) {
                  controller.play();
                }
              });
            },
          ),
        ));
  }

  Widget _buildLoadingProgress() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        color: Colors.white.withAlpha(128),
      ),
      child: LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.config.accentColor.withAlpha(64),
        ),
      ),
    );
  }
}

/// Circular progress indicator for reels
class CircularReelProgressIndicator extends StatelessWidget {
  final ReelModel reel;
  final ReelConfig config;
  final double size;
  final double strokeWidth;

  const CircularReelProgressIndicator({
    super.key,
    required this.reel,
    required this.config,
    this.size = 60.0,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReelController>();
    return Obx(() {
      final videoController = controller.currentVideoController;
      if (videoController == null) {
        return _buildLoadingIndicator();
      }
      return StreamBuilder<Duration>(
        stream: controller.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = videoController.value.duration;
          if (duration.inMilliseconds <= 0) {
            return _buildLoadingIndicator();
          }
          final progress = position.inMilliseconds / duration.inMilliseconds;
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withAlpha(128),
                  ),
                ),
                // Progress circle
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    config.accentColor,
                  ),
                ),
                // Center content
                Container(
                  width: size - (strokeWidth * 4),
                  height: size - (strokeWidth * 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  child: Icon(
                    controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                    color: config.textColor,
                    size: size * 0.4,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          config.accentColor.withAlpha(64),
        ),
      ),
    );
  }
}
