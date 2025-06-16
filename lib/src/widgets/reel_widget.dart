import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../controllers/reel_controller.dart';
import '../models/reel_config.dart';

class ReelWidget extends StatefulWidget {
  final ReelController controller;
  final ReelConfig config;

  const ReelWidget({
    Key? key,
    required this.controller,
    required this.config,
  }) : super(key: key);

  @override
  State<ReelWidget> createState() => _ReelWidgetState();
}

class _ReelWidgetState extends State<ReelWidget> {
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _dragStartX = 0;
  Duration _dragStartPosition = Duration.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(widget.config.controlsAutoHideDuration!, () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _handleTap() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
    widget.controller.togglePlayPause();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartPosition = widget.controller.currentPosition.value;
    _isDragging = true;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.globalPosition.dx - _dragStartX;
    final duration = widget.controller.currentReel.value?.duration;
    if (duration == Duration.zero) return;

    final seekPercentage = delta / MediaQuery.of(context).size.width;
    final seekDuration = Duration(
      milliseconds: (_dragStartPosition.inMilliseconds +
              (duration!.inMilliseconds * seekPercentage))
          .round(),
    );

    // Clamp the seek duration between 0 and total duration
    final clampedDuration = Duration(
      milliseconds:
          seekDuration.inMilliseconds.clamp(0, duration.inMilliseconds),
    );

    widget.controller.seekTo(clampedDuration);
    widget.config.onSeek?.call(clampedDuration);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    final currentController = widget.controller.currentVideoController;
    if (currentController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _handleTap,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: Stack(
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: VideoPlayer(currentController),
            ),
          ),

          // Progress bar
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.config.progressBarPadding,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value:
                      widget.controller.currentPosition.value.inMilliseconds /
                          widget.controller.currentReel.value!.duration!
                              .inMilliseconds,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),

          // Controls overlay
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: IconButton(
                  icon: Icon(
                    widget.controller.isPlaying.value
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: widget.controller.togglePlayPause,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
