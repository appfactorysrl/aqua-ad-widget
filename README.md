# Aqua Ad Widget

Gestore di pubblicità per progetti Flutter web e mobile.

## Installazione

Aggiungi al tuo `pubspec.yaml`:

```yaml
dependencies:
  aqua_ad_widget: ^1.0.0
```

## Utilizzo

```dart
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

// Configura il refresh delle immagini (opzionale)
AquaConfig.setImageRefreshSeconds(15); // default: 10 secondi

// Configura la location globale (obbligatorio)
AquaConfig.setDefaultLocation('https://mysite.com');

// Configura l'URL del server (opzionale)
AquaConfig.setDefaultBaseUrl('https://myserver.com/asyncspc.php');

// Mostra una pubblicità
AquaAdWidget(
  zoneId: 123,
  width: 300,
  height: 250,
)
```

## Parametri

- `zoneId`: ID numerico della zona pubblicitaria (obbligatorio)
- `width`: Larghezza del widget (opzionale, default: 300)
- `height`: Altezza del widget (opzionale, default: 250)
- `baseUrl`: URL base del server Revive (opzionale, se non specificato usa AquaConfig.setDefaultBaseUrl)
- `prefix`: Prefisso per le zone (opzionale, default: 'fanta-')
- `location`: URL della pagina corrente (opzionale, se non specificato usa AquaConfig.setDefaultLocation)