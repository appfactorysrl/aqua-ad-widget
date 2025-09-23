import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/aqua_config.dart';
import '../utils/url_launcher.dart';
import 'video_ad_widget.dart';

/// A Flutter widget that displays advertisements from Revive AdServer or Aqua Platform.
///
/// This widget supports both image and video advertisements with automatic refresh,
/// click tracking, and carousel functionality for multiple ads.
///
/// Example usage:
/// ```dart
/// AquaAdWidget(
///   zoneId: 123,
///   width: 300,
///   height: 250,
/// )
/// ```
class AquaAdWidget extends StatefulWidget {
  /// The numeric ID of the ad zone from your Revive AdServer.
  final int zoneId;

  /// The width of the widget in pixels.
  ///
  /// If not specified, the widget will take the full width of its container
  /// and use the [ratio] to determine height.
  final double? width;

  /// The height of the widget in pixels.
  ///
  /// If not specified and [width] is provided, height will be calculated
  /// using the [ratio]. If neither are specified, [ratio] determines the aspect ratio.
  final double? height;

  /// The base URL for the Revive AdServer.
  ///
  /// If not provided, uses the value set via [AquaConfig.setDefaultBaseUrl].
  /// Defaults to the Aqua Platform server if not configured.
  final String? baseUrl;

  /// The current page URL for ad tracking.
  ///
  /// If not provided, uses the value set via [AquaConfig.setDefaultLocation].
  /// This parameter is required for proper ad tracking.
  final String? location;

  /// The aspect ratio for the widget.
  ///
  /// Used when [width] is specified or when taking full container width.
  /// Defaults to 16/9.
  final double ratio;

  /// Whether to use the actual ad dimensions to set the aspect ratio.
  ///
  /// When true, the widget will use the dimensions from the first loaded ad
  /// to determine its aspect ratio, overriding the [ratio] parameter.
  /// Defaults to false.
  final bool autoGrow;

  /// The number of ads to load for carousel functionality.
  ///
  /// Can be an integer (1 or more) or the string 'auto' to automatically
  /// load up to 5 ads. When greater than 1, displays ads in a carousel
  /// with dot navigation. Defaults to 1.
  final dynamic adCount;

  /// Creates an [AquaAdWidget].
  ///
  /// The [zoneId] parameter is required and must correspond to a valid
  /// zone ID in your Revive AdServer configuration.
  const AquaAdWidget({
    super.key,
    required this.zoneId,
    this.width,
    this.height,
    this.baseUrl,
    this.location,
    this.ratio = 16 / 9,
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
  final PageController _pageController = PageController();

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
          _error =
              'Location non configurata. Usa AquaConfig.setDefaultLocation()';
          _isLoading = false;
        });
        return;
      }

      final int requestCount =
          widget.adCount == 'auto' ? 5 : widget.adCount as int;
      final zones =
          List.filled(requestCount, widget.zoneId.toString()).join('|');
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

          final videoMatch =
              RegExp(r'<source src=\"([^\"]+)\"').firstMatch(htmlContent);
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
        if (widget.autoGrow &&
            loadedAds[0]['width'] != null &&
            loadedAds[0]['height'] != null) {
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
          final firstAd = loadedAds[0];
          if (!firstAd['isVideo']) {
            _startRefreshTimer();
          }
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
    _refreshTimer =
        Timer(Duration(seconds: AquaConfig.imageRefreshSeconds), () {
      _loadAd();
    });
  }

  Future<void> _handleClick(String url) async {
    await launchURL(url);
  }

  Widget _buildAdContent(Map<String, dynamic> ad, int index) {
    if (ad['isVideo'] && ad['videoUrl'] != null) {
      return VideoAdWidget(
        videoUrl: ad['videoUrl'],
        clickUrl: ad['clickUrl'],
        onVideoEnded: _ads.length == 1 ? _loadAd : null,
      );
    }

    if (ad['imageUrl'] != null) {
      final imageUrl = ad['imageUrl'].contains('placehold.co')
          ? '${ad['imageUrl']}.png'
          : ad['imageUrl'];

      return GestureDetector(
        onTap:
            ad['clickUrl'] != null ? () => _handleClick(ad['clickUrl']) : null,
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
                          : Colors.white.withValues(alpha: 0.5),
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
