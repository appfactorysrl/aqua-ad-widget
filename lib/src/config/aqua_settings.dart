/// Settings class for individual AquaAdWidget configuration.
///
/// Use this class to override default values for specific widget instances.
class AquaSettings {
  /// The refresh interval for advertisements.
  ///
  /// Can be a positive integer representing seconds between refreshes,
  /// or false to disable auto-refresh. If null, uses global default.
  final dynamic adRefreshSeconds;

  /// Whether carousel should auto-advance.
  ///
  /// If null, uses global default.
  final bool? carouselAutoAdvance;

  /// The base URL for the Revive AdServer.
  ///
  /// If null, uses global default.
  final String? baseUrl;

  /// The current page URL for ad tracking.
  ///
  /// If null, uses global default.
  final String? location;

  /// The locale for error messages.
  ///
  /// If null, uses global default.
  final String? locale;

  /// Whether to hide the widget when no ads are available.
  ///
  /// If null, uses global default.
  final bool? hideIfEmpty;

  /// Whether to filter out fallback ads in carousel mode.
  ///
  /// If null, uses global default.
  final bool? noFallbackWhenCarousel;

  /// Creates an [AquaSettings] instance.
  const AquaSettings({
    this.adRefreshSeconds,
    this.carouselAutoAdvance,
    this.baseUrl,
    this.location,
    this.locale,
    this.hideIfEmpty,
    this.noFallbackWhenCarousel,
  });
}
