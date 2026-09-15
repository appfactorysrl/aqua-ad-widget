import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'asset_cache_store.dart';

/// Disk-backed store used on Android, iOS, macOS, Linux and Windows.
///
/// Each cached image is written as a single file inside a dedicated cache
/// directory. The filename is a SHA-256 hash of the asset URL so arbitrary
/// URLs map to safe, collision-resistant filenames.
class _IoAssetCacheStore implements AssetCacheStore {
  static const _subDir = 'aqua_ad_widget_cache';

  Directory? _dir;
  Future<Directory>? _dirFuture;

  Future<Directory> _resolveDir() {
    // Fast path once the directory has been resolved.
    final resolved = _dir;
    if (resolved != null) return Future.value(resolved);
    // Cache the in-flight future so concurrent callers share one lookup.
    return _dirFuture ??= () async {
      final base = await getTemporaryDirectory();
      final dir = Directory('${base.path}/$_subDir');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _dir = dir;
      return dir;
    }();
  }

  String _fileName(String key) => sha256.convert(utf8.encode(key)).toString();

  Future<File> _file(String key) async {
    final dir = await _resolveDir();
    return File('${dir.path}/${_fileName(key)}');
  }

  @override
  Future<Uint8List?> read(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      // Unreadable cache entry: treat as a miss.
      return null;
    }
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    try {
      final file = await _file(key);
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Best-effort persistence; failures must not break rendering.
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final file = await _file(key);
      if (await file.exists()) await file.delete();
      final tmp = File('${file.path}.tmp');
      if (await tmp.exists()) await tmp.delete();
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _resolveDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _dir = null;
      _dirFuture = null;
    } catch (_) {}
  }

  // --- Single-file video caching -----------------------------------------

  @override
  Future<String?> filePath(String key) async {
    try {
      final file = await _file(key);
      return await file.exists() ? file.path : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> downloadToFile(String key, String url) async {
    File? tmp;
    try {
      final file = await _file(key);
      // Already cached (e.g. a concurrent download finished first).
      if (await file.exists()) return file.path;

      // Download to a temporary sibling first, then atomically rename so the
      // final path only ever points at a complete file.
      tmp = File('${file.path}.tmp');
      if (await tmp.exists()) await tmp.delete();

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      if (response.statusCode != 200) {
        return null;
      }

      final sink = tmp.openWrite();
      try {
        await response.stream.pipe(sink);
      } finally {
        await sink.close();
      }

      // Guard against a race where another download completed meanwhile.
      if (await file.exists()) {
        await tmp.delete();
        return file.path;
      }
      await tmp.rename(file.path);
      return file.path;
    } catch (_) {
      // Best-effort caching: clean up any partial temp file and report a miss.
      try {
        if (tmp != null && await tmp.exists()) await tmp.delete();
      } catch (_) {}
      return null;
    }
  }

  // --- HLS caching (concatenated to a single file) -----------------------

  @override
  Future<String?> downloadHlsAsFile(String key, String manifestUrl) async {
    File? tmp;
    try {
      final file = await _file(key);
      // Already cached (single-file and HLS share the same key path).
      if (await file.exists()) return file.path;

      final baseUri = Uri.parse(manifestUrl);
      final manifestResponse = await http.get(baseUri);
      if (manifestResponse.statusCode != 200) return null;

      // Collect segment URIs in playlist order. Non-tag, non-blank lines are
      // segment references, resolved against the manifest URL.
      final segmentUris = <Uri>[];
      for (final rawLine
          in const LineSplitter().convert(manifestResponse.body)) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        segmentUris.add(baseUri.resolve(line));
      }
      if (segmentUris.isEmpty) return null;

      // Concatenate all segments into one temp file, then atomically rename.
      // For unencrypted MPEG-TS, concatenating the segment bytes in order
      // yields a valid, directly playable stream.
      tmp = File('${file.path}.tmp');
      if (await tmp.exists()) await tmp.delete();

      final sink = tmp.openWrite();
      try {
        for (final segmentUri in segmentUris) {
          final segResponse = await http.get(segmentUri);
          if (segResponse.statusCode != 200) {
            await sink.close();
            await tmp.delete();
            return null;
          }
          sink.add(segResponse.bodyBytes);
        }
      } finally {
        await sink.close();
      }

      // Guard against a race where another download completed meanwhile.
      if (await file.exists()) {
        await tmp.delete();
        return file.path;
      }
      await tmp.rename(file.path);
      return file.path;
    } catch (_) {
      try {
        if (tmp != null && await tmp.exists()) await tmp.delete();
      } catch (_) {}
      return null;
    }
  }
}

/// Creates the disk-backed store used on IO platforms.
AssetCacheStore createStore() => _IoAssetCacheStore();
