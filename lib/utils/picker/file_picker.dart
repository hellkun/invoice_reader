import 'package:cross_file/cross_file.dart';
import 'file_picker_io.dart' if (dart.library.html) 'file_picker_selector.dart';

abstract class FilePicker {
  static FilePicker? _instance;

  factory FilePicker() {
    if (_instance == null) {
      _instance = FilePickerImpl();
    }

    return _instance!;
  }

  Future<List<XFile>> pickFiles();
}
