import 'asset_cache_store.dart';

// Conditional import: on IO platforms (Android/iOS/desktop) we persist to disk;
// on the web there is no filesystem, so the store is a no-op and the cache
// operates in memory only.
import 'asset_cache_store_stub.dart'
    if (dart.library.io) 'asset_cache_store_io.dart';

/// Creates the platform-appropriate [AssetCacheStore].
///
/// Returns a disk-backed store on IO platforms and a no-op store on the web.
AssetCacheStore createAssetCacheStore() => createStore();
