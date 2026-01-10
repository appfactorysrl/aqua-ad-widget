import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

void main() {
  group('AquaSettings', () {
    test('should create with all parameters', () {
      const settings = AquaSettings(
        adRefreshSeconds: 30,
        carouselAutoAdvance: false,
        baseUrl: 'https://custom.server.com/asyncspc.php',
        location: 'https://mysite.com',
        locale: 'es',
        hideIfEmpty: true,
        noFallbackWhenCarousel: false,
      );

      expect(settings.adRefreshSeconds, equals(30));
      expect(settings.carouselAutoAdvance, equals(false));
      expect(settings.baseUrl, equals('https://custom.server.com/asyncspc.php'));
      expect(settings.location, equals('https://mysite.com'));
      expect(settings.locale, equals('es'));
      expect(settings.hideIfEmpty, equals(true));
      expect(settings.noFallbackWhenCarousel, equals(false));
    });

    test('should create with default values', () {
      const settings = AquaSettings();

      expect(settings.adRefreshSeconds, isNull);
      expect(settings.carouselAutoAdvance, isNull);
      expect(settings.baseUrl, isNull);
      expect(settings.location, isNull);
      expect(settings.locale, isNull);
      expect(settings.hideIfEmpty, isNull);
      expect(settings.noFallbackWhenCarousel, isNull);
    });
  });
}