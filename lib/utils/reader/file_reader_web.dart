import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

import 'package:invoice_reader/model/invoice.dart';

import 'file_reader.dart';

class InvoiceReaderImpl implements InvoiceReader {
  @override
  Future<InvoiceSource> read(dynamic source) {
    final completer = Completer<InvoiceSource>();

    final reader = FileReader();
    reader.onLoadEnd.listen((event) async {
      print('onLoadEnd');
      var result = reader.result;
      String? name = (source as File).name;
      if (result is Uint8List) {
        if (source.type == 'application/pdf') {
          result = await readPdfAsImage(result);
          name = '.png';
        }

        completer.complete(InvoiceSource(
          result,
          name: name,
        ));
      } else {
        completer
            .completeError('Unexpected result type: ${result.runtimeType}');
      }
    });

    return completer.future;
  }
}
