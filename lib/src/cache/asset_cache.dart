import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'asset_cache_store.dart';
import 'asset_cache_store_factory.dart';

/// URL-keyed cache for advertisement image assets.
///
/// The ad server serves a distinct, content-addressed URL for every creative
/// version, so a URL uniquely identifies an immutable asset. That means the
/// cache never has to revalidate or expire entries for correctness: when the
/// creative changes, its URL changes and a fresh entry is created. Entries are
/// only evicted to bound resource usage (memory and disk).
///
/// Lookups resolve in three layers, fastest first:
/// 1. an in-memory LRU map of decoded byte buffers;
/// 2. the persistent [AssetCacheStore] (disk on IO platforms, no-op on web);
/// 3. the network, after which the bytes are written back to both layers.
///
/// Concurrent requests for the same URL share a single in-flight fetch.
///
/// Images are cached in memory and on disk. Videos are also cached on disk as
/// a single file: plain videos are stored as-is, and HLS streams are downloaded
/// and concatenated into one playable file. Either way, a cache hit is played
/// directly from the local file.
class AssetCache {
  AssetCache._();

  /// The shared cache instance used by the package.
  static final AssetCache instance = AssetCache._();

  /// Maximum number of assets kept in the in-memory LRU.
  static const int _maxMemoryEntries = 30;

  /// Maximum total bytes kept in the in-memory LRU (~40 MB).
  static const int _maxMemoryBytes = 40 * 1024 * 1024;

  final AssetCacheStore _store = createAssetCacheStore();

  // Insertion-ordered map used as an LRU: most-recently-used entries are moved
  // to the end, so the eviction candidate is always the first key.
  final LinkedHashMap<String, Uint8List> _memory =
      LinkedHashMap<String, Uint8List>();
  int _memoryBytes = 0;

  // De-duplicates concurrent fetches for the same URL.
  final Map<String, Future<Uint8List>> _inFlight = {};

  // De-duplicate concurrent background video / HLS downloads by URL.
  final Map<String, Future<String?>> _videoDownloads = {};
  final Map<String, Future<String?>> _hlsDownloads = {};

  /// Returns the bytes for [url], loading from memory, disk, or network as
  /// needed and populating the faster layers on the way back.
  ///
  /// Throws if the asset cannot be obtained from any layer.
  Future<Uint8List> getBytes(String url) {
    final cached = _readMemory(url);
    if (cached != null) return Future.value(cached);
    return _inFlight[url] ??= _load(url).whenComplete(() {
      _inFlight.remove(url);
    });
  }

  Future<Uint8List> _load(String url) async {
    // Disk layer.
    final fromStore = await _store.read(url);
    if (fromStore != null) {
      _writeMemory(url, fromStore);
      return fromStore;
    }

    // Network layer.
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load asset ($url): HTTP ${response.statusCode}',
        Uri.parse(url),
      );
    }
    final bytes = response.bodyBytes;
    _writeMemory(url, bytes);
    // Persist without blocking the caller.
    unawaited(_store.write(url, bytes));
    return bytes;
  }

  Uint8List? _readMemory(String url) {
    final bytes = _memory.remove(url);
    if (bytes == null) return null;
    // Re-insert to mark as most-recently-used.
    _memory[url] = bytes;
    return bytes;
  }

  void _writeMemory(String url, Uint8List bytes) {
    final existing = _memory.remove(url);
    if (existing != null) _memoryBytes -= existing.lengthInBytes;

    _memory[url] = bytes;
    _memoryBytes += bytes.lengthInBytes;

    // Evict least-recently-used entries until within both bounds.
    while (_memory.length > _maxMemoryEntries ||
        (_memoryBytes > _maxMemoryBytes && _memory.length > 1)) {
      final oldestKey = _memory.keys.first;
      final removed = _memory.remove(oldestKey);
      if (removed != null) _memoryBytes -= removed.lengthInBytes;
    }
  }

  // --- Single-file video caching -----------------------------------------

  /// Returns the local file path of a fully cached single-file video for [url],
  /// or `null` if it is not cached (or the platform has no filesystem).
  ///
  /// The video is played directly from this file by the platform video player.
  Future<String?> videoFile(String url) => _store.filePath(url);

  /// Downloads the video at [url] into the persistent cache in the background,
  /// without blocking playback. Safe to call on every miss: concurrent and
  /// repeated calls for the same URL share a single download, and the file is
  /// written atomically so it only becomes a hit once fully downloaded.
  ///
  /// Returns the resulting file path, or `null` if caching is unavailable or
  /// the download failed. Failures are swallowed so streaming is unaffected.
  Future<String?> cacheVideoInBackground(String url) {
    return _videoDownloads[url] ??=
        _store.downloadToFile(url, url).whenComplete(() {
      _videoDownloads.remove(url);
    });
  }

  // --- HLS caching (concatenated to a single file) -----------------------

  /// Downloads the HLS stream at [url] into the persistent cache in the
  /// background, concatenating its segments into a single playable file, so
  /// later plays load from disk. The cached file lives at the same key as a
  /// single-file video, so [videoFile] reports the hit for both.
  ///
  /// Safe to call on every miss: concurrent and repeated calls for the same URL
  /// share a single download, and the file is committed atomically so it only
  /// becomes a hit once fully assembled. Failures are swallowed so streaming is
  /// unaffected. Only unencrypted MPEG-TS streams are cached.
  Future<String?> cacheHlsInBackground(String url) {
    return _hlsDownloads[url] ??=
        _store.downloadHlsAsFile(url, url).whenComplete(() {
      _hlsDownloads.remove(url);
    });
  }

  /// Removes a single [url] from every cache layer.
  Future<void> evict(String url) async {
    final removed = _memory.remove(url);
    if (removed != null) _memoryBytes -= removed.lengthInBytes;
    await _store.delete(url);
  }

  /// Clears the entire cache (memory and persistent store).
  Future<void> clear() async {
    _memory.clear();
    _memoryBytes = 0;
    await _store.clear();
  }
}
