# Changelog

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