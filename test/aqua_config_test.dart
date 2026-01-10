import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

void main() {
  group('AquaConfig', () {
    test('should set and get default values', () {
      AquaConfig.setDefaultAdRefreshSeconds(20);
      expect(AquaConfig.adRefreshSeconds, equals(20));

      AquaConfig.setDefaultLocation('https://example.com');
      expect(AquaConfig.defaultLocation, equals('https://example.com'));

      AquaConfig.setDefaultBaseUrl('https://ads.example.com/asyncspc.php');
      expect(AquaConfig.defaultBaseUrl, equals('https://ads.example.com/asyncspc.php'));

      AquaConfig.setDefaultCarouselAutoAdvance(false);
      expect(AquaConfig.carouselAutoAdvance, equals(false));

      AquaConfig.setDefaultLocale('it');
      expect(AquaConfig.defaultLocale, equals('it'));

      AquaConfig.setDefaultHideIfEmpty(true);
      expect(AquaConfig.hideIfEmpty, equals(true));

      AquaConfig.setDebugMode(true);
      expect(AquaConfig.debugMode, equals(true));

      AquaConfig.setDefaultNoFallbackWhenCarousel(false);
      expect(AquaConfig.noFallbackWhenCarousel, equals(false));
    });

    test('should handle disabled refresh', () {
      AquaConfig.setDefaultAdRefreshSeconds(false);
      expect(AquaConfig.adRefreshSeconds, equals(false));
      expect(AquaConfig.imageRefreshSeconds, equals(10)); // fallback value
    });
  });
}