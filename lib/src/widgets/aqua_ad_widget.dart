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

  /// Whether to show the progress bar.
  ///
  /// If true, displays a progress bar at the bottom of the widget.
  /// Defaults to false.
  final bool showProgressBar;

  /// The color of the progress bar.
  ///
  /// Defaults to white.
  final Color progressBarColor;

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
    this.showProgressBar = false,
    this.progressBarColor = Colors.white,
  });

  @override
  State<AquaAdWidget> createState() => _AquaAdWidgetState();
}

class _AquaAdWidgetState extends State<AquaAdWidget> {
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  Timer? _preloadTimer;
  double? _adWidth;
  double? _adHeight;
  double? _currentRatio;
  double? _calculatedWidth;
  double? _calculatedHeight;

  List<Map<String, dynamic>> _ads = [];
  List<Map<String, dynamic>>? _preloadedAds;
  int _currentAdIndex = 0;
  int _videoKeyCounter = 0;
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  Timer? _videoFallbackTimer;
  late AquaLocalizations _localizations;
  int? _detectedAdCount;
  String? _currentLocale;
  bool _isLoadingAd = false;
  bool _hasError = false;

  // Progress bar
  double _progressValue = 0.0;
  Timer? _progressTimer;
  bool _isVideoControllingProgress = false;
  double _lastVideoProgress = 0.0;
  Timer? _videoProgressCheckTimer;

  // Mute state
  bool _isMuted = true;

  void _debugLog(String message) {
    if (AquaConfig.debugMode) {
      print(message);
    }
  }

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
    _debugLog('🗑️ Disposing widget - cancelling all timers');
    _refreshTimer?.cancel();
    _preloadTimer?.cancel();
    _carouselTimer?.cancel();
    _videoFallbackTimer?.cancel();
    _videoProgressCheckTimer?.cancel();
    _progressTimer?.cancel();
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
    _videoProgressCheckTimer?.cancel(); // Cancella anche il timer di controllo video
    
    // Incrementa il counter per invalidare tutti i video precedenti
    _videoKeyCounter++;

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

          // Parse beacon tracking pixel
          final beaconUrl = _parseBeaconFromHtml(htmlContent);
          // Beacon will be loaded when slide becomes visible

          if (videoMatch != null || imageMatch != null) {
            loadedAds.add({
              'html': htmlContent,
              'width': adData['width'],
              'height': adData['height'],
              'videoUrl': videoMatch?.group(1),
              'imageUrl': imageMatch?.group(1),
              'clickUrl': linkMatch?.group(1),
              'isVideo': videoMatch != null,
              'beaconUrl': beaconUrl,
              'isFallback': _checkIfFallback(linkMatch?.group(1)),
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

        // Filtra i fallback se richiesto e ci sono più ads
        final filteredAds = _filterFallbacksIfNeeded(adsToShow);

        // Se adCount è 'auto', memorizza il numero effettivo di annunci ricevuti
        if (widget.adCount == 'auto') {
          _detectedAdCount = filteredAds.length;
        }

        setState(() {
          _ads = filteredAds;
          _currentAdIndex = 0;
          _isLoading = false;
          _error = null;
          _progressValue = 0.0; // Reset progress bar
          _isVideoControllingProgress = false; // Reset controllo video
        });
        _isLoadingAd = false;

        // Reset PageController alla prima pagina se è un carousel
        if (filteredAds.length > 1 && _pageController.hasClients) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }

        if (filteredAds.length == 1) {
          final firstAd = filteredAds[0];
          if (!firstAd['isVideo']) {
            _startRefreshTimer();
          } else {
            // Per video singoli, avvia il controllo dopo che il widget è stato costruito
            _debugLog('🎬 Single video detected, will start progress check after build');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _ads.isNotEmpty && _ads[0]['isVideo']) {
                _debugLog('🎬 Starting progress check for single video after build (PostFrameCallback)');
                _startVideoProgressCheck();
              }
            });
          }
        } else if (filteredAds.length > 1 && (widget.settings?.carouselAutoAdvance ??
            AquaConfig.carouselAutoAdvance)) {
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
      if (mounted) {
        setState(() {
          _error = _localizations.connectionError;
          _isLoading = false;
        });
      }
      _isLoadingAd = false;
      // Non avviare timer in caso di errore
      return;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _preloadTimer?.cancel();
    _progressTimer?.cancel();

    // Non avviare timer se c'è un errore permanente
    if (_hasError) return;

    final refreshSeconds =
        widget.settings?.adRefreshSeconds ?? AquaConfig.adRefreshSeconds;
    if (refreshSeconds == false) return;

    final seconds = refreshSeconds is bool ? 10 : (refreshSeconds as int);

    // Avvia barra di progresso
    _startProgressBar(seconds);

    if (seconds <= 5) {
      // Se il refresh è troppo veloce, usa il metodo tradizionale
      _refreshTimer = Timer(Duration(seconds: seconds), () {
        if (!_hasError) {
          _loadAd();
        }
      });
      return;
    }

    // Calcola quando avviare il precaricamento per immagini
    final preloadDelay = seconds - 5;
    final preloadSeconds = preloadDelay > 0 ? preloadDelay : 1;

    // Avvia precaricamento
    _preloadTimer = Timer(Duration(seconds: preloadSeconds), () {
      if (!_hasError) {
        _preloadNextAd();
      }
    });

    // Timer principale per il cambio effettivo
    _refreshTimer = Timer(Duration(seconds: seconds), () {
      if (!_hasError) {
        _switchToPreloadedAd();
      }
    });
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _progressTimer?.cancel();
    if (_ads.isEmpty) return;

    final currentAd = _ads[_currentAdIndex];
    final refreshSeconds =
        widget.settings?.adRefreshSeconds ?? AquaConfig.adRefreshSeconds;
    
    // Per i video, avvia un timer di fallback in caso non si carichino
    if (currentAd['isVideo']) {
      // Reset progress bar per i video e lascia che il video la controlli
      if (widget.showProgressBar) {
        setState(() {
          _progressValue = 0.0;
          _isVideoControllingProgress = false; // Il video prenderà controllo quando inizia
        });
      }
      
      // Timer di fallback: se il video non si carica entro 5 secondi, passa al prossimo
      _debugLog('🎬 Video slide detected, progress check will start when video becomes visible');
      return;
    }
    
    // Per le immagini, usa le impostazioni di refresh
    final imageSeconds = refreshSeconds is bool ? 10 : refreshSeconds;

    // Reset e avvia barra di progresso per carousel
    if (widget.showProgressBar) {
      setState(() {
        _progressValue = 0.0;
      });
    }
    _startProgressBar(imageSeconds);

    _carouselTimer = Timer(Duration(seconds: imageSeconds), () {
      _nextSlide();
    });
  }

  void _nextSlide() {
    _debugLog('➡️ _nextSlide called, current index: $_currentAdIndex, total ads: ${_ads.length}');
    if (_ads.isEmpty) return;

    final nextIndex = (_currentAdIndex + 1) % _ads.length;
    
    // Se siamo arrivati alla fine del carousel, carica nuovi annunci
    if (_currentAdIndex == _ads.length - 1) {
      _debugLog('🔄 End of carousel reached, loading new ads');
      setState(() {
        _progressValue = 0.0; // Reset progress bar
      });
      // Cancella tutti i timer prima di caricare nuove ads
      _debugLog('🔄 End of carousel - cancelling all timers before loading new ads');
      _carouselTimer?.cancel();
      _videoFallbackTimer?.cancel();
      _videoProgressCheckTimer?.cancel();
      _progressTimer?.cancel();
      _loadAd();
      return;
    }
    
    _debugLog('📱 Moving to slide $nextIndex');
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _preloadNextAd() async {

    try {
      // ignore: deprecated_member_use_from_same_package
      final baseUrl = widget.settings?.baseUrl ??
          widget.baseUrl ??
          AquaConfig.defaultBaseUrl;
      // ignore: deprecated_member_use_from_same_package
      final location = widget.settings?.location ??
          widget.location ??
          AquaConfig.defaultLocation;

      if (location == null) return;

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

          // Parse beacon tracking pixel
          final beaconUrl = _parseBeaconFromHtml(htmlContent);
          // Beacon will be loaded when slide becomes visible

          if (videoMatch != null || imageMatch != null) {
            loadedAds.add({
              'html': htmlContent,
              'width': adData['width'],
              'height': adData['height'],
              'videoUrl': videoMatch?.group(1),
              'imageUrl': imageMatch?.group(1),
              'clickUrl': linkMatch?.group(1),
              'isVideo': videoMatch != null,
              'beaconUrl': beaconUrl,
              'isFallback': _checkIfFallback(linkMatch?.group(1)),
            });
          }
        }
      }

      if (loadedAds.isNotEmpty) {
        final adsToShow = widget.adCount == 'auto' && loadedAds.length > 5
            ? loadedAds.sublist(0, 5)
            : loadedAds;
        final filteredAds = _filterFallbacksIfNeeded(adsToShow);
        _preloadedAds = filteredAds;
      }
    } catch (e) {
      // Ignora errori di precaricamento
    }
  }

  void _switchToPreloadedAd() {
    if (_preloadedAds != null && _preloadedAds!.isNotEmpty) {
      setState(() {
        _ads = _preloadedAds!;
        _currentAdIndex = 0;
        _preloadedAds = null;
        _videoKeyCounter++;
        _progressValue = 0.0; // Reset progress bar
        _isVideoControllingProgress = false; // Reset controllo video
        // Non cambiare _isLoading per mantenere le dimensioni
      });

      // Reset PageController alla prima pagina se è un carousel
      if (_ads.length > 1 && _pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      if (_ads.length == 1) {
        final firstAd = _ads[0];
        if (!firstAd['isVideo']) {
          _debugLog('🖼️ Single image ad detected, starting refresh timer');
          _startRefreshTimer();
        } else {
          // Per video singoli precaricati, il controllo sarà avviato quando il video diventa visibile
          _debugLog('🎬 Single preloaded video detected, progress check will start when video becomes visible');
        }
      } else if (_ads.length > 1 && (widget.settings?.carouselAutoAdvance ??
          AquaConfig.carouselAutoAdvance)) {
        _debugLog('🎠 Multiple ads detected, starting carousel timer');
        _startCarouselTimer();
      }
    } else {
      // Fallback al caricamento tradizionale se il precaricamento fallisce
      _loadAd();
    }
  }

  void _startProgressBar(int totalSeconds) {
    if (!widget.showProgressBar) return;

    // Cancella timer esistente e prendi controllo della progress bar
    _progressTimer?.cancel();
    _isVideoControllingProgress = false;

    _debugLog('🔄 Starting progress bar for $totalSeconds seconds, resetting to 0.0');
    setState(() {
      _progressValue = 0.0;
    });

    const updateInterval = Duration(milliseconds: 100);
    final increment = 1.0 / (totalSeconds * 1000 / updateInterval.inMilliseconds);

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      // Solo aggiorna se non è un video a controllare la progress bar
      if (!_isVideoControllingProgress && mounted) {
        setState(() {
          _progressValue += increment;
          if (_progressValue >= 1.0) {
            _progressValue = 1.0;
            timer.cancel();
          }
        });
      } else {
        // Se un video ha preso controllo, ferma questo timer
        timer.cancel();
      }
    });
  }

  void _startVideoProgressCheck() {
    _debugLog('🔍 Starting video progress check (cancelling existing timer)');
    _videoProgressCheckTimer?.cancel();
    _lastVideoProgress = 0.0;
    double previousProgress = 0.0;
    
    // Controlla ogni 5 secondi se il video sta progredendo
    _videoProgressCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        _debugLog('🔍 Progress check cancelled - widget not mounted');
        timer.cancel();
        return;
      }
      
      _debugLog('🔍 Checking video progress: $_lastVideoProgress (previous: $previousProgress)');
      
      // Se il progresso è ancora 0 dopo 5 secondi, il video non si è caricato
      if (_lastVideoProgress == 0.0) {
        _debugLog('⚠️ Video not progressing, triggering fallback');
        timer.cancel();
        if (_ads.length > 1) {
          _nextSlide();
        } else {
          _loadAd();
        }
        return;
      }
      
      // Se il progresso non è cambiato rispetto al controllo precedente, il video è bloccato
      if (_lastVideoProgress == previousProgress && _lastVideoProgress < 0.95) {
        _debugLog('⚠️ Video stuck at ${(_lastVideoProgress * 100).toStringAsFixed(1)}%, triggering fallback');
        timer.cancel();
        if (_ads.length > 1) {
          _nextSlide();
        } else {
          _loadAd();
        }
        return;
      }
      
      // Aggiorna il progresso precedente per il prossimo controllo
      previousProgress = _lastVideoProgress;
    });
  }

  /// Filter fallback ads from carousel if needed
  List<Map<String, dynamic>> _filterFallbacksIfNeeded(List<Map<String, dynamic>> ads) {
    final noFallbackWhenCarousel = widget.settings?.noFallbackWhenCarousel ?? AquaConfig.noFallbackWhenCarousel;
    
    if (!noFallbackWhenCarousel || ads.length <= 1) {
      return ads;
    }
    
    final nonFallbackAds = ads.where((ad) => ad['isFallback'] != true).toList();
    
    if (nonFallbackAds.isNotEmpty) {
      final fallbackCount = ads.length - nonFallbackAds.length;
      if (fallbackCount > 0) {
        _debugLog('🚫 Filtered out $fallbackCount fallback ads from carousel');
      }
      return nonFallbackAds;
    }
    
    return ads;
  }

  /// Check if this is a fallback ad by comparing zone IDs
  bool _checkIfFallback(String? clickUrl) {
    if (clickUrl == null) return false;
    
    final zoneIdMatch = RegExp(r'zoneid=(\d+)').firstMatch(clickUrl);
    if (zoneIdMatch != null) {
      final returnedZoneId = int.tryParse(zoneIdMatch.group(1) ?? '');
      if (returnedZoneId != null && returnedZoneId != widget.zoneId) {
        _debugLog('🔄 Fallback ad detected: requested zone ${widget.zoneId}, got zone $returnedZoneId');
        return true;
      }
    }
    return false;
  }

  /// Parse beacon tracking pixel from HTML content
  String? _parseBeaconFromHtml(String htmlContent) {
    final patterns = [
      RegExp(r"<img[^>]*width='0'[^>]*height='0'[^>]*src='([^']+)'[^>]*>", caseSensitive: false),
      RegExp(r"<img[^>]*src='([^']*lg\.php[^']*)'[^>]*>", caseSensitive: false),
      RegExp(r"<img[^>]*src='([^']*beacon[^']*)'[^>]*>", caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(htmlContent);
      if (match != null) {
        final beaconUrl = match.group(1);
        if (beaconUrl != null) {
          return beaconUrl;
        }
      }
    }
    
    return null;
  }
  
  /// Load beacon tracking pixel using invisible image
  void _loadBeacon(String beaconUrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final overlay = Overlay.of(context);
        final entry = OverlayEntry(
          builder: (context) => Positioned(
            left: -1000,
            top: -1000,
            child: SizedBox(
              width: 1,
              height: 1,
              child: Image.network(
                beaconUrl,
                width: 1,
                height: 1,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
        overlay.insert(entry);
        
        Timer(const Duration(seconds: 5), () {
          entry.remove();
        });
      }
    });
  }

  Future<void> _handleClick(String url) async {
    await launchURL(url);
  }

  Widget _buildAdContent(Map<String, dynamic> ad, int index) {
    // Carica il beacon quando la slide diventa visibile
    if (ad['beaconUrl'] != null && _currentAdIndex == index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBeacon(ad['beaconUrl']);
      });
    }

    if (ad['isVideo'] && ad['videoUrl'] != null) {
      // Determina se questo video è visibile
      final isVisible = _currentAdIndex == index;
      
      return VideoAdWidget(
        key: ValueKey('${ad['videoUrl']}_$_videoKeyCounter'),
        videoUrl: ad['videoUrl'],
        clickUrl: ad['clickUrl'],
        initialMuted: _isMuted,
        isVisible: isVisible,
        onMuteChanged: (muted) {
          if (mounted) {
            setState(() {
              _isMuted = muted;
            });
          }
        },
        onDurationAvailable: _ads.length == 1 ? (duration) {
          // Usa la durata effettiva del video per il cambio automatico
          _refreshTimer?.cancel();
          _preloadTimer?.cancel();

          // Precarica immediatamente
          _preloadTimer = Timer(Duration(seconds: 1), () {
            if (!_hasError && !_isLoadingAd) {
              _preloadNextAd();
            }
          });

          // Timer principale per il cambio basato sulla durata del video
          _refreshTimer = Timer(Duration(seconds: duration + 1), () {
            if (!_hasError) {
              if (_preloadedAds != null && _preloadedAds!.isNotEmpty) {
                _switchToPreloadedAd();
              } else {
                _loadAd();
              }
            }
          });
        } : null,
        onVideoStarted: () {
          // Solo log e controllo per video visibili
          if (isVisible) {
            _debugLog('▶️ Video started: ${ad['videoUrl']} (index: $index, current: $_currentAdIndex)');
            if (_ads.length > 1) {
              _debugLog('  → Starting progress check for visible carousel video');
              _startVideoProgressCheck();
            } else {
              _debugLog('  → Single video started');
              _startVideoProgressCheck();
            }
          }
        },
        onVideoEnded: () {
          // Solo per video visibili
          if (isVisible) {
            _debugLog('⏹️ Video ended: ${ad['videoUrl']} - cancelling progress check timer');
            _videoProgressCheckTimer?.cancel();
            if (_ads.length > 1) {
              _debugLog('  → Moving to next slide');
              if (mounted) {
                _nextSlide();
              }
            } else {
              _debugLog('  → Single video ended');
            }
          }
        },
        borderRadius: widget.borderRadius,
        onProgressChanged: (progress) {
          // Solo per video visibili e con key corretta
          if (isVisible) {
            final currentVideoKey = '${_ads.isNotEmpty ? _ads[_currentAdIndex]['videoUrl'] : ''}_$_videoKeyCounter';
            final thisVideoKey = '${ad['videoUrl']}_$_videoKeyCounter';
            
            // Verifica che questo sia il video corrente
            if (_currentAdIndex == index && currentVideoKey == thisVideoKey) {
              _debugLog('📊 Video progress update: $progress (video: ${ad['videoUrl']}, index: $index)');
              _lastVideoProgress = progress;
              
              // Solo aggiorna la UI se la progress bar è abilitata
              if (widget.showProgressBar && mounted) {
                setState(() {
                  _isVideoControllingProgress = true;
                  _progressValue = progress;
                });
              }
            }
          }
        },
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
          return const SizedBox.shrink();
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
      final height = widget.height ?? (widget.width! / ratio);
      return SizedBox(
        width: widget.width,
        height: height,
        child: child,
      );
    }

    // Usa LayoutBuilder per catturare le dimensioni effettive
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite) {
          final width = constraints.maxWidth;
          final height = width / ratio;

          // Salva le dimensioni calcolate
          if (_calculatedWidth == null || _calculatedHeight == null) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _calculatedWidth = width;
                  _calculatedHeight = height;
                });
              }
            });
          }

          return SizedBox(
            width: width,
            height: height,
            child: child,
          );
        }

        // Fallback ad AspectRatio se non ci sono dimensioni finite
        return AspectRatio(
          aspectRatio: ratio,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hideIfEmpty = widget.settings?.hideIfEmpty ?? AquaConfig.hideIfEmpty;

    if (_isLoading && _ads.isEmpty) {
      if (hideIfEmpty) {
        return const SizedBox.shrink();
      }
      // Usa dimensioni salvate se disponibili per evitare collasso
      if (_calculatedWidth != null && _calculatedHeight != null) {
        return SizedBox(
          width: _calculatedWidth,
          height: _calculatedHeight,
          child: Container(
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return _buildSizedContainer(
        child: Container(
          color: Colors.white,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if ((_error != null || _hasError) && _ads.isEmpty) {
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
      final child = Stack(
        children: [
          _buildAdContent(_ads[0], 0),
          if (widget.showProgressBar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(widget.progressBarColor),
                minHeight: 2,
              ),
            ),
        ],
      );

      return _buildSizedContainer(
        child: widget.borderRadius != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius!),
                child: child,
              )
            : child,
      );
    }

    final child = Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentAdIndex = index;
              _progressValue = 0.0; // Reset progress bar
              _isVideoControllingProgress = false; // Reset controllo
            });
            
            // Cancella i timer esistenti
            _debugLog('🔄 Page changed to $index - cancelling all timers');
            _carouselTimer?.cancel();
            _videoFallbackTimer?.cancel();
            _videoProgressCheckTimer?.cancel();
            _progressTimer?.cancel();
            
            // Se la nuova slide è un video, avvia il controllo del progresso
            if (_ads[index]['isVideo']) {
              _debugLog('📱 Moved to video slide $index, starting progress check');
              _startVideoProgressCheck();
            }
            
            if (widget.settings?.carouselAutoAdvance ??
                AquaConfig.carouselAutoAdvance) {
              _startCarouselTimer();
            }
          },
          itemCount: _ads.length,
          itemBuilder: (context, index) {
            // Ricostruisce sempre il widget per aggiornare isVisible
            return _buildAdContent(_ads[index], index);
          },
        ),
        if (widget.showProgressBar)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(widget.progressBarColor),
              minHeight: 2,
            ),
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
    );

    return _buildSizedContainer(
      child: widget.borderRadius != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius!),
              child: child,
            )
          : child,
    );
  }
}
