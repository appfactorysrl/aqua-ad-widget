import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

void main() {
  group('AquaLocalizations', () {
    test('should provide English messages', () {
      final localizations = AquaLocalizations('en');
      
      expect(localizations.noAds, equals('No ads available'));
      expect(localizations.connectionError, equals('Connection error'));
      expect(localizations.locationNotConfigured, equals('Location not configured. Use AquaConfig.setDefaultLocation()'));
    });

    test('should provide Italian messages', () {
      final localizations = AquaLocalizations('it');
      
      expect(localizations.noAds, equals('Nessuna pubblicità disponibile'));
      expect(localizations.connectionError, equals('Errore di connessione'));
      expect(localizations.locationNotConfigured, equals('Location non configurata. Usa AquaConfig.setDefaultLocation()'));
    });

    test('should provide Spanish messages', () {
      final localizations = AquaLocalizations('es');
      
      expect(localizations.noAds, equals('No hay anuncios disponibles'));
      expect(localizations.connectionError, equals('Error de conexión'));
      expect(localizations.locationNotConfigured, equals('Ubicación no configurada. Usa AquaConfig.setDefaultLocation()'));
    });

    test('should provide French messages', () {
      final localizations = AquaLocalizations('fr');
      
      expect(localizations.noAds, equals('Aucune publicité disponible'));
      expect(localizations.connectionError, equals('Erreur de connexion'));
      expect(localizations.locationNotConfigured, equals('Emplacement non configuré. Utilisez AquaConfig.setDefaultLocation()'));
    });

    test('should provide German messages', () {
      final localizations = AquaLocalizations('de');
      
      expect(localizations.noAds, equals('Keine Werbung verfügbar'));
      expect(localizations.connectionError, equals('Verbindungsfehler'));
      expect(localizations.locationNotConfigured, equals('Standort nicht konfiguriert. Verwenden Sie AquaConfig.setDefaultLocation()'));
    });

    test('should fallback to English for unknown locale', () {
      final localizations = AquaLocalizations('unknown');
      
      expect(localizations.noAds, equals('No ads available'));
      expect(localizations.connectionError, equals('Connection error'));
      expect(localizations.locationNotConfigured, equals('Location not configured. Use AquaConfig.setDefaultLocation()'));
    });
  });
}