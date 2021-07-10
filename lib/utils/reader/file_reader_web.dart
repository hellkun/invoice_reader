import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

import 'package:invoice_reader/model/invoice.dart';
import 'package:logging/logging.dart';

import 'file_reader.dart';

class InvoiceReaderImpl implements InvoiceReader {
  
  final Logger _logger = Logger('InvoiceReader');

  @override
  Future<InvoiceSource> read(dynamic source) {
    final completer = Completer<InvoiceSource>();

    final reader = FileReader();
    reader.onLoadEnd.listen((event) async {
      _logger.fine('onLoadEnd');
      var result = reader.result;
      String? name = (source as File).name;
      if (result is Uint8List) {
        completer.complete(InvoiceSource(
          result,
          name: name,
          type: source.type == 'application/pdf'
              ? InvoiceSourceType.pdf
              : InvoiceSourceType.image,
        ));
      } else {
        completer
            .completeError('Unexpected result type: ${result.runtimeType}');
      }
    });

    reader.readAsArrayBuffer(source);

    return completer.future;
  }
}
