/// Global configuration class for Aqua Ad Widget settings.
///
/// Use this class to configure default values that will be used across
/// all [AquaAdWidget] instances in your application.
class AquaConfig {
  /// Private constructor to prevent instantiation.
  AquaConfig._();
  static int _imageRefreshSeconds = 10;
  static String? _defaultLocation;
  static String _defaultBaseUrl =
      'http://servedby.aqua-adserver.com/asyncspc.php';
  static bool _carouselAutoAdvance = true;

  /// Gets the current image refresh interval in seconds.
  static int get imageRefreshSeconds => _imageRefreshSeconds;

  /// Gets the default location URL used for ad tracking.
  static String? get defaultLocation => _defaultLocation;

  /// Gets the default base URL for the Revive AdServer.
  static String get defaultBaseUrl => _defaultBaseUrl;

  /// Gets whether carousel auto-advance is enabled.
  static bool get carouselAutoAdvance => _carouselAutoAdvance;

  /// Sets the refresh interval for image advertisements.
  ///
  /// [seconds] must be a positive integer representing the number of seconds
  /// between automatic ad refreshes. Default is 10 seconds.
  static void setImageRefreshSeconds(int seconds) {
    _imageRefreshSeconds = seconds;
  }

  /// Sets the default location URL for ad tracking.
  ///
  /// [location] should be the URL of your website or application.
  /// This is required for proper ad tracking and must be set before
  /// using [AquaAdWidget].
  static void setDefaultLocation(String location) {
    _defaultLocation = location;
  }

  /// Sets the default base URL for the Revive AdServer.
  ///
  /// [baseUrl] should be the full URL to your Revive AdServer's asyncspc.php endpoint.
  /// If not set, defaults to the Aqua Platform server.
  static void setDefaultBaseUrl(String baseUrl) {
    _defaultBaseUrl = baseUrl;
  }

  /// Sets whether carousel should auto-advance.
  ///
  /// [enabled] controls automatic slide advancement in carousels.
  /// Default is true.
  static void setCarouselAutoAdvance(bool enabled) {
    _carouselAutoAdvance = enabled;
  }
}
