import 'dart:async';
import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:file_selector/file_selector.dart' as selector;
import 'file_picker_web.dart' show kTypeGroups;
import 'file_picker.dart';

/// An implementation of [FilePicker] utilizing file_picker package
class FilePickerImpl implements FilePicker {
  @override
  Future<List<XFile>> pickFiles() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return selector.openFiles(
        acceptedTypeGroups: kTypeGroups,
      );
    }

    return picker.FilePicker.platform.pickFiles(
      type: picker.FileType.custom,
      allowMultiple: true,
      allowedExtensions: const [
        'jpg',
        'png',
        'pdf',
      ],
    ).then((value) async {
      if (value == null) {
        return [];
      }

      return List.unmodifiable(value.files.map(_mapFromPlatformFile));
    });
  }

  XFile _mapFromPlatformFile(picker.PlatformFile file) {
    return XFile(
      file.path!,
      name: file.name,
      bytes: file.bytes,
      length: file.size,
    );
  }
}
