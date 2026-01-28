@JS()
library;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import '../utils/url_launcher.dart';
import '../config/aqua_config.dart';

@JS('Hls')
external JSAny get Hls;

@JS('Hls.isSupported')
external JSFunction get hlsIsSupported;

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
  Object? _hls;

  void _debugLog(String message) {
    if (AquaConfig.debugMode) {
      // ignore: avoid_print
      print('[VideoAdWidget] $message');
    }
  }

  @override
  void initState() {
    super.initState();
    _debugLog('🎬 initState - videoUrl: ${widget.videoUrl}, isVisible: ${widget.isVisible}');
    _isMuted = widget.initialMuted;
    if (widget.isVisible) {
      _createVideoElement();
    }
  }

  @override
  void didUpdateWidget(VideoAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Solo logga se cambia effettivamente la visibilità
    if (oldWidget.isVisible != widget.isVisible) {
      _debugLog('🔄 didUpdateWidget - oldVisible: ${oldWidget.isVisible}, newVisible: ${widget.isVisible}, initialized: $_isInitialized');
      
      if (widget.isVisible && !oldWidget.isVisible) {
        _debugLog('  → Video becoming visible');
        if (!_isInitialized) {
          _debugLog('  → Creating video element');
          _createVideoElement();
        } else {
          _debugLog('  → Recreating video element to fix Chrome codec issues');
          _disposeVideoElement();
          _createVideoElement();
        }
      } else if (!widget.isVisible && oldWidget.isVisible) {
        _debugLog('  → Video becoming hidden, disposing');
        _disposeVideoElement();
      }
    }
  }

  void _createVideoElement() {
    if (_isInitialized) {
      _debugLog('⚠️ _createVideoElement called but already initialized');
      return;
    }
    
    // Aggiungi timestamp al viewType per garantire unicità assoluta
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _viewType = 'video-${widget.videoUrl.hashCode}-$timestamp';
    _debugLog('🎥 Creating video element - viewType: $_viewType');
    
    _videoElement = web.HTMLVideoElement()
      ..muted = _isMuted
      ..loop = false
      ..playsInline = true;

    _videoElement!.setAttribute('playsinline', '');
    _videoElement!.setAttribute('webkit-playsinline', '');
    _videoElement!.setAttribute('preload', 'metadata'); // Carica solo metadata inizialmente
    _videoElement!.style.width = '100%';
    _videoElement!.style.height = '100%';
    _videoElement!.style.objectFit = 'cover';
    if (widget.borderRadius != null) {
      _videoElement!.style.borderRadius = '${widget.borderRadius}px';
    }

    _videoElement!.onLoadedMetadata.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('📊 Video metadata loaded - duration: ${_videoElement!.duration}s');
    });

    _videoElement!.onCanPlay.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('✅ Video can play');
      if (widget.isVisible && mounted) {
        _debugLog('  → Auto-playing video');
        _videoElement!.play();
      }
    });

    _videoElement!.onPlay.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('▶️ Video play event fired');
    });

    _videoElement!.onPause.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('⏸️ Video pause event fired');
    });

    _videoElement!.onEnded.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('⏹️ Video ended event fired, isVisible: ${widget.isVisible}');
      if (widget.isVisible) {
        widget.onVideoEnded?.call();
      }
    });

    _videoElement!.onError.listen((event) {
      if (_videoElement == null || !mounted) return;
      final errorMsg = _videoElement?.error?.message ?? 'Unknown error';
      _debugLog('❌ Video error event: $errorMsg');
    });

    _videoElement!.onStalled.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('⚠️ Video stalled');
    });

    _videoElement!.onWaiting.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('⏳ Video waiting for data');
    });

    _videoElement!.onLoadedData.listen((_) {
      if (_videoElement == null || !mounted) return;
      _debugLog('📦 Video data loaded, isVisible: ${widget.isVisible}, mounted: $mounted');
      if (widget.isVisible && mounted) {
        _startProgressTracking();
        final duration = _videoElement!.duration.toInt();
        _debugLog('  → Video duration: ${duration}s');
        widget.onDurationAvailable?.call(duration);
        widget.onVideoStarted?.call();
      } else {
        _debugLog('  → Skipping callbacks (not visible or not mounted)');
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement!,
    );
    
    _isInitialized = true;
    _debugLog('✅ Video element created and registered');
    
    // Usa hls.js se disponibile e se è un file HLS
    final isHLS = widget.videoUrl.contains('.m3u8');
    if (isHLS) {
      try {
        final isSupported = js_util.callMethod(hlsIsSupported, 'call', []) as bool;
        if (isSupported) {
          _debugLog('🔗 Using HLS.js for: ${widget.videoUrl}');
          _hls = js_util.callConstructor(Hls, []);
          js_util.callMethod(_hls!, 'loadSource', [widget.videoUrl]);
          js_util.callMethod(_hls!, 'attachMedia', [_videoElement]);
        } else {
          _debugLog('🔗 HLS.js not supported, using native');
          _videoElement!.src = widget.videoUrl;
          _videoElement!.load();
        }
      } catch (e) {
        _debugLog('❌ HLS.js error: $e, falling back to native');
        _videoElement!.src = widget.videoUrl;
        _videoElement!.load();
      }
    } else {
      _debugLog('🔗 Using native video for: ${widget.videoUrl}');
      final srcWithTimestamp = widget.videoUrl.contains('?') 
          ? '${widget.videoUrl}&_t=$timestamp'
          : '${widget.videoUrl}?_t=$timestamp';
      _videoElement!.src = srcWithTimestamp;
      _videoElement!.load();
    }
  }

  void _disposeVideoElement() {
    _debugLog('🗑️ Disposing video element');
    _progressTimer?.cancel();
    
    // Distruggi hls.js se presente
    if (_hls != null) {
      try {
        js_util.callMethod(_hls!, 'destroy', []);
      } catch (e) {
        _debugLog('⚠️ Error destroying HLS: $e');
      }
      _hls = null;
    }
    
    if (_videoElement != null) {
      try {
        _videoElement!.pause();
        _videoElement!.src = '';
        _videoElement!.load();
        _videoElement!.remove();
      } catch (e) {
        _debugLog('⚠️ Error disposing video: $e');
      }
      _videoElement = null;
    }
    _isInitialized = false;
  }
  
  void _startProgressTracking() {
    _debugLog('📊 Starting progress tracking');
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!widget.isVisible || !mounted) {
        _debugLog('⏹️ Stopping progress tracking (not visible or not mounted)');
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
    _debugLog('🗑️ Widget dispose called');
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

    // Usa una key unica basata sul viewType per forzare ricreazione del widget
    final child = Stack(
      key: ValueKey(_viewType),
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
