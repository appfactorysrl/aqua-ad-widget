import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/url_launcher.dart';

class VideoAdWidget extends StatefulWidget {
  final String videoUrl;
  final String? clickUrl;
  final VoidCallback? onVideoStarted;
  final VoidCallback? onVideoEnded;
  final double? borderRadius;
  final ValueChanged<double>? onProgressChanged;
  final ValueChanged<int>? onDurationAvailable;
  final bool initialMuted;
  final ValueChanged<bool>? onMuteChanged;
  final bool isVisible;

  const VideoAdWidget({
    super.key,
    required this.videoUrl,
    this.clickUrl,
    this.onVideoStarted,
    this.onVideoEnded,
    this.borderRadius,
    this.onProgressChanged,
    this.onDurationAvailable,
    this.initialMuted = true,
    this.onMuteChanged,
    this.isVisible = true,
  });

  @override
  State<VideoAdWidget> createState() => _VideoAdWidgetState();
}

class _VideoAdWidgetState extends State<VideoAdWidget> {
  VideoPlayerController? _controller;
  late bool _isMuted;
  bool _hasStarted = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuted;
    if (widget.isVisible) {
      _initializeController();
    }
  }

  @override
  void didUpdateWidget(VideoAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible && !_isInitialized) {
      _initializeController();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _disposeController();
    }
  }

  void _initializeController() {
    if (_isInitialized) return;
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (widget.isVisible && mounted) {
          setState(() {});
          _controller!.setVolume(_isMuted ? 0.0 : 1.0);
          _controller!.play();
          _hasStarted = true;
          final duration = _controller!.value.duration.inSeconds;
          widget.onDurationAvailable?.call(duration);
          widget.onVideoStarted?.call();
        }
      });

    _controller!.addListener(_onVideoEnd);
    _isInitialized = true;
  }

  void _disposeController() {
    _controller?.removeListener(_onVideoEnd);
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _hasStarted = false;
    _isInitialized = false;
  }

  void _onVideoEnd() {
    if (!widget.isVisible || _controller == null) return;
    
    if (_hasStarted &&
        _controller!.value.position >= _controller!.value.duration) {
      widget.onVideoEnded?.call();
    }
    
    // Aggiorna progresso solo se visibile
    if (_controller!.value.duration.inMilliseconds > 0) {
      final progress = _controller!.value.position.inMilliseconds / 
                      _controller!.value.duration.inMilliseconds;
      widget.onProgressChanged?.call(progress.clamp(0.0, 1.0));
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final videoPlayer = ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );

    final clippedVideo = widget.borderRadius != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius!),
            child: videoPlayer,
          )
        : videoPlayer;

    return Stack(
      children: [
        clippedVideo,
        if (widget.clickUrl != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => launchURL(widget.clickUrl!),
              child: Container(color: Colors.transparent),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              if (_controller != null) {
                setState(() {
                  _isMuted = !_isMuted;
                  _controller!.setVolume(_isMuted ? 0.0 : 1.0);
                  widget.onMuteChanged?.call(_isMuted);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
