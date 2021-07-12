import 'dart:async';
import 'dart:io';

import 'package:invoice_reader/model/invoice.dart';

import 'file_reader.dart';

class InvoiceReaderImpl implements InvoiceReader {
  @override
  Future<InvoiceSource> read(source) async {
    print('source = $source');
    final file = File(source);
    final bytes = await file.readAsBytes();

    final fName = file.path.split('/').last;

    final fExtName = fName.split('.').last;

    return InvoiceSource(
      bytes,
      name: fName,
      type: fExtName == 'pdf' ? InvoiceSourceType.pdf : InvoiceSourceType.image,
    );
  }
}
