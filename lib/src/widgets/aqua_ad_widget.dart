import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/aqua_config.dart';
import 'dart:html' as html if (dart.library.html) '';
import 'dart:ui_web' as ui_web if (dart.library.html) '';
import '../utils/url_launcher.dart';


class AquaAdWidget extends StatefulWidget {
  final int zoneId;
  final double? width;
  final double? height;
  final String? baseUrl;
  final String? location;
  final double ratio;
  final bool autoGrow;
  
  const AquaAdWidget({
    super.key,
    required this.zoneId,
    this.width,
    this.height,
    this.baseUrl,
    this.location,
    this.ratio = 16/9,
    this.autoGrow = false,
  });

  @override
  State<AquaAdWidget> createState() => _AquaAdWidgetState();
}

class _AquaAdWidgetState extends State<AquaAdWidget> {
  bool _isLoading = true;
  String? _clickUrl;
  String? _imageUrl;
  String? _videoUrl;
  bool _isVideo = false;
  bool _isMuted = true;
  String? _error;
  String? _viewType;
  Timer? _refreshTimer;
  double? _adWidth;
  double? _adHeight;
  double? _currentRatio;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAd() async {
    _refreshTimer?.cancel();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final baseUrl = widget.baseUrl ?? AquaConfig.defaultBaseUrl;
      final location = widget.location ?? AquaConfig.defaultLocation;
      
      if (location == null) {
        setState(() {
          _error = 'Location non configurata. Usa AquaConfig.setDefaultLocation()';
          _isLoading = false;
        });
        return;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl?zones=${widget.zoneId}&loc=$location'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        
        if (data.isNotEmpty) {
          final adData = data[0] as Map<String, dynamic>;
          final htmlContent = adData['html'] as String;
          
          if (widget.autoGrow) {
            final width = adData['width'];
            final height = adData['height'];
            if (width != null && height != null) {
              _adWidth = double.tryParse(width.toString());
              _adHeight = double.tryParse(height.toString());
              if (_adWidth != null && _adHeight != null && _adHeight! > 0) {
                _currentRatio = _adWidth! / _adHeight!;
              }
            }
          }
          
          final videoMatch = RegExp(r'<source src=\"([^\"]+)\"').firstMatch(htmlContent);
          final imageMatch = RegExp(r"src='([^']+)'").firstMatch(htmlContent);
          final linkMatch = videoMatch != null 
              ? RegExp(r'<a href=\"([^\"]+)\"').firstMatch(htmlContent)
              : RegExp(r"href='([^']+)'").firstMatch(htmlContent);
          
          if (kIsWeb && videoMatch != null) {
            await _setupWebVideo(videoMatch.group(1)!, linkMatch?.group(1));
          } else if (imageMatch != null) {
            _setupImage(imageMatch.group(1)!, linkMatch?.group(1));
          } else {
            setState(() {
              _error = null;
              _isLoading = false;
              _imageUrl = null;
              _videoUrl = null;
            });
          }
        } else {
          setState(() {
            _error = 'Nessuna pubblicità disponibile';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Errore nel caricamento della pubblicità';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Errore di connessione';
        _isLoading = false;
      });
    }
  }

  Future<void> _setupWebVideo(String videoUrl, String? clickUrl) async {
    if (!kIsWeb) return;
    
    final viewType = 'video-${widget.zoneId}-${videoUrl.hashCode}';
    
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final video = html.VideoElement()
            ..src = videoUrl
            ..autoplay = true
            ..muted = true
            ..loop = false
            ..controls = false
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover';
          
          video.onEnded.listen((_) {
            _loadAd();
          });
          
          return video;
        },
      );
    }
    
    setState(() {
      _videoUrl = videoUrl;
      _clickUrl = clickUrl;
      _isVideo = true;
      _viewType = viewType;
      _isLoading = false;
    });
  }

  void _setupImage(String imageUrl, String? clickUrl) {
    setState(() {
      _imageUrl = imageUrl;
      _clickUrl = clickUrl;
      _isVideo = false;
      _isLoading = false;
    });
    
    _refreshTimer?.cancel();
    _refreshTimer = Timer(Duration(seconds: AquaConfig.imageRefreshSeconds), () {
      _loadAd();
    });
  }

  Future<void> _handleClick(String url) async {
    await launchURL(url);
  }

  Widget _buildSizedContainer({required Widget child}) {
    final ratio = _currentRatio ?? widget.ratio;
    
    if (widget.width != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height ?? (widget.width! / ratio),
        child: child,
      );
    }
    
    return AspectRatio(
      aspectRatio: ratio,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSizedContainer(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildSizedContainer(
        child: Center(child: Text(_error!)),
      );
    }

    if (kIsWeb && _isVideo && _videoUrl != null && _viewType != null) {
      return _buildSizedContainer(
        child: Stack(
          children: [
            HtmlElementView(viewType: _viewType!),
            if (_clickUrl != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _handleClick(_clickUrl!),
                  child: Container(color: Colors.transparent),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  if (kIsWeb) {
                    final video = html.document.querySelector('video[src="$_videoUrl"]') as html.VideoElement?;
                    if (video != null) {
                      video.muted = !video.muted;
                      setState(() {
                        _isMuted = video.muted;
                      });
                    }
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
        ),
      );
    }
    
    if (_imageUrl != null) {
      final imageUrl = _imageUrl!.contains('placehold.co') 
          ? '${_imageUrl!}.png' 
          : _imageUrl!;
      
      return GestureDetector(
        onTap: _clickUrl != null ? () => _handleClick(_clickUrl!) : null,
        child: _buildSizedContainer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Text('Pubblicità', style: TextStyle(color: Colors.grey)),
                ),
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}