import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/src/video_thumbnail_platform.dart';

/// An implementation of [VideoThumbnailPlatform] that uses method channels.
class MethodChannelVideoThumbnail extends VideoThumbnailPlatform {
  /// The method channel used to interact with the native platform.
  static const methodChannel =
      MethodChannel('plugins.justsoft.xyz/video_thumbnail');

  final Map<int, Completer<Object>> _futures = <int, Completer<Object>>{};

  MethodChannelVideoThumbnail() {
    methodChannel.setMethodCallHandler(_resolveCall);
  }

  Future<dynamic> _resolveCall(MethodCall call) async {
    switch (call.method) {
      case 'result#files':
        _resolveFilesCall(call);
        return;

      case 'result#file':
        _resolveFileCall(call);
        return;

      case 'result#data':
        _resolveDataCall(call);
        return;

      case 'result#error':
        _resolveError(call);
        return;

      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Unknown method ${call.method}',
        );
    }
  }

  void _resolveFilesCall(MethodCall call) {
    final List<String> result = call.arguments['result']?.cast<String>() ?? [];
    final int callId = call.arguments['callId'];

    _resolveFuture(callId, result.map(XFile.new).toList());
  }

  void _resolveFileCall(MethodCall call) {
    final String result = call.arguments['result'];
    final int callId = call.arguments['callId'];

    _resolveFuture(callId, XFile(result));
  }

  void _resolveDataCall(MethodCall call) {
    final List<int> result = call.arguments['result'];
    final int callId = call.arguments['callId'];

    _resolveFuture(callId, Uint8List.fromList(result));
  }

  void _resolveError(MethodCall call) {
    final Object error = call.arguments['result'];
    final int callId = call.arguments['callId'];

    _resolveFuture(callId, error is Exception ? error : Exception(error));
  }

  void _resolveFuture(int callId, Object value) {
    if (value is Exception) {
      _futures[callId]?.completeError(value);
    } else {
      _futures[callId]?.complete(value);
    }
    _futures.remove(callId);
  }

  (Completer<T>, int) _createCompleterAndCallId<T extends Object>() {
    final Completer<T> completer = Completer<T>();
    final int callId = completer.hashCode;

    _futures[callId] = completer;

    return (completer, callId);
  }

  int _getTimeMsValue(int? timeMs) =>
      defaultTargetPlatform == TargetPlatform.android
          ? timeMs ?? -1
          : timeMs ?? 0;

  @override
  Future<List<XFile>> thumbnailFiles(
    List<({String videoPath, VideoThumbnailConfig config})> videosAndConfigs,
  ) async {
    final (completer, callId) = _createCompleterAndCallId<List<XFile>>();

    final result = await methodChannel.invokeMethod(
      'files',
      {
        'callId': callId,
        'data': videosAndConfigs
            .map(
              (e) => [e.videoPath, e.config.toMap()],
            )
            .toList()
      },
    );

    if (result != true) {
      _resolveFuture(callId, result);
    }

    return completer.future;
  }

  @override
  Future<XFile> thumbnailFile({
    required String video,
    required Map<String, String>? headers,
    required String? thumbnailPath,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    int? timeMs,
    required int quality,
  }) async {
    final (completer, callId) = _createCompleterAndCallId<XFile>();

    final reqMap = <String, dynamic>{
      'callId': callId,
      'video': video,
      'headers': headers,
      'path': thumbnailPath,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': _getTimeMsValue(timeMs),
      'quality': quality
    };

    final result = await methodChannel.invokeMethod('file', reqMap);

    if (result != true) {
      _resolveFuture(callId, result);
    }

    return completer.future;
  }

  @override
  Future<Uint8List> thumbnailData({
    required String video,
    required Map<String, String>? headers,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    int? timeMs,
    required int quality,
  }) async {
    final (completer, callId) = _createCompleterAndCallId<Uint8List>();

    final reqMap = <String, dynamic>{
      'callId': callId,
      'video': video,
      'headers': headers,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': _getTimeMsValue(timeMs),
      'quality': quality,
    };

    final result = await methodChannel.invokeMethod('data', reqMap);

    if (result != true) {
      _resolveFuture(callId, result);
    }

    return completer.future;
  }
}
