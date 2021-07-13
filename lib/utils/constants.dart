import 'package:flutter/foundation.dart';

/// Constants of files and assets, etc.
class FileConstants {
  static const _kPlatformAssetPath = kIsWeb ? '' : 'assets/';

  /// 更新日志的路径
  static const assetChangesPath = _kPlatformAssetPath + 'CHANGES.md';

  /// Excel模板文件的路径
  static const xlsTemplatePath = _kPlatformAssetPath + 'xls_template.xlsx';
}
