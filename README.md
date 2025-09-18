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
  aqua_ad_widget: ^1.0.1
```

## Usage

```dart
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

// Configure image refresh interval (optional)
AquaConfig.setImageRefreshSeconds(15); // default: 10 seconds

// Configure global location (required)
AquaConfig.setDefaultLocation('https://mysite.com');

// Configure server URL (optional)
AquaConfig.setDefaultBaseUrl('https://myserver.com/asyncspc.php');

// Display an ad
AquaAdWidget(
  zoneId: 123,
  width: 300,
  height: 250,
  ratio: 16/9, // optional, default: 16/9
  autoGrow: false, // optional, default: false
)
```

## Parameters

- `zoneId`: Numeric ID of the ad zone (required)
- `width`: Widget width (optional, default: 300)
- `height`: Widget height (optional, default: 250)
- `baseUrl`: Revive server base URL (optional, uses AquaConfig.setDefaultBaseUrl if not specified)
- `location`: Current page URL (optional, uses AquaConfig.setDefaultLocation if not specified)
- `ratio`: Aspect ratio for the widget (optional, default: 16/9). Used when width is specified or when taking 100% container width
- `autoGrow`: When true, uses the actual ad dimensions to set the aspect ratio (optional, default: false)

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
  
  // Optional: Set custom Revive server URL
  AquaConfig.setDefaultBaseUrl('https://ads.myserver.com/asyncspc.php');
  
  runApp(MyApp());
}
```

## License

MIT License - see [LICENSE](LICENSE) file for details.