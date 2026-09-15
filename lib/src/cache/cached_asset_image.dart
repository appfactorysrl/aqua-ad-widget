import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'asset_cache.dart';

/// An [ImageProvider] that resolves image bytes through [AssetCache].
///
/// This mirrors the role of [NetworkImage] but sources bytes from the package
/// cache (memory -> disk -> network) instead of Flutter's transient in-memory
/// image cache. Two providers are equal when their [url]s match, which lets
/// Flutter's own [ImageCache] de-duplicate identical creatives as well.
@immutable
class CachedAssetImage extends ImageProvider<CachedAssetImage> {
  /// Creates a provider for the image at [url].
  const CachedAssetImage(this.url, {this.scale = 1.0});

  /// The asset URL. Also acts as the cache key.
  final String url;

  /// The scale to apply to the decoded image.
  final double scale;

  @override
  Future<CachedAssetImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedAssetImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CachedAssetImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<CachedAssetImage>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadCodec(
    CachedAssetImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await AssetCache.instance.getBytes(key.url);
    if (bytes.isEmpty) {
      throw StateError('Asset is empty: ${key.url}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedAssetImage &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'CachedAssetImage')}'
      '("$url", scale: $scale)';
}
