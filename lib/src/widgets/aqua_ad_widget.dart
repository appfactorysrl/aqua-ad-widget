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
  final dynamic adCount;

  const AquaAdWidget({
    super.key,
    required this.zoneId,
    this.width,
    this.height,
    this.baseUrl,
    this.location,
    this.ratio = 16/9,
    this.autoGrow = false,
    this.adCount = 1,
  });

  @override
  State<AquaAdWidget> createState() => _AquaAdWidgetState();
}

class _AquaAdWidgetState extends State<AquaAdWidget> {
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  double? _adWidth;
  double? _adHeight;
  double? _currentRatio;

  List<Map<String, dynamic>> _ads = [];
  int _currentAdIndex = 0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
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

      final int requestCount = widget.adCount == 'auto' ? 5 : widget.adCount as int;
      final zones = List.filled(requestCount, widget.zoneId.toString()).join('|');
      final response = await http.get(
        Uri.parse('$baseUrl?zones=$zones&loc=$location'),
      );

      final List<Map<String, dynamic>> loadedAds = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        for (final adData in data) {
          final width = int.tryParse(adData['width'].toString()) ?? 0;
          final height = int.tryParse(adData['height'].toString()) ?? 0;

          if (width == 0 || height == 0) continue;

          final htmlContent = adData['html'] as String;

          final videoMatch = RegExp(r'<source src=\"([^\"]+)\"').firstMatch(htmlContent);
          final imageMatch = RegExp(r"src='([^']+)'").firstMatch(htmlContent);
          final linkMatch = videoMatch != null
              ? RegExp(r'<a href=\"([^\"]+)\"').firstMatch(htmlContent)
              : RegExp(r"href='([^']+)'").firstMatch(htmlContent);

          if (videoMatch != null || imageMatch != null) {
            loadedAds.add({
              'html': htmlContent,
              'width': adData['width'],
              'height': adData['height'],
              'videoUrl': videoMatch?.group(1),
              'imageUrl': imageMatch?.group(1),
              'clickUrl': linkMatch?.group(1),
              'isVideo': videoMatch != null,
            });
          }
        }
      }

      if (loadedAds.isNotEmpty) {
        if (widget.autoGrow && loadedAds[0]['width'] != null && loadedAds[0]['height'] != null) {
          _adWidth = double.tryParse(loadedAds[0]['width'].toString());
          _adHeight = double.tryParse(loadedAds[0]['height'].toString());
          if (_adWidth != null && _adHeight != null && _adHeight! > 0) {
            _currentRatio = _adWidth! / _adHeight!;
          }
        }

        setState(() {
          _ads = loadedAds;
          _currentAdIndex = 0;
          _isLoading = false;
        });

        if (loadedAds.length == 1) {
          _startRefreshTimer();
        }
      } else {
        setState(() {
          _error = 'Nessuna pubblicità disponibile';
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

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(Duration(seconds: AquaConfig.imageRefreshSeconds), () {
      _loadAd();
    });
  }

  String _getViewType(String videoUrl, int index) {
    return 'video-${widget.zoneId}-${videoUrl.hashCode}-$index';
  }

  void _setupWebVideo(String videoUrl, int index) {
    if (!kIsWeb) return;

    final viewType = _getViewType(videoUrl, index);

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
          if (widget.adCount == 1) {
            _loadAd();
          }
        });

        return video;
      },
    );
  }

  Future<void> _handleClick(String url) async {
    await launchURL(url);
  }

  Widget _buildAdContent(Map<String, dynamic> ad, int index) {
    if (kIsWeb && ad['isVideo'] && ad['videoUrl'] != null) {
      _setupWebVideo(ad['videoUrl'], index);
      final viewType = _getViewType(ad['videoUrl'], index);

      return Stack(
        children: [
          HtmlElementView(viewType: viewType),
          if (ad['clickUrl'] != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _handleClick(ad['clickUrl']),
                child: Container(color: Colors.transparent),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                if (kIsWeb) {
                  final video = html.document.querySelector('video[src="${ad['videoUrl']}"]') as html.VideoElement?;
                  if (video != null) {
                    video.muted = !video.muted;
                    setState(() {});
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.volume_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (ad['imageUrl'] != null) {
      final imageUrl = ad['imageUrl'].contains('placehold.co')
          ? '${ad['imageUrl']}.png'
          : ad['imageUrl'];

      return GestureDetector(
        onTap: ad['clickUrl'] != null ? () => _handleClick(ad['clickUrl']) : null,
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
      );
    }

    return const SizedBox.shrink();
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

    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_ads.length == 1) {
      return _buildSizedContainer(
        child: _buildAdContent(_ads[0], 0),
      );
    }

    return _buildSizedContainer(
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentAdIndex = index;
              });
            },
            itemCount: _ads.length,
            itemBuilder: (context, index) {
              return _buildAdContent(_ads[index], index);
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_ads.length, (index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentAdIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
