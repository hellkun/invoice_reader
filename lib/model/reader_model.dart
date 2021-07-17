
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'invoice.dart';

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

  Iterable<InvoiceSource> get sourcesOfInvoices => _sourcesOfInvoices;

  String _message = '已就绪';
  String get message => _message;

  ReaderModel({
    List<InvoiceSource>? sources,
  }) {
    if (sources != null) _sourcesOfInvoices.addAll(sources);
  }

  void addInvoiceSource(InvoiceSource source) {
    if (!_sourcesOfInvoices.contains(source)) {
      _sourcesOfInvoices.add(source);
      notifyListeners();
    } else {
      _logger.info('File ${source.name} has been added before');
    }
  }

  void removeInvoiceSource(InvoiceSource source) {
    _sourcesOfInvoices.remove(source);
    notifyListeners();
  }

  void removeAllSources() {
    _sourcesOfInvoices.clear();
    notifyListeners();
  }
}
