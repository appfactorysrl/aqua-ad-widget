import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/url_launcher.dart';

class VideoAdWidget extends StatefulWidget {
  final String videoUrl;
  final String? clickUrl;
  final VoidCallback? onVideoEnded;
  final double? borderRadius;

  const VideoAdWidget({
    super.key,
    required this.videoUrl,
    this.clickUrl,
    this.onVideoEnded,
    this.borderRadius,
  });

  @override
  State<VideoAdWidget> createState() => _VideoAdWidgetState();
}

class _VideoAdWidgetState extends State<VideoAdWidget> {
  late VideoPlayerController _controller;
  bool _isMuted = true;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.setVolume(0.0);
        _controller.play();
        _hasStarted = true;
      });

    _controller.addListener(_onVideoEnd);
  }

  void _onVideoEnd() {
    if (_hasStarted &&
        _controller.value.position >= _controller.value.duration) {
      widget.onVideoEnded?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoPlayer = _controller.value.isInitialized
        ? ClipRect(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());

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
              setState(() {
                _isMuted = !_isMuted;
                _controller.setVolume(_isMuted ? 0.0 : 1.0);
              });
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
