import 'dart:html' as html;

Future<void> launchURL(String url) async {
  html.window.open(url, '_blank');
}