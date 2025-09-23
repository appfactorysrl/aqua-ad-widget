import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import '../utils/url_launcher.dart';

class VideoAdWidget extends StatefulWidget {
  final String videoUrl;
  final String? clickUrl;
  final VoidCallback? onVideoEnded;

  const VideoAdWidget({
    super.key,
    required this.videoUrl,
    this.clickUrl,
    this.onVideoEnded,
  });

  @override
  State<VideoAdWidget> createState() => _VideoAdWidgetState();
}

class _VideoAdWidgetState extends State<VideoAdWidget> {
  bool _isMuted = true;
  web.HTMLVideoElement? _videoElement;
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _createVideoElement();
  }

  void _createVideoElement() {
    _viewType =
        'video-${widget.videoUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _videoElement = web.HTMLVideoElement()
      ..src = widget.videoUrl
      ..muted = true
      ..loop = false;

    _videoElement!.style.width = '100%';
    _videoElement!.style.height = '100%';
    _videoElement!.style.objectFit = 'cover';

    _videoElement!.onEnded.listen((_) {
      widget.onVideoEnded?.call();
    });

    _videoElement!.onLoadedData.listen((_) {
      _videoElement!.play();
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: HtmlElementView(
            key: ValueKey(_viewType),
            viewType: _viewType,
          ),
        ),
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
                _videoElement?.muted = _isMuted;
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
