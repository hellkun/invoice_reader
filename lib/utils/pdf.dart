import 'dart:typed_data';

import 'package:native_pdf_renderer/native_pdf_renderer.dart';

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
