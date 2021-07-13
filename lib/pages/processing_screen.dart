import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:invoice_reader/utils/constants.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:zxing_lib/zxing.dart';

Logger _logger = Logger('ProcessingScreen');

class ProcessingScreen extends StatelessWidget {
  static const _kMinDialogWidth = 300.0;

  final Iterable<InvoiceSource> invoices;

  ProcessingScreen({
    Key? key,
    required this.invoices,
  })  : assert(invoices.isNotEmpty),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final width = MediaQuery.of(context).size.width;

    return ChangeNotifierProvider<_ProcessingModel>(
      create: (_) => _ProcessingModel(invoices),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: max(_kMinDialogWidth, width / 3),
        child: Consumer<_ProcessingModel>(
          builder: (context, model, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题：正在解析
                model.zippedFileBytes == null
                    ? child!
                    : Text(
                        '处理完毕',
                        style: theme.textTheme.headline6,
                      ),
                const SizedBox(height: 16.0),
                // 进度（文字+进度条）

                ListView.separated(
                  itemBuilder: (_, index) =>
                      _buildStageEntry(theme, model.stateInfo.elementAt(index)),
                  separatorBuilder: (_, __) => const SizedBox(height: 4.0),
                  itemCount: model.stateInfo.length,
                  shrinkWrap: true,
                ),

                if (model.zippedFileBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16.0)),
                      ),
                      onPressed: () => _download(model.zippedFileBytes!),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          '下载',
                          textAlign: TextAlign.center,
                        ),
                        width: double.infinity,
                      ),
                    ),
                  )
              ],
            );
          },
          child: Text(
            '正在处理...',
            style: theme.textTheme.headline6,
          ),
        ),
      ),
    );
  }

  void _download(List<int> bytes) {
    final date = DateTime.now();
    final strDate = DateFormat('yyyy-MM-dd_HH-mm').format(date);

    Future.delayed(
      const Duration(milliseconds: 300),
      () => FileSaver.instance.saveFile(
        '电子发票_$strDate.zip',
        Uint8List.fromList(bytes),
        'zip',
        mimeType: MimeType.ZIP,
      ),
    );
  }

  Widget _buildStageEntry(ThemeData theme, _StateInfo entry) {
    return Row(
      children: [
        Icon(
          entry.isDone ? Icons.done : Icons.timelapse,
          color: entry.isDone
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.stageName,
              style: theme.textTheme.bodyText1,
            ),
            Text(
              entry.message,
              style: theme.textTheme.bodyText2,
            ),
          ],
        ),
      ],
    );
    return Text('${entry.stageName}: ${entry.message}');
  }
}

enum _ProcessingStage {
  /// 正在解析
  parsing,

  /// 正在生成表格
  creatingExcel,

  /// 正在生成压缩包
  creatingArchive,
}

class _StateInfo {
  final String stageName;
  final String message;
  final bool isDone;

  _StateInfo(this.stageName, this.message, this.isDone);
}

class _ProcessingModel extends ChangeNotifier {
  List<int>? _zippedFileBytes;

  List<int>? get zippedFileBytes => _zippedFileBytes;

  final Iterable<InvoiceSource> sources;

  final Map<_ProcessingStage, _StateInfo> _stageMap = {};

  Iterable<_StateInfo> get stateInfo => _stageMap.values;

  _ProcessingModel(this.sources) {
    _createArchiveOfContents();
  }

  void _createArchiveOfContents() async {
    // 先解析
    final invoices = await _decodeInvoices();

    // 生成Excel
    _stageMap[_ProcessingStage.creatingExcel] =
        _StateInfo('生成表格', '正在处理', false);
    notifyListeners();

    final excel = await getExcel(invoices);

    _stageMap[_ProcessingStage.creatingExcel] = _StateInfo('生成表格', '已完成', true);
    notifyListeners();

    // 生成压缩包
    _stageMap[_ProcessingStage.creatingArchive] =
        _StateInfo('生成压缩包', '正在处理', false);
    notifyListeners();

    final arc = await Future.delayed(const Duration(milliseconds: 50),
        () => _generateArchive(sources, excel));
    final encoder = ZipEncoder();
    _zippedFileBytes = encoder.encode(arc)!;
    encoder.endEncode();

    _stageMap[_ProcessingStage.creatingArchive] =
        _StateInfo('生成压缩包', '已完成', true);
    notifyListeners();
  }

  Future<List<Invoice>> _decodeInvoices() async {
    final list = <Invoice>[];

    var i = 0;
    for (var source in sources) {
      _stageMap[_ProcessingStage.parsing] =
          _StateInfo('解析', '正在解析第${i + 1}个文件', false);
      notifyListeners();

      try {
        final parsed = source.hasParsed
            ? source.peekResult()!
            : (await Future.delayed(
                const Duration(milliseconds: 50), () => source.getResult()));
        list.add(parsed);
        i++;
      } on ChecksumException {
        _logger.info('ChecksumException while decoding file ${source.name}');
      } on NotFoundException {
        _logger.info('NotFoundException while decoding file ${source.name}');
      }
    }

    _stageMap[_ProcessingStage.parsing] = _stageMap[_ProcessingStage.parsing] =
        _StateInfo('解析', '已解析${list.length}个文件', true);
    notifyListeners();

    return list;
  }

  Future<Archive> _generateArchive(
      Iterable<InvoiceSource> invoices, Excel file) async {
    final arc = Archive();

    String? _determineExt(InvoiceSource source) {
      if (source.name?.contains('.') != true) {
        return null;
      }
      return source.name!.substring(source.name!.lastIndexOf('.'));
    }

    final futures = invoices.map((e) async {
      var fExtName = _determineExt(e);
      late List<int> content;
      if (fExtName == null) {
        _logger.warning('Unknown original ext name');
        // TODO: encode
      } else {
        content = e.content;
      }

      assert(fExtName != null);
      final info = await e.getResult();
      final fName = '${info.code}-${info.serial}';

      return ArchiveFile(
        fName + fExtName!,
        content.length,
        content,
      );
    });

    (await Future.wait(futures)).forEach(arc.addFile);

    final excelContent = file.encode()!;
    arc.addFile(ArchiveFile(
      'invoices.xlsx',
      excelContent.length,
      excelContent,
    ));

    return arc;
  }

  Future<Excel> getExcel(List<Invoice> invoices) async {
    final excel = await _getBaseExcelTemplate();

    final sheet = excel.sheets.values.first;
    for (var i = 0; i < invoices.length; i++) {
      final e = invoices[i];

      // 从3rd row开始插入数据
      sheet.insertRowIterables([
        i + 1,
        "${e.code}",
        "${e.serial}",
        "${e.signature.substring(e.signature.length - 6, e.signature.length)}",
        e.strDate,
        e.amount,
      ], i + 2);
    }

    return excel;
  }

  FutureOr<Excel> _getBaseExcelTemplate() async {
    final data = await rootBundle.load(FileConstants.xlsTemplatePath);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return Excel.decodeBytes(bytes);
  }
}
