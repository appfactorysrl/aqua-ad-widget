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
  aqua_ad_widget: ^2.2.0
```

## Usage

```dart
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

// Configure image refresh interval (optional)
AquaConfig.setImageRefreshSeconds(15); // default: 10 seconds

// Configure global location (required)
AquaConfig.setDefaultLocation('https://mysite.com');

// Configure server URL (optional, default: http://servedby.aqua-adserver.com/asyncspc.php)
AquaConfig.setDefaultBaseUrl('https://myserver.com/asyncspc.php');

// Display an ad
AquaAdWidget(
  zoneId: 123,
  width: 300,
  height: 250,
  ratio: 16/9, // optional, default: 16/9
  autoGrow: false, // optional, default: false
  adCount: 1, // optional, default: 1
)

// Carousel with auto-detection
AquaAdWidget(
  zoneId: 123,
  adCount: 'auto', // loads up to 5 ads automatically
)
```

## Parameters

- `zoneId`: Numeric ID of the ad zone (required)
- `width`: Widget width (optional, default: 300)
- `height`: Widget height (optional, default: 250)
- `baseUrl`: Revive server base URL (optional, uses AquaConfig.setDefaultBaseUrl if not specified, default: http://servedby.aqua-adserver.com/asyncspc.php)
- `location`: Current page URL (optional, uses AquaConfig.setDefaultLocation if not specified)
- `ratio`: Aspect ratio for the widget (optional, default: 16/9). Used when width is specified or when taking 100% container width
- `autoGrow`: When true, uses the actual ad dimensions to set the aspect ratio (optional, default: false)
- `adCount`: Number of ads to load for carousel functionality (optional, default: 1). When > 1, displays ads in a carousel with dot navigation. Use 'auto' to automatically load up to 5 ads

## Supported Banner Types

Currently compatible with the following banner types:
- **Local Banner**: Standard image banners hosted locally
- **External Banner**: Image banners hosted on external servers
- **AdserverPlugins.com In-Banner Video**: Video advertisements with autoplay support

## Features

- **Image & Video Ads**: Automatically detects and displays both image and video advertisements
- **Auto-refresh**: Images refresh automatically after a configurable interval, videos reload when finished
- **Click Tracking**: Full click-through support with proper URL handling
- **Global Configuration**: Set default values once for the entire app
- **Cross-Platform**: Supports Android, iOS, and Web platforms
- **Web Optimized**: Built specifically for Flutter web with HTML video support
- **Audio Controls**: Video ads include mute/unmute button overlay

## Configuration

Configure global settings once in your app's main function:

```dart
void main() {
  // Required: Set the location for ad tracking
  AquaConfig.setDefaultLocation('https://mywebsite.com');
  
  // Optional: Customize refresh interval (default: 10 seconds)
  AquaConfig.setImageRefreshSeconds(15);
  
  // Optional: Set custom Revive server URL (default: http://servedby.aqua-adserver.com/asyncspc.php)
  AquaConfig.setDefaultBaseUrl('https://ads.myserver.com/asyncspc.php');
  
  runApp(MyApp());
}
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