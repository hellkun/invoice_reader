import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:invoice_reader/utils/decode.dart';
import 'package:logging/logging.dart';
import 'package:zxing_lib/zxing.dart';

enum ReaderState {
  idle,

  decoding,

  done,
}

class ReaderModel extends ChangeNotifier {

  final Logger _logger = Logger('ReaderModel');

  ReaderState _readerState = ReaderState.idle;

  ReaderState get readerState => _readerState;

  final List<InvoiceSource> _sourcesOfInvoices = [];

  List<InvoiceSource> get sourcesOfInvoices => _sourcesOfInvoices;

  String _message = '已就绪';
  String get message => _message;

  ReaderModel({
    List<InvoiceSource>? sources,
  }) {
    if (sources != null) _sourcesOfInvoices.addAll(sources);
  }

  void addInvoiceSource(InvoiceSource source) {
    _sourcesOfInvoices.add(source);
    notifyListeners();
  }

  void removeInvoiceSource(InvoiceSource source) {
    _sourcesOfInvoices.remove(source);
    notifyListeners();
  }

  void removeAllSources() {
    _sourcesOfInvoices.clear();
    notifyListeners();
  }

  Future<List<Invoice>> _decodeInvoices({
    Duration intervalDuration = const Duration(milliseconds: 50),
    ValueChanged<int>? onEach,
  }) async {
    final list = <Invoice>[];

    var i = 0;
    for (var source in _sourcesOfInvoices) {
      onEach?.call(i);

      try {
        final qrResult = await Future.delayed(
            intervalDuration, () => parseResultFromInvoice(source));
        _logger.fine('text = ${qrResult.text}');

        list.add(Invoice.fromQR(
          qrResult.text,
          source: source,
        ));
        i++;
      } on ChecksumException {
        _logger.info('ChecksumException while decoding file ${source.name}');
      } on NotFoundException {
        _logger.info('NotFoundException while decoding file ${source.name}');
      }
    }

    return list;
  }

  void decodeAndSave() async {
    _readerState = ReaderState.decoding;
    notifyListeners();

    final invoices = await _decodeInvoices(onEach: (index) {
      _message = '正在解析第${index + 1}张发票\n'
          '（共${_sourcesOfInvoices.length}张）';
      notifyListeners();
    });

    if (invoices.isEmpty) {
      _message = '解析失败';
      _readerState = ReaderState.idle;
      notifyListeners();
      return;
    }
    assert(() {
      invoices.forEach((element) {
        _logger.fine('Got $element');
      });
      return true;
    }());

    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;

    sheet.insertRowIterables([
      '序号',
      '发票代码（文本格式）',
      '发票号码',
      '校验码（后6位）',
      '开票日期',
      '金额',
    ], 0);

    _message = '正在生成Excel表格';
    notifyListeners();

    for (var i = 0; i < invoices.length; i++) {
      final e = invoices[i];

      sheet.insertRowIterables([
        i + 1,
        "${e.code}",
        "${e.serial}",
        "${e.signature.substring(e.signature.length - 6, e.signature.length)}",
        e.strDate,
        e.amount,
      ], i + 1);
    }

    _message = '正在生成压缩包';
    notifyListeners();

    // 等待一下，便于UI更新
    await Future.delayed(const Duration(seconds: 1));

    final arc = _generateArchive(invoices);
    final excelContent = excel.encode()!;
    arc.addFile(ArchiveFile(
      'invoices.xlsx',
      excelContent.length,
      excelContent,
    ));

    final encoder = ZipEncoder();
    final zipped = encoder.encode(arc)!;
    encoder.endEncode();

    _readerState = ReaderState.done;
    _message = '已解析${invoices.length}个文件';
    notifyListeners();

    // 保存文件
    //excel.save();

    FileSaver.instance.saveFile(
      '电子发票.zip',
      Uint8List.fromList(zipped),
      'zip',
      mimeType: MimeType.ZIP,
    );
  }

  Archive _generateArchive(List<Invoice> invoices) {
    final arc = Archive();

    String? _determineExt(InvoiceSource source) {
      if (source.name?.contains('.') != true) {
        return null;
      }
      return source.name!.substring(source.name!.lastIndexOf('.'));
    }

    invoices.map((e) {
      if (e.source == null) {
        return null;
      }

      var fExtName = _determineExt(e.source!);
      late List<int> content;
      if (fExtName == null) {
        _logger.warning('Unknown original ext name');
        // TODO: encode
      } else {
        content = e.source!.imageSource;
      }

      assert(fExtName != null);
      final fName = '${e.code}-${e.serial}';

      return ArchiveFile(
        fName + fExtName!,
        content.length,
        content,
      );
    }).forEach((element) {
      if (element != null) {
        arc.addFile(element);
      }
    });

    return arc;
  }
}
