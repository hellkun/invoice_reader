import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';

final Logger _logger = Logger('Decode');

Future<Result> parseResultFromInvoice(
  Uint8List image, [
  bool tryCrop = true,
]) async {
  final param = {
    'image': image,
    'tryCrop': tryCrop,
  };

  if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Decoding image with dart:ui on non-main-isolate causes exception on Windows,
    // I guess it could happen on other desktop platforms,
    // so we cannot use compute to do async decoding.
    // the issue can be found here: https://github.com/flutter/flutter/issues/10647
    return _parseResultFromInvoice(param);
  } else {
    return compute(_parseResultFromInvoice, param);
  }
}

final _reader = QRCodeReader();

Future<Result> _parseResultFromInvoice(Map<String, dynamic> parameter) async {
  final image = parameter['image'] as Uint8List;
  final tryCrop = parameter['tryCrop'] as bool;

  final source = await _createFromBytes(image);

  try {
    final bitmap = _parseFromLuminanceSource(source, tryCrop);
    return _reader.decode(bitmap);
  } on Exception {
    if (tryCrop) {
      _logger.warning(
          'Failed to decode with tryCrop=$tryCrop, retry without cropping');

      final bitmap = _parseFromLuminanceSource(source, false);
      return _reader.decode(bitmap);
    }
    rethrow;
  }
}

BinaryBitmap _parseFromLuminanceSource(LuminanceSource source, bool tryCrop) {
  // 二维码在左上角，可以crop一次
  if (source.isCropSupported && tryCrop) {
    source = source.crop(0, 0, source.width ~/ 3, source.height ~/ 3);
  }

  return BinaryBitmap(HybridBinarizer(source));
}

Future<LuminanceSource> _createFromBytes(Uint8List src) {
  final completer = Completer<LuminanceSource>();

  ui.decodeImageFromList(src, (result) async {
    try {
      final data = (await result.toByteData())!.buffer.asInt32List();
      completer.complete(RGBLuminanceSource(
        result.width,
        result.height,
        data,
      ));
    } catch (e) {
      completer.completeError(e);
    }
  });

  return completer.future;
}
