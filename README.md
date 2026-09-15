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
  aqua_ad_widget: ^5.2.1
```

### Web Setup (Required for HLS Video Support)

For Flutter Web projects, add HLS.js to your `web/index.html` to enable proper HLS video playback:

```html
<head>
  <!-- ... other head content ... -->
  
  <!-- HLS.js for video streaming support -->
  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
  
  <title>Your App</title>
</head>
```

This is **required** for HLS video ads (`.m3u8` files) to work correctly in Chrome and other browsers. Without it, videos may fail to play with codec errors.

### iOS Setup (App Transport Security)

Ad creatives (images and videos) are served from third-party domains, and some
are delivered over plain HTTP (the default ad server uses `http://`). iOS blocks
non-HTTPS network loads by default, which prevents assets from loading and can
make a video ad appear stuck (the widget keeps retrying without ever playing).

Add an App Transport Security exception to your app's `ios/Runner/Info.plist`.
Scope it to your ad domains where you can:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

The same applies to macOS (`macos/Runner/Info.plist`).

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

// Configure image caching (optional, default: true)
AquaConfig.setDefaultCacheAssets(true); // cache image ads on device

// Display an ad
AquaAdWidget(
  zoneId: 123,
  width: 528,
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
    cacheAssets: true, // override global image caching
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
- `onEmptyChanged`: Callback invoked when the widget's empty state changes (optional). Receives `true` when there is no ad to display and `false` when an ad is available. Useful for hiding surrounding layout when no ad is served
- `settings`: Custom settings for this widget instance (optional). Use `AquaSettings` to override global defaults for specific widgets
  - `adRefreshSeconds`: Override refresh interval
  - `carouselAutoAdvance`: Override carousel auto-advance
  - `baseUrl`: Override server URL
  - `location`: Override tracking location
  - `locale`: Override language ('en', 'it', 'es', 'fr', 'de')
  - `hideIfEmpty`: Override hide behavior when no ads available
  - `noFallbackWhenCarousel`: Override fallback filtering in carousels
  - `cacheAssets`: Override image caching for this widget instance (images only; videos always stream)

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
- **Image Caching**: Image ads are cached on device (memory + disk) and reused across refreshes; enabled by default and safe against remote changes
- **Progressive Video Streaming**: Video ads (including HLS) stream from the network and start playing as soon as enough has buffered

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
  
  // Optional: Enable debug logging (default: false)
  AquaConfig.setDebugMode(true);
  
  // Optional: Filter fallback ads from carousels (default: true)
  AquaConfig.setDefaultNoFallbackWhenCarousel(true);
  
  // Optional: Enable/disable image caching (default: true)
  AquaConfig.setDefaultCacheAssets(true);
  
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
  settings: AquaSettings(
    hideIfEmpty: true,
    noFallbackWhenCarousel: false, // Allow fallback ads in this carousel
  ),
)
```

## Reacting to Empty Ads

Use `onEmptyChanged` to know whether an ad is actually being shown, for example
to hide a surrounding container, title, or padding when no ad is served:

```dart
bool _adEmpty = true;

// ...

Column(
  children: [
    if (!_adEmpty) const Text('Sponsored'),
    AquaAdWidget(
      zoneId: 123,
      onEmptyChanged: (isEmpty) {
        setState(() => _adEmpty = isEmpty);
      },
    ),
  ],
)
```

The callback fires with `true` when the widget has no ad to display and `false`
once an ad is available, and only when the value changes. Combine it with
`hideIfEmpty: true` so the widget itself occupies no space while empty.

## Debug Mode

Enable debug logging to troubleshoot ad loading and video playback issues:

```dart
// Global configuration
AquaConfig.setDebugMode(true); // Enable debug logs

// Debug logs include:
// - Ad loading status and errors
// - Video playback events
// - Fallback ad detection
// - Carousel navigation events
// - Progress tracking information
```

## Fallback Ad Filtering

When the ad server returns ads from different zones (fallback ads), you can control their display in carousels:

```dart
// Global configuration - filter fallback ads from all carousels
AquaConfig.setDefaultNoFallbackWhenCarousel(true); // default

// Per-widget override - allow fallback ads in specific carousel
AquaAdWidget(
  zoneId: 123,
  adCount: 5,
  settings: AquaSettings(
    noFallbackWhenCarousel: false, // Show fallback ads in this carousel
  ),
)

// Behavior:
// - When true: Fallback ads are filtered out if non-fallback ads are available
// - When false: All ads (including fallbacks) are shown
// - Single ads are never filtered (only applies to carousels)
```

## Image Caching

Image ads are cached on the device so repeated impressions and refreshes reuse
already-downloaded bytes instead of hitting the network every time. Caching is
enabled by default.

This applies to image ads only. Video ads always stream from the network (see
the note below).

```dart
// Global configuration (default: true)
AquaConfig.setDefaultCacheAssets(true);

// Per-widget override
AquaAdWidget(
  zoneId: 123,
  settings: AquaSettings(
    cacheAssets: false, // disable caching for this widget only
  ),
)
```

How it works:

- **URL-keyed**: the cache key is the asset URL. The ad server serves a distinct,
  content-addressed URL for every creative version, so when a creative changes
  the URL changes too. That means the cache is always safe: a changed asset has
  a new key and is fetched fresh, and cached bytes are never served stale. No
  polling or revalidation of the server is performed.
- **Layered**: lookups resolve from an in-memory LRU, then an on-disk store, then
  the network. Newly fetched bytes populate both faster layers.
- **Cross-platform**: disk persistence is used on Android, iOS, macOS, Linux and
  Windows. On the web there is no filesystem, so caching operates in memory only
  for the session.
- **Bounded**: the in-memory layer is capped by entry count and total size and
  evicts least-recently-used assets automatically.

You can manage the cache programmatically:

```dart
await AssetCache.instance.clear();        // remove everything
await AssetCache.instance.evict(assetUrl); // remove a single asset
```

### Video Ads

Video ads (including HLS `.m3u8`) are **not cached**. They always stream from
the network and play progressively, starting as soon as enough has buffered.
The `cacheAssets` flag only affects image ads.

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