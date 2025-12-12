# Changelog

## 3.4.2

* Fix infinite loop caused by image loading errors
* Add permanent error state to prevent continuous reload attempts
* Improve error handling with SchedulerBinding for safe setState calls
* Add comprehensive protection against timer restarts on errors
* Remove debug print statements for production release
* Enhance stability when ads fail to load or display

## 3.4.1

* Fix infinite loop issue caused by didChangeDependencies cycles
* Fix context access error in initState() for locale detection
* Add protection against multiple simultaneous loadAd calls
* Improve locale caching to prevent unnecessary reinitializations
* Add early returns to prevent timer starts on errors
* Enhance error handling and debugging capabilities
* Add debug page for troubleshooting widget behavior

## 3.4.0

* Add multi-language support (English, Italian, Spanish, French, German)
* Add automatic locale detection from device/browser
* Add `hideIfEmpty` configuration to hide widget when no ads available
* Add `locale` parameter to AquaSettings for per-widget language override
* Add `setDefaultLocale()` and `setDefaultHideIfEmpty()` to AquaConfig
* Improve `adCount: 'auto'` to adapt to actual number of ads received
* Optimize auto mode to request only detected ad count after first load
* Add white background to loading and error states
* Export AquaLocalizations class for public use
* Fix single ad behavior in auto mode (no carousel, proper refresh)

## 3.3.2

* Maintenance release

## 3.3.1

* Fix borderRadius parameter support for mobile platforms (Android/iOS)
* Add missing borderRadius parameter to video_ad_widget_mobile.dart
* Ensure feature parity between web and mobile video implementations

## 3.3.0

* Add borderRadius parameter for rounded corners on ads
* Apply border radius directly to video and image elements for better Safari compatibility
* Update dependencies: http ^1.6.0, video_player ^2.10.1, flutter_lints ^6.0.0
* Fix library name deprecation warning
* Improve example app with dark gradient background and glass effect AppBar

## 3.2.0

* Add AquaSettings class for per-widget configuration
* Rename setImageRefreshSeconds to setDefaultAdRefreshSeconds with deprecation
* Rename setCarouselAutoAdvance to setDefaultCarouselAutoAdvance with deprecation
* Add ability to disable auto-refresh by setting adRefreshSeconds to false
* Move baseUrl and location parameters to AquaSettings with deprecation
* Improve API consistency with settings-based configuration
* Maintain backward compatibility with deprecated parameters

## 3.1.0

* Add configurable carousel auto-advance functionality
* Fix web video widget inspector errors with unique keys
* Add carousel timer management for automatic slide progression
* Improve video handling in carousel mode
* Perfect 160/160 pub.dev score with 100% documentation

## 3.0.1

* Fix conditional export logic for proper WASM compatibility
* Replace deprecated dart:html with package:web
* Improve code formatting and linting compliance
* Achieve perfect 160/160 pub.dev score

## 3.0.0

* **BREAKING**: WASM compatibility - conditional video widget implementation
* Add support for all Flutter platforms: macOS, Linux, Windows
* Web implementation uses HTML video elements (WASM compatible)
* Mobile/Desktop implementation uses video_player package
* Conditional exports prevent dart:io dependency on web platforms
* Full cross-platform support maintained

## 2.2.0

* **BREAKING**: Improve pub.dev score with comprehensive improvements
* Add complete dartdoc documentation for all public API elements
* Replace dart:html with dart:js_interop for WASM compatibility
* Fix all static analysis issues and formatting
* Resolve test compatibility issues
* Achieve full pub.dev scoring requirements

## 2.1.1

* Add documentation for finding server URL in Revive AdServer and Aqua Platform control panels
* Clarify default server URL configuration in README
* Improve setup instructions with step-by-step guide for URL discovery

## 2.1.0

* **MAJOR**: Replace dart:html with video_player for unified cross-platform video support
* Fix iOS build errors by removing web-only dependencies
* Unified video implementation works on Android, iOS, and Web
* Video ads now start muted with working mute/unmute toggle
* Video scaling improved with proper cover behavior and clipping
* Prevent premature video reload during initialization
* Simplified codebase with single video widget implementation

## 2.0.1

* Fix dart analyze issues
* Resolve undefined_identifier error
* Make _pageController final
* Replace deprecated withOpacity with withValues

## 2.0.0

* **BREAKING CHANGES**: Major feature release with new parameters
* Add `ratio` parameter for aspect ratio control (default: 16/9)
* Add `autoGrow` parameter to use actual ad dimensions for ratio
* Add `adCount` parameter for carousel functionality
* Support `adCount: 'auto'` mode to load up to 5 ads automatically
* Implement carousel with PageView and dot navigation
* Smart widget sizing: fixed width or full container width with ratio
* Filter invalid ads (width/height = 0) automatically
* Disable auto-refresh when carousel is active
* Preserve video auto-refresh on end behavior
* Update example app with comprehensive demonstrations
* Update documentation with all new parameters and usage examples

## 1.1.2

* Remove prefix parameter to simplify API
* Fix server response parsing (handle array format)
* Widget disappears completely when no ads available
* Improve error handling and user experience

## 1.1.1

* Fix mobile click handling with platform-specific URL launcher
* Add clean architecture for cross-platform URL handling
* Resolve compilation errors on all platforms
* Improve code organization with separate utility files

## 1.1.0

* Add Android and iOS platform support
* Refactor to single unified widget with conditional imports
* Add url_launcher dependency for mobile link handling
* Improve code maintainability with unified codebase

## 1.0.2

* Update README with English documentation
* Add Aqua Platform compatibility information
* Document supported banner types (Local, External, AdserverPlugins.com In-Banner Video)

## 1.0.1

* Change zoneId parameter from String to int
* Add global configuration for base URL (AquaConfig.setDefaultBaseUrl)
* Improve API consistency

## 1.0.0

* Initial release
* Support for Revive Adserver integration
* Image and video ad support
* Auto-refresh functionality
* Global configuration for refresh intervals and location
* Web platform support with click tracking