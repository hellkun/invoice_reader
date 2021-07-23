import 'package:file_selector/file_selector.dart';

import 'file_picker.dart';

/// An implementation of [FickPicker] utilizing file_selector package
class FilePickerImpl implements FilePicker {
  @override
  Future<List<XFile>> pickFiles() {
    return openFiles(
      acceptedTypeGroups: kTypeGroups,
    );
  }
}

final kTypeGroups = [
  XTypeGroup(label: '图片', extensions: ['jpg', 'png']),
  XTypeGroup(label: '文档', extensions: ['pdf']),
];
