import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';
import '../config/aqua_config.dart';

class AquaAdWidget extends StatefulWidget {
  final int zoneId;
  final double? width;
  final double? height;
  final String? baseUrl;
  final String? prefix;
  final String? location;
  
  const AquaAdWidget({
    super.key,
    required this.zoneId,
    this.width,
    this.height,
    this.baseUrl,
    this.prefix,
    this.location,
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
    // Cancella timer precedente
    _refreshTimer?.cancel();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final baseUrl = widget.baseUrl ?? AquaConfig.defaultBaseUrl;
      final prefix = widget.prefix ?? 'fanta-';
      final location = widget.location ?? AquaConfig.defaultLocation;
      
      if (location == null) {
        setState(() {
          _error = 'Location non configurata. Usa AquaConfig.setDefaultLocation()';
          _isLoading = false;
        });
        return;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl?zones=${widget.zoneId}|${widget.zoneId}&prefix=$prefix&loc=$location'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final zoneKey = '${prefix}0'; // Prima zona
        
        if (data.containsKey(zoneKey)) {
          final adData = data[zoneKey] as Map<String, dynamic>;
          final htmlContent = adData['html'] as String;
          
          // Controlla se è un video
          final videoMatch = RegExp(r'<source src=\"([^\"]+)\"').firstMatch(htmlContent);
          final imageMatch = RegExp(r"src='([^']+)'").firstMatch(htmlContent);
          // Per i video, cerca il link prima del tag video
          final linkMatch = videoMatch != null 
              ? RegExp(r'<a href=\"([^\"]+)\"').firstMatch(htmlContent)
              : RegExp(r"href='([^']+)'").firstMatch(htmlContent);
          
          if (videoMatch != null) {
            print('DEBUG - Video URL: ${videoMatch.group(1)}');
            print('DEBUG - Click URL: ${linkMatch?.group(1)}');
            
            final videoUrl = videoMatch.group(1)!;
            final viewType = 'video-${widget.zoneId}-${videoUrl.hashCode}';
            
            // Registra la view factory prima di usarla
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
                
                // Listener per quando il video finisce
                video.onEnded.listen((_) {
                  print('DEBUG - Video ended, reloading ad');
                  _loadAd();
                });
                
                return video;
              },
            );
            
            setState(() {
              _videoUrl = videoUrl;
              _clickUrl = linkMatch?.group(1);
              _isVideo = true;
              _viewType = viewType;
              _isLoading = false;
            });
          } else if (imageMatch != null) {
            print('DEBUG - Image URL: ${imageMatch.group(1)}');
            print('DEBUG - Click URL: ${linkMatch?.group(1)}');
            setState(() {
              _imageUrl = imageMatch.group(1);
              _clickUrl = linkMatch?.group(1);
              _isVideo = false;
              _isLoading = false;
            });
            
            // Timer per ricaricare l'immagine
            _refreshTimer?.cancel();
            _refreshTimer = Timer(Duration(seconds: AquaConfig.imageRefreshSeconds), () {
              print('DEBUG - Image timeout, reloading ad');
              _loadAd();
            });
          } else {
            setState(() {
              _error = 'Nessuna pubblicità disponibile';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _error = 'Zona pubblicitaria non trovata';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width ?? 300,
        height: widget.height ?? 250,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: widget.width ?? 300,
        height: widget.height ?? 250,
        child: Center(child: Text(_error!)),
      );
    }

    if (_isVideo && _videoUrl != null && _viewType != null) {
      return SizedBox(
        width: widget.width ?? 300,
        height: widget.height ?? 250,
        child: Stack(
          children: [
            HtmlElementView(viewType: _viewType!),
            if (_clickUrl != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    print('DEBUG - Clicking video, opening: $_clickUrl');
                    html.window.open(_clickUrl!, '_blank');
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  final video = html.document.querySelector('video[src="$_videoUrl"]') as html.VideoElement?;
                  if (video != null) {
                    video.muted = !video.muted;
                    setState(() {
                      _isMuted = video.muted;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(8),
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
      // Forza formato PNG per evitare problemi con SVG
      final imageUrl = _imageUrl!.contains('placehold.co') 
          ? '${_imageUrl!}.png' 
          : _imageUrl!;
      
      return GestureDetector(
        onTap: _clickUrl != null ? () {
          html.window.open(_clickUrl!, '_blank');
        } : null,
        child: SizedBox(
          width: widget.width ?? 300,
          height: widget.height ?? 250,
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

    return SizedBox(
      width: widget.width ?? 300,
      height: widget.height ?? 250,
      child: const Center(child: Text('Nessuna pubblicità disponibile')),
    );
  }
}