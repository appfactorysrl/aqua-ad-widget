class AquaConfig {
  static int _imageRefreshSeconds = 10;
  static String? _defaultLocation;
  static String _defaultBaseUrl = 'http://servedby.aqua-adserver.com/asyncspc.php';
  
  static int get imageRefreshSeconds => _imageRefreshSeconds;
  static String? get defaultLocation => _defaultLocation;
  static String get defaultBaseUrl => _defaultBaseUrl;
  
  static void setImageRefreshSeconds(int seconds) {
    _imageRefreshSeconds = seconds;
  }
  
  static void setDefaultLocation(String location) {
    _defaultLocation = location;
  }
  
  static void setDefaultBaseUrl(String baseUrl) {
    _defaultBaseUrl = baseUrl;
  }
}