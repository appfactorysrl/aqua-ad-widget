class AquaConfig {
  static int _imageRefreshSeconds = 10;
  static String? _defaultLocation;
  
  static int get imageRefreshSeconds => _imageRefreshSeconds;
  static String? get defaultLocation => _defaultLocation;
  
  static void setImageRefreshSeconds(int seconds) {
    _imageRefreshSeconds = seconds;
  }
  
  static void setDefaultLocation(String location) {
    _defaultLocation = location;
  }
}