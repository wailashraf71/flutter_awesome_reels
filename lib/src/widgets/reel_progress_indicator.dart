import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  const ReelProgressIndicator({
    Key? key,
    required this.reel,
    required this.config,
    this.showThumb = false,
    this.showTime = false,
    this.height = 3.0,
  }) : super(key: key);

  @override
  State<ReelProgressIndicator> createState() => _ReelProgressIndicatorState();
}

class _ReelProgressIndicatorState extends State<ReelProgressIndicator> {
  bool _isDragging = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReelController>(
      builder: (context, controller, child) {
        final videoController = controller.currentVideoController;
        
        if (videoController == null) {
          return _buildLoadingProgress();
        }

        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = videoController.value.duration;
            
            if (duration.inMilliseconds <= 0) {
              return _buildLoadingProgress();
            }

            final progress = _isDragging 
                ? (_dragValue ?? 0.0)
                : position.inMilliseconds / duration.inMilliseconds;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
      },
    );
  }

  Widget _buildProgressBar(
    ReelController controller,
    double progress,
    Duration duration,
    Duration position,
  ) {
    if (widget.showThumb) {
      return _buildSliderProgress(controller, progress, duration, position);
    } else {
      return _buildLinearProgress(progress);
    }
  }

  Widget _buildLinearProgress(double progress) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        color: Colors.white.withOpacity(0.3),
      ),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.config.accentColor,
        ),
      ),
    );
  }

  Widget _buildSliderProgress(
    ReelController controller,
    double progress,
    Duration duration,
    Duration position,
  ) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: widget.height,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: _isDragging ? 8.0 : 6.0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
        activeTrackColor: widget.config.accentColor,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        thumbColor: widget.config.accentColor,
        overlayColor: widget.config.accentColor.withOpacity(0.2),
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChanged: (value) {
          setState(() {
            _isDragging = true;
            _dragValue = value;
          });
        },
        onChangeStart: (value) {
          setState(() {
            _isDragging = true;
            _dragValue = value;
          });
          controller.pause();
        },
        onChangeEnd: (value) {
          final newPosition = Duration(
            milliseconds: (value * duration.inMilliseconds).round(),
          );
          controller.seekTo(newPosition);
          
          setState(() {
            _isDragging = false;
            _dragValue = null;
          });
          
          // Resume playback after seeking
          Future.delayed(const Duration(milliseconds: 100), () {
            if (controller.wasPlayingBeforeSeek) {
              controller.play();
            }
          });
        },
      ),
    );
  }

  Widget _buildTimeIndicators(Duration position, Duration duration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          ReelUtils.formatDuration(position),
          style: TextStyle(
            color: widget.config.textColor.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          ReelUtils.formatDuration(duration),
          style: TextStyle(
            color: widget.config.textColor.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingProgress() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        color: Colors.white.withOpacity(0.3),
      ),
      child: LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.config.accentColor.withOpacity(0.5),
        ),
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
    Key? key,
    required this.reel,
    required this.config,
    this.chapters,
    this.showBuffering = true,
  }) : super(key: key);

  @override
  State<AdvancedReelProgressIndicator> createState() => 
      _AdvancedReelProgressIndicatorState();
}

class _AdvancedReelProgressIndicatorState 
    extends State<AdvancedReelProgressIndicator> {
  bool _isDragging = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReelController>(
      builder: (context, controller, child) {
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

            final progress = _isDragging 
                ? (_dragValue ?? 0.0)
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
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),

                  // Buffered progress
                  if (widget.showBuffering)
                    _buildBufferedProgress(buffered, duration),

                  // Chapter markers
                  if (widget.chapters != null)
                    _buildChapterMarkers(duration),

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
      },
    );
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
            final startPercent = range.start.inMilliseconds / duration.inMilliseconds;
            final endPercent = range.end.inMilliseconds / duration.inMilliseconds;
            final rangeWidth = (endPercent - startPercent) * width;
            
            return Positioned(
              left: startPercent * width,
              child: Container(
                width: rangeWidth,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: Colors.white.withOpacity(0.5),
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
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 0,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: _isDragging ? 8.0 : 6.0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: Colors.transparent,
        thumbColor: widget.config.accentColor,
        overlayColor: widget.config.accentColor.withOpacity(0.2),
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChanged: (value) {
          setState(() {
            _isDragging = true;
            _dragValue = value;
          });
        },
        onChangeStart: (value) {
          setState(() {
            _isDragging = true;
            _dragValue = value;
          });
          controller.pause();
        },
        onChangeEnd: (value) {
          final newPosition = Duration(
            milliseconds: (value * duration.inMilliseconds).round(),
          );
          controller.seekTo(newPosition);
          
          setState(() {
            _isDragging = false;
            _dragValue = null;
          });
          
          // Resume playback after seeking
          Future.delayed(const Duration(milliseconds: 100), () {
            if (controller.wasPlayingBeforeSeek) {
              controller.play();
            }
          });
        },
      ),
    );
  }

  Widget _buildLoadingProgress() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        color: Colors.white.withOpacity(0.3),
      ),
      child: LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.config.accentColor.withOpacity(0.5),
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
    Key? key,
    required this.reel,
    required this.config,
    this.size = 60.0,
    this.strokeWidth = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReelController>(
      builder: (context, controller, child) {
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
                      Colors.white.withOpacity(0.3),
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
                      controller.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: config.textColor,
                      size: size * 0.4,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          config.accentColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
