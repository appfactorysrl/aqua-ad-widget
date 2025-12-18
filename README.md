# Aqua Ad Widget

[![Pub Version](https://img.shields.io/pub/v/aqua_ad_widget)](https://pub.dev/packages/aqua_ad_widget)
[![GitHub Issues](https://img.shields.io/github/issues/appfactorysrl/aqua-ad-widget)](https://github.com/appfactorysrl/aqua-ad-widget/issues)
[![GitHub Stars](https://img.shields.io/github/stars/appfactorysrl/aqua-ad-widget)](https://github.com/appfactorysrl/aqua-ad-widget)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter widget for Revive Adserver integration with support for image and video ads, auto-refresh, and click tracking.

Developed for compatibility with [Aqua Platform](https://www.aquaplatform.com) (cloud managed version of Revive AdServer) and should be compatible with standard Revive AdServer installations.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  aqua_ad_widget: ^4.0.0
```

## Usage

```dart
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

// Configure ad refresh interval (optional)
AquaConfig.setDefaultAdRefreshSeconds(15); // default: 10 seconds
// or disable auto-refresh
AquaConfig.setDefaultAdRefreshSeconds(false);

// Configure global location (required)
AquaConfig.setDefaultLocation('https://mysite.com');

// Configure server URL (optional, default: http://servedby.aqua-adserver.com/asyncspc.php)
AquaConfig.setDefaultBaseUrl('https://myserver.com/asyncspc.php');

// Configure locale (optional, default: auto-detect from device/browser)
AquaConfig.setDefaultLocale('en'); // 'en', 'it', 'es', 'fr', 'de'

// Configure hide behavior (optional, default: false)
AquaConfig.setDefaultHideIfEmpty(true); // hide widget when no ads available

// Display an ad
AquaAdWidget(
  zoneId: 123,
  width: 300,
  height: 250,
  ratio: 16/9, // optional, default: 16/9
  autoGrow: false, // optional, default: false
  adCount: 1, // optional, default: 1
  borderRadius: 12, // optional, rounded corners in pixels
  settings: AquaSettings(
    adRefreshSeconds: 20, // override global setting
    carouselAutoAdvance: false, // override global setting
    baseUrl: 'https://custom.server.com/asyncspc.php',
    location: 'https://mypage.com',
    locale: 'it', // override global locale
    hideIfEmpty: true, // override global hide behavior
  ),
)

// Carousel with auto-detection and rounded corners
AquaAdWidget(
  zoneId: 123,
  adCount: 'auto', // loads up to 5 ads automatically
  borderRadius: 20, // rounded corners
)

// Widget with progress bar
AquaAdWidget(
  zoneId: 123,
  showProgressBar: true, // show progress bar
  progressBarColor: Colors.blue, // custom color
)
```

## Parameters

- `zoneId`: Numeric ID of the ad zone (required)
- `width`: Widget width (optional, default: 300)
- `height`: Widget height (optional, default: 250)
- `baseUrl`: Revive server base URL (optional, uses AquaConfig.setDefaultBaseUrl if not specified, default: http://servedby.aqua-adserver.com/asyncspc.php) **[DEPRECATED: use settings.baseUrl]**
- `location`: Current page URL (optional, uses AquaConfig.setDefaultLocation if not specified) **[DEPRECATED: use settings.location]**
- `ratio`: Aspect ratio for the widget (optional, default: 16/9). Used when width is specified or when taking 100% container width
- `autoGrow`: When true, uses the actual ad dimensions to set the aspect ratio (optional, default: false)
- `adCount`: Number of ads to load for carousel functionality (optional, default: 1). When > 1, displays ads in a carousel with dot navigation. Use 'auto' to automatically load up to 5 ads
- `borderRadius`: Border radius for rounded corners in pixels (optional, default: null). Applies to both image and video ads
- `showProgressBar`: Whether to show the progress bar (optional, default: false). Displays a progress bar at the bottom of the widget
- `progressBarColor`: The color of the progress bar (optional, default: Colors.white). Customizable progress bar color
- `settings`: Custom settings for this widget instance (optional). Use `AquaSettings` to override global defaults for specific widgets
  - `adRefreshSeconds`: Override refresh interval
  - `carouselAutoAdvance`: Override carousel auto-advance
  - `baseUrl`: Override server URL
  - `location`: Override tracking location
  - `locale`: Override language ('en', 'it', 'es', 'fr', 'de')
  - `hideIfEmpty`: Override hide behavior when no ads available

## Supported Banner Types

Currently compatible with the following banner types:
- **Local Banner**: Standard image banners hosted locally
- **External Banner**: Image banners hosted on external servers
- **AdserverPlugins.com In-Banner Video**: Video advertisements with autoplay support

## Features

- **Image & Video Ads**: Automatically detects and displays both image and video advertisements
- **Auto-refresh**: Images refresh automatically after a configurable interval (can be disabled), videos reload when finished
- **Click Tracking**: Full click-through support with proper URL handling
- **Rounded Corners**: Optional border radius for modern UI design
- **Global Configuration**: Set default values once for the entire app
- **Cross-Platform**: Supports Android, iOS, Web, macOS, Linux, and Windows platforms
- **Web Optimized**: Built specifically for Flutter web with HTML video support
- **Audio Controls**: Video ads include mute/unmute button overlay
- **Carousel Auto-Advance**: Configurable automatic slide progression in carousels
- **Multi-Language Support**: Automatic locale detection with support for 5 languages (EN, IT, ES, FR, DE)
- **Hide When Empty**: Optional configuration to hide widget completely when no ads available

## Configuration

Configure global settings once in your app's main function:

```dart
void main() {
  // Required: Set the location for ad tracking
  AquaConfig.setDefaultLocation('https://mywebsite.com');
  
  // Optional: Customize refresh interval (default: 10 seconds)
  AquaConfig.setDefaultAdRefreshSeconds(15);
  
  // Optional: Disable auto-refresh
  // AquaConfig.setDefaultAdRefreshSeconds(false);
  
  // Optional: Set custom Revive server URL (default: http://servedby.aqua-adserver.com/asyncspc.php)
  AquaConfig.setDefaultBaseUrl('https://ads.myserver.com/asyncspc.php');
  
  // Optional: Enable/disable carousel auto-advance (default: true)
  AquaConfig.setDefaultCarouselAutoAdvance(true);
  
  // Optional: Set default locale (default: auto-detect from device/browser)
  AquaConfig.setDefaultLocale('en'); // Supported: 'en', 'it', 'es', 'fr', 'de'
  
  // Optional: Hide widget when no ads available (default: false)
  AquaConfig.setDefaultHideIfEmpty(true);
  
  runApp(MyApp());
}
```

## Localization

The widget automatically detects the device/browser language and displays error messages in the appropriate language. Supported languages:

- **English** (en) - default
- **Italian** (it)
- **Spanish** (es)
- **French** (fr)
- **German** (de)

You can override the language globally or per widget:

```dart
// Global configuration
AquaConfig.setDefaultLocale('it');

// Per-widget override
AquaAdWidget(
  zoneId: 123,
  settings: AquaSettings(locale: 'es'),
)
```

## Hide When Empty

By default, the widget shows a white background during loading and when no ads are available. You can configure it to hide completely (no space occupied):

```dart
// Global configuration
AquaConfig.setDefaultHideIfEmpty(true);

// Per-widget override
AquaAdWidget(
  zoneId: 123,
  settings: AquaSettings(hideIfEmpty: true),
)
```

### Finding Your Server URL

To find your specific server URL:

**Aqua Platform Users:**
1. Log into your Aqua Platform dashboard
2. Go to "Inventory" → "Zones"
3. Click on any zone and select "Get Tag"
4. In the generated HTML code, look for the URL in the script src attribute (e.g., `src="https://yoursite.aqua-adserver.com/asyncspc.php"`)

**Revive AdServer Users:**
1. Log into your Revive AdServer admin panel
2. Navigate to "Inventory" → "Zones"
3. Select a zone and click "Zone Tags"
4. Choose "Asynchronous JS Tag" and copy the URL from the generated code

Use this URL with `AquaConfig.setDefaultBaseUrl()` in your Flutter app.

## License

MIT License - see [LICENSE](LICENSE) file for details.