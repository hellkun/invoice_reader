import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoice_reader/utils/decode.dart';
import 'package:logging/logging.dart';

class InvoiceSource {
  final Uint8List imageSource;

  final String? name;

  final InvoiceSourceType type;

  final Logger _logger = Logger('InvoiceSource');

  /// 解析的结果
  Invoice? _result;

  InvoiceSource(
    this.imageSource, {
    this.name,
    this.type = InvoiceSourceType.image,
  });

  bool get hasParsed => _result != null;
  
  Invoice? peekResult() => _result;

  Future<Invoice> getResult() {
    if (_result != null) {
      _logger.fine(
          'InvoiceSource $name has been parsed before, reusing the result');
      return SynchronousFuture(_result!);
    }

    _logger.fine('Decoding InvoiceSource $name ...');
    return parseResultFromInvoice(this)
        .then((value) => Invoice.fromQR(value.text))
        .then((value) {
      _result = value;
      return value;
    });
  }

  @override
  int get hashCode {
    final bytesHash = hashList(imageSource);
    return hashValues(
      name,
      bytesHash,
      type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! InvoiceSource) return false;

    return other.name == name &&
        listEquals(other.imageSource, imageSource) &&
        other.type == type;
  }
}

enum InvoiceSourceType {
  image,

  pdf,
}

class Invoice {
  /// 发票代码
  final String code;

  /// 发票号码
  final String serial;

  /// 开票日期
  final String strDate;

  /// 校验码
  final String signature;

  /// 金额
  final Decimal amount;

  Invoice({
    required this.code,
    required this.serial,
    required this.strDate,
    required this.signature,
    required this.amount,
  });

  DateTime get date {
    assert(strDate.length == 8);
    final year = int.parse(strDate.substring(0, 4));
    final month = int.parse(strDate.substring(4, 6));
    final day = int.parse(strDate.substring(6));

    return DateTime(year, month, day);
  }

  factory Invoice.fromQR(String text) {
    final contents = text.split(',');
    assert(contents.length == 9);

    return Invoice(
      code: contents[2],
      serial: contents[3],
      strDate: contents[5],
      signature: contents[6],
      amount: Decimal.parse(contents[4]),
    );
  }

  @override
  String toString() {
    return '{Invoice (code=$code, serial = $serial, date = $date, sign = $signature, amount = $amount)}';
  }
}
