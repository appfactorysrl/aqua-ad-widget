import 'dart:js_interop';

@JS('window.open')
external void windowOpen(String url, String target);

Future<void> launchURL(String url) async {
  windowOpen(url, '_blank');
}
