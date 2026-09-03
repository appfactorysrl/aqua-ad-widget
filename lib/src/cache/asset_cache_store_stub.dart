import 'dart:typed_data';

import 'asset_cache_store.dart';

/// Web (and any non-IO platform) implementation.
///
/// There is no filesystem available here, so persistence is a no-op and the
/// cache operates purely in memory (see [AssetCache]) for the app session.
class _NoopAssetCacheStore implements AssetCacheStore {
  @override
  Future<Uint8List?> read(String key) async => null;

  @override
  Future<void> write(String key, Uint8List bytes) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<String?> filePath(String key) async => null;

  @override
  Future<String?> downloadToFile(String key, String url) async => null;

  @override
  Future<String?> downloadHlsAsFile(String key, String manifestUrl) async =>
      null;
}

/// Creates the no-op store used on the web.
AssetCacheStore createStore() => _NoopAssetCacheStore();
