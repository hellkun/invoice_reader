import 'dart:typed_data';

import 'package:invoice_reader/model/invoice.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'file_reader_web.dart'
    if (dart.library.io) 'file_reader_io.dart';

abstract class InvoiceReader {
  factory InvoiceReader() => InvoiceReaderImpl();

  Future<InvoiceSource> read(dynamic source);

}

  Future<Uint8List> readPdfAsImage(Uint8List data) async {
    final document = await PdfDocument.openData(data);

    final page = await document.getPage(1);
    print('Page size = ${page.width}/${page.height}');
    final image = await page.render(
      width: page.width * 3,
      height: page.height * 3,
      format: PdfPageFormat.PNG,
    );

    await page.close();

    return image!.bytes;
  }