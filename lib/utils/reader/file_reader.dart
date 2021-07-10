
import 'package:invoice_reader/model/invoice.dart';

import 'file_reader_web.dart' if (dart.library.io) 'file_reader_io.dart';

abstract class InvoiceReader {
  factory InvoiceReader() => InvoiceReaderImpl();

  Future<InvoiceSource> read(dynamic source);
}