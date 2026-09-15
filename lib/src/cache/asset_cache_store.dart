import 'dart:typed_data';

/// Abstraction over an optional persistent backing store for cached image
/// bytes, keyed by the asset URL.
///
/// Because the ad server serves a distinct (content-addressed) URL for every
/// creative version, entries never become stale: a changed asset has a new URL
/// and therefore a new key. The store only needs to map a key to raw bytes.
///
/// Implementations are platform specific. The IO implementation stores bytes
/// on disk so caches survive app restarts; the web implementation is a no-op
/// because browsers do not expose a filesystem here (the in-memory layer still
/// applies on web).
abstract class AssetCacheStore {
  /// Loads persisted bytes for [key], or `null` if not present.
  Future<Uint8List?> read(String key);

  /// Persists [bytes] under [key].
  Future<void> write(String key, Uint8List bytes);

  /// Removes the persisted entry for [key], if any.
  Future<void> delete(String key);

  /// Removes all persisted entries.
  Future<void> clear();

  /// Returns the absolute path of a *complete* cached file for [key], or
  /// `null` if no finished file exists.
  ///
  /// Used for large assets (single-file videos) that are played directly from
  /// disk by the platform video player. On the web this always returns `null`.
  Future<String?> filePath(String key);

  /// Downloads the asset at [url] and stores it under [key], returning the
  /// resulting file path (or `null` if the platform has no filesystem).
  ///
  /// Implementations must write atomically: a partially downloaded file must
  /// never be observable via [filePath]. This lets a caller stream [url] from
  /// the network while the same bytes are cached in the background; the entry
  /// only becomes a cache hit once the download completes.
  Future<String?> downloadToFile(String key, String url);

  /// Downloads the HLS media playlist at [manifestUrl] and stores it under
  /// [key] as a **single playable file** by concatenating its segments in
  /// playlist order.
  ///
  /// This targets the same path as [filePath]/[downloadToFile], so once cached
  /// an HLS stream is played the same way as any other file — no local HLS
  /// manifest and no local server are involved (iOS cannot play HLS from
  /// `file://`, but it plays the concatenated MPEG-TS stream fine).
  ///
  /// Only works for unencrypted MPEG-TS segments. The file is written
  /// atomically, so it only becomes a hit once fully assembled. Returns the
  /// resulting file path, or `null` if caching is unavailable or it failed.
  Future<String?> downloadHlsAsFile(String key, String manifestUrl);
}
