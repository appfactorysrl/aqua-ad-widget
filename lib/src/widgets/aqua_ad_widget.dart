import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/aqua_config.dart';
import '../config/aqua_settings.dart';
import '../utils/url_launcher.dart';
import '../localization/aqua_localizations.dart';
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
  @Deprecated('Use settings.baseUrl instead')
  final String? baseUrl;

  /// The current page URL for ad tracking.
  ///
  /// If not provided, uses the value set via [AquaConfig.setDefaultLocation].
  /// This parameter is required for proper ad tracking.
  @Deprecated('Use settings.location instead')
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

  /// Custom settings for this widget instance.
  ///
  /// If provided, these settings will override the global defaults
  /// set via [AquaConfig] for this specific widget.
  final AquaSettings? settings;

  /// The border radius for the widget corners.
  ///
  /// If provided, the widget will have rounded corners with the specified radius.
  /// Defaults to null (no rounded corners).
  final double? borderRadius;

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
    this.settings,
    this.borderRadius,
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
  Timer? _carouselTimer;
  late AquaLocalizations _localizations;
  int? _detectedAdCount;
  String? _currentLocale;
  bool _isLoadingAd = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Inizializza con locale di default, sarà aggiornato in didChangeDependencies
    final defaultLocale = widget.settings?.locale ?? AquaConfig.defaultLocale;
    _currentLocale = defaultLocale;
    _localizations = AquaLocalizations(defaultLocale);
    _loadAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeLocalization();
  }

  void _initializeLocalization() {
    final locale = widget.settings?.locale ?? 
                   (AquaConfig.defaultLocale != 'en' ? AquaConfig.defaultLocale : 
                   Localizations.localeOf(context).languageCode);
    
    // Solo reinizializza se il locale è cambiato
    if (_currentLocale != locale) {
      _currentLocale = locale;
      _localizations = AquaLocalizations(locale);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    // Previeni chiamate multiple simultanee
    if (_isLoadingAd) {
      return;
    }
    
    if (_hasError) {
      return;
    }
    
    _isLoadingAd = true;
    _refreshTimer?.cancel();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ignore: deprecated_member_use_from_same_package
      final baseUrl = widget.settings?.baseUrl ??
          widget.baseUrl ??
          AquaConfig.defaultBaseUrl;
      // ignore: deprecated_member_use_from_same_package
      final location = widget.settings?.location ??
          widget.location ??
          AquaConfig.defaultLocation;

      if (location == null) {
        setState(() {
          _error = _localizations.locationNotConfigured;
          _isLoading = false;
        });
        return;
      }

      final int requestCount = widget.adCount == 'auto'
          ? (_detectedAdCount ?? 5)
          : widget.adCount as int;
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

        // Limita a massimo 5 annunci se adCount è 'auto'
        final adsToShow = widget.adCount == 'auto' && loadedAds.length > 5
            ? loadedAds.sublist(0, 5)
            : loadedAds;

        // Se adCount è 'auto', memorizza il numero effettivo di annunci ricevuti
        if (widget.adCount == 'auto' && _detectedAdCount == null) {
          _detectedAdCount = adsToShow.length;
        }

        setState(() {
          _ads = adsToShow;
          _currentAdIndex = 0;
          _isLoading = false;
        });
        _isLoadingAd = false;

        if (adsToShow.length == 1) {
          final firstAd = adsToShow[0];
          if (!firstAd['isVideo']) {
            _startRefreshTimer();
          }
        } else if (widget.settings?.carouselAutoAdvance ??
            AquaConfig.carouselAutoAdvance) {
          _startCarouselTimer();
        }
      } else {
        setState(() {
          _error = _localizations.noAds;
          _isLoading = false;
        });
        _isLoadingAd = false;
        // Non avviare timer se non ci sono annunci
        return;
      }
    } catch (e) {
      setState(() {
        _error = _localizations.connectionError;
        _isLoading = false;
      });
      _isLoadingAd = false;
      // Non avviare timer in caso di errore
      return;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    
    // Non avviare timer se c'è un errore permanente
    if (_hasError) return;
    
    final refreshSeconds =
        widget.settings?.adRefreshSeconds ?? AquaConfig.adRefreshSeconds;
    if (refreshSeconds == false) return;
    
    final seconds = refreshSeconds is bool ? 10 : (refreshSeconds as int);
    if (seconds <= 0) return;
    
    _refreshTimer = Timer(Duration(seconds: seconds), () {
      if (!_hasError) {
        _loadAd();
      }
    });
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    if (_ads.isEmpty) return;

    final currentAd = _ads[_currentAdIndex];
    final refreshSeconds =
        widget.settings?.adRefreshSeconds ?? AquaConfig.adRefreshSeconds;
    final imageSeconds = refreshSeconds is bool ? 30 : refreshSeconds;
    final duration = currentAd['isVideo'] ? 30 : imageSeconds;

    _carouselTimer = Timer(Duration(seconds: duration), () {
      _nextSlide();
    });
  }

  void _nextSlide() {
    if (_ads.isEmpty) return;

    final nextIndex = (_currentAdIndex + 1) % _ads.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleClick(String url) async {
    await launchURL(url);
  }

  Widget _buildAdContent(Map<String, dynamic> ad, int index) {
    if (ad['isVideo'] && ad['videoUrl'] != null) {
      return VideoAdWidget(
        videoUrl: ad['videoUrl'],
        clickUrl: ad['clickUrl'],
        onVideoEnded: _ads.length == 1
            ? _loadAd
            : ((widget.settings?.carouselAutoAdvance ??
                    AquaConfig.carouselAutoAdvance)
                ? _nextSlide
                : null),
        borderRadius: widget.borderRadius,
      );
    }

    if (ad['imageUrl'] != null) {
      final imageUrl = ad['imageUrl'].contains('placehold.co')
          ? '${ad['imageUrl']}.png'
          : ad['imageUrl'];

      final imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Marca come errore permanente per evitare loop
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _error = 'Errore caricamento immagine';
              });
            }
          });
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Text(_localizations.advertisement, style: const TextStyle(color: Colors.grey)),
            ),
          );
        },
      );

      final clippedImage = widget.borderRadius != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius!),
              child: imageWidget,
            )
          : imageWidget;

      return MouseRegion(
        cursor: ad['clickUrl'] != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap:
              ad['clickUrl'] != null ? () => _handleClick(ad['clickUrl']) : null,
          child: clippedImage,
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
    final hideIfEmpty = widget.settings?.hideIfEmpty ?? AquaConfig.hideIfEmpty;

    if (_isLoading) {
      if (hideIfEmpty) {
        return const SizedBox.shrink();
      }
      return _buildSizedContainer(
        child: Container(
          color: Colors.white,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || _hasError) {
      if (hideIfEmpty) {
        return const SizedBox.shrink();
      }
      return _buildSizedContainer(
        child: Container(
          color: Colors.white,
          child: Center(child: Text(_error ?? 'Errore')),
        ),
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
              if (widget.settings?.carouselAutoAdvance ??
                  AquaConfig.carouselAutoAdvance) {
                _startCarouselTimer();
              }
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
