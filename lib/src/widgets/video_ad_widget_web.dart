import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:async';
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
  late bool _isMuted;
  web.HTMLVideoElement? _videoElement;
  late String _viewType;
  Timer? _progressTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuted;
    if (widget.isVisible) {
      _createVideoElement();
    }
  }

  @override
  void didUpdateWidget(VideoAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible && !_isInitialized) {
      _createVideoElement();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _disposeVideoElement();
    }
  }

  void _createVideoElement() {
    if (_isInitialized) return;
    
    _viewType =
        'video-${widget.videoUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _videoElement = web.HTMLVideoElement()
      ..src = widget.videoUrl
      ..muted = _isMuted
      ..loop = false;

    _videoElement!.style.width = '100%';
    _videoElement!.style.height = '100%';
    _videoElement!.style.objectFit = 'cover';
    if (widget.borderRadius != null) {
      _videoElement!.style.borderRadius = '${widget.borderRadius}px';
    }

    _videoElement!.onEnded.listen((_) {
      if (widget.isVisible) {
        widget.onVideoEnded?.call();
      }
    });

    _videoElement!.onLoadedData.listen((_) {
      if (widget.isVisible && mounted) {
        _videoElement!.play();
        _startProgressTracking();
        final duration = _videoElement!.duration.toInt();
        widget.onDurationAvailable?.call(duration);
        widget.onVideoStarted?.call();
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement!,
    );
    
    _isInitialized = true;
  }

  void _disposeVideoElement() {
    _progressTimer?.cancel();
    _videoElement?.pause();
    _videoElement?.remove();
    _videoElement = null;
    _isInitialized = false;
  }
  
  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!widget.isVisible || !mounted) {
        timer.cancel();
        return;
      }
      if (_videoElement != null && _videoElement!.duration > 0) {
        final progress = _videoElement!.currentTime / _videoElement!.duration;
        widget.onProgressChanged?.call(progress.clamp(0.0, 1.0));
      }
    });
  }
  
  @override
  void dispose() {
    _disposeVideoElement();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || !_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final child = Stack(
      children: [
        SizedBox.expand(
          child: HtmlElementView(
            key: ValueKey(_viewType),
            viewType: _viewType,
          ),
        ),
        if (widget.clickUrl != null)
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => launchURL(widget.clickUrl!),
                child: Container(color: Colors.transparent),
              ),
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
                widget.onMuteChanged?.call(_isMuted);
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

    return widget.borderRadius != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius!),
            child: child,
          )
        : child;
  }
}
