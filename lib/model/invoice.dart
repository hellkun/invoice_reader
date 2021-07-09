import 'dart:typed_data';

import 'package:decimal/decimal.dart';

class InvoiceSource {
  final Uint8List imageSource;

  final String? name;

  InvoiceSource(this.imageSource, {this.name});
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

  final InvoiceSource? source;

  Invoice({
    required this.code,
    required this.serial,
    required this.strDate,
    required this.signature,
    required this.amount,
    this.source,
  });

  DateTime get date {
    assert(strDate.length == 8);
    final year = int.parse(strDate.substring(0, 4));
    final month = int.parse(strDate.substring(4, 6));
    final day = int.parse(strDate.substring(6));

    return DateTime(year, month, day);
  }

  factory Invoice.fromQR(String text, {InvoiceSource? source}) {
    final contents = text.split(',');
    assert(contents.length == 9);

    return Invoice(
      code: contents[2],
      serial: contents[3],
      strDate: contents[5],
      signature: contents[6],
      amount: Decimal.parse(contents[4]),
      source: source,
    );
  }

  @override
  String toString() {
    return '{Invoice (code=$code, serial = $serial, date = $date, sign = $signature, amount = $amount)}';
  }
}
