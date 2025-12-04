/// Localization support for Aqua Ad Widget messages.
class AquaLocalizations {
  final String languageCode;

  AquaLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'no_ads': 'No ads available',
      'connection_error': 'Connection error',
      'location_not_configured': 'Location not configured. Use AquaConfig.setDefaultLocation()',
      'advertisement': 'Advertisement',
    },
    'it': {
      'no_ads': 'Nessuna pubblicità disponibile',
      'connection_error': 'Errore di connessione',
      'location_not_configured': 'Location non configurata. Usa AquaConfig.setDefaultLocation()',
      'advertisement': 'Pubblicità',
    },
    'es': {
      'no_ads': 'No hay anuncios disponibles',
      'connection_error': 'Error de conexión',
      'location_not_configured': 'Ubicación no configurada. Usa AquaConfig.setDefaultLocation()',
      'advertisement': 'Publicidad',
    },
    'fr': {
      'no_ads': 'Aucune publicité disponible',
      'connection_error': 'Erreur de connexion',
      'location_not_configured': 'Emplacement non configuré. Utilisez AquaConfig.setDefaultLocation()',
      'advertisement': 'Publicité',
    },
    'de': {
      'no_ads': 'Keine Werbung verfügbar',
      'connection_error': 'Verbindungsfehler',
      'location_not_configured': 'Standort nicht konfiguriert. Verwenden Sie AquaConfig.setDefaultLocation()',
      'advertisement': 'Werbung',
    },
  };

  String get noAds => _localizedValues[languageCode]?['no_ads'] ?? _localizedValues['en']!['no_ads']!;
  String get connectionError => _localizedValues[languageCode]?['connection_error'] ?? _localizedValues['en']!['connection_error']!;
  String get locationNotConfigured => _localizedValues[languageCode]?['location_not_configured'] ?? _localizedValues['en']!['location_not_configured']!;
  String get advertisement => _localizedValues[languageCode]?['advertisement'] ?? _localizedValues['en']!['advertisement']!;
}
