# Aqua Ad Widget Example

This example demonstrates how to use the Aqua Ad Widget library in a Flutter application.

## Features Demonstrated

- **Basic Ad Display**: Simple ad widget with zone ID
- **Carousel Mode**: Multiple ads with automatic progression
- **Progress Bar**: Visual progress indicator for ad transitions
- **Rounded Corners**: Custom border radius styling
- **Debug Mode**: Comprehensive debugging and testing interface
- **Global Configuration**: Setting up default values for the entire app

## Running the Example

1. Make sure you have Flutter installed
2. Navigate to the example directory:
   ```bash
   cd example
   ```
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Configuration

The example is configured to use a test ad server. In a real application, you would:

1. Set your own ad server URL using `AquaConfig.setDefaultBaseUrl()`
2. Configure your website location using `AquaConfig.setDefaultLocation()`
3. Use your actual zone IDs from your Revive AdServer

## Debug Features

Tap the bug icon in the app bar to access the debug page, which includes:

- Widget lifecycle monitoring
- Ad loading call tracking
- Locale switching
- Widget visibility toggling

This helps developers understand how the widget behaves in different scenarios.