import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';

Future<Result> parseResultFromInvoice(
  InvoiceSource invoice, [
  bool tryCrop = true,
]) async {
  return compute(_parseResultFromInvoice, {
    'invoice': invoice,
    'tryCrop': tryCrop,
  }).then((value) {
    if (value == null) {
      return Future.error('bitmap null');
    }

    return value;
  });
}

final _reader = QRCodeReader();

Result? _parseResultFromInvoice(Map<String, dynamic> parameter) {
  final invoice = parameter['invoice'] as InvoiceSource;
  final tryCrop = parameter['tryCrop'] as bool;

  final source = _getLuminanceSource(invoice);
  if (source == null) {
    return null;
  }

  try {
    final bitmap = _parseFromLuminanceSource(source, tryCrop);
    return bitmap != null ? _reader.decode(bitmap) : null;
  } on Exception {
    if (tryCrop) {
      print('Failed to decode with tryCrop=$tryCrop, retry without cropping');

      final bitmap = _parseFromLuminanceSource(source, false);
      return bitmap != null ? _reader.decode(bitmap) : null;
    }
    rethrow;
  }
}

LuminanceSource? _getLuminanceSource(InvoiceSource invoice) {
  var markTime = DateTime.now().millisecondsSinceEpoch;

  var image = _decodeImage(invoice);

  final afterDecodeTime = DateTime.now().millisecondsSinceEpoch;
  print('Decoding image takes ${afterDecodeTime - markTime}ms');
  markTime = afterDecodeTime;

  if (image == null) {
    return null;
  }

  return RGBLuminanceSource(image.width, image.height, image.data);
}

BinaryBitmap? _parseFromLuminanceSource(LuminanceSource source, bool tryCrop) {
  // 二维码在左上角，可以crop一次
  if (source.isCropSupported && tryCrop) {
    print('crop source');
    source = source.crop(0, 0, source.width ~/ 3, source.height ~/ 3);
  }

  return BinaryBitmap(HybridBinarizer(source));
}

Image? _decodeImage(InvoiceSource invoice) {
  return invoice.name != null
      ? decodeNamedImage(invoice.imageSource, invoice.name!)
      : decodeImage(invoice.imageSource);
}
