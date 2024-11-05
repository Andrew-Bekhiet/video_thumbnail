import 'package:flutter/foundation.dart';
import 'package:get_thumbnail_video/index.dart';

class VideoThumbnailConfig {
  final Map<String, String>? headers;
  final String? thumbnailPath;
  final ImageFormat imageFormat;
  final int? maxHeight;
  final int? maxWidth;
  final int? timeMs;
  final int? quality;

  const VideoThumbnailConfig({
    this.thumbnailPath,
    this.headers,
    this.imageFormat = ImageFormat.PNG,
    this.maxHeight,
    this.maxWidth,
    this.timeMs,
    this.quality,
  });

  Map<String, Object?> toMap() {
    return {
      'path': thumbnailPath,
      'headers': headers,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': defaultTargetPlatform == TargetPlatform.android
          ? timeMs ?? -1
          : timeMs ?? 0,
      'quality': quality,
    };
  }
}
