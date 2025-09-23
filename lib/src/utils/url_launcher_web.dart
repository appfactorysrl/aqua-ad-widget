import 'dart:js_interop';

@JS('window')
external JSObject get window;

@JS()
external void open(String url, String target);

Future<void> launchURL(String url) async {
  open(url, '_blank');
}