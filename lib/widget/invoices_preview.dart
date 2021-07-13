import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:invoice_reader/utils/reader/file_reader.dart';
import 'package:logging/logging.dart';

import '../widget/invoice_card.dart';

/// [InvoiceSource]的交互区
///
/// 可以在这里处理[InvoiceSource]的增加和移除
class InvoiceInteractionZone extends StatefulWidget {
  /// 新增[InvoiceSource]时的回调
  final ValueChanged<InvoiceSource>? onAdd;

  /// 已载入的[InvoiceSource]
  final Iterable<InvoiceSource> sourcesOfInvoices;

  /// 移除[InvoiceSource]时的回调
  final ValueChanged<InvoiceSource>? onRemove;

  /// 清空所有[InvoiceSource]时的回调
  final VoidCallback? onRemoveAll;

  InvoiceInteractionZone({
    Key? key,
    required this.sourcesOfInvoices,
    this.onRemove,
    this.onRemoveAll,
    this.onAdd,
  }) : super(key: key);

  @override
  _InvoiceInteractionZoneState createState() => _InvoiceInteractionZoneState();
}

class _InvoiceInteractionZoneState extends State<InvoiceInteractionZone> {
  final Logger _logger = Logger('InvoiceInteractionZone');

  DropzoneViewController? _controller;

  late InvoiceReader _invoiceReader;

  bool _isDragging = false;

  @override
  void initState() {
    _invoiceReader = InvoiceReader();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final showActionBar = widget.sourcesOfInvoices.isNotEmpty;

    Widget child = _buildMain(showActionBar);

    if (kIsWeb) {
      child = Stack(
        alignment: Alignment.topCenter,
        children: [
          DropzoneView(
            onCreated: (ctrl) => _controller = ctrl,
            onDrop: _onContentDropped,
            onHover: () => updateDraggingState(true),
            onLeave: () => updateDraggingState(false),
          ),
          Positioned.fill(child: child),
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Text(
                  '拖拽到这里',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ),
        ],
      );
    }

    return child;
  }

  void updateDraggingState(bool isDragging) {
    if (mounted) {
      if (_isDragging != isDragging) {
        setState(() {
          _isDragging = isDragging;
        });
      }
    }
  }

  Widget _buildMain(bool showActionBar) {
    Widget child = widget.sourcesOfInvoices.isEmpty
        ? _buildGuide()
        : _InvoicesPreview(
            sourcesOfInvoices: widget.sourcesOfInvoices,
            onRemove: widget.onRemove,
            onRemoveAll: widget.onRemoveAll,
          );

    if (showActionBar) {
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          _buildActionSideBar(),
        ],
      );
    }

    return Container(
      color: Colors.black12,
      child: child,
    );
  }

  Widget _buildGuide() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '电子发票归档',
            style: theme.textTheme.headline4,
          ),
          Text(
            _controller != null ? '拖拽或点击下方按钮以选择文件' : '点击下方按钮选择文件',
            style: theme.textTheme.bodyText1,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              style: ButtonStyle(
                textStyle: MaterialStateProperty.all(theme.textTheme.headline6),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(
                    horizontal: 48.0,
                    vertical: 16.0,
                  ),
                ),
              ),
              onPressed: _pickFile,
              child: const Text('选择文件'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSideBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        right: 16.0,
        top: MediaQuery.of(context).size.height * 0.1,
      ),
      child: Column(
        children: [
          // 添加
          FloatingActionButton(
            onPressed: _pickFile,
            child: Icon(
              Icons.add,
              color: theme.colorScheme.onSecondary,
            ),
            tooltip: '添加文件',
            mini: true,
          ),

          const SizedBox(height: 16.0),

          // 清空
          FloatingActionButton(
            onPressed: widget.onRemoveAll,
            child: Icon(
              Icons.clear_all,
              color: theme.colorScheme.onSecondary,
            ),
            tooltip: '清空',
            mini: true,
          ),
        ],
      ),
    );
  }

  /// 选择文件
  void _pickFile() async {
    final pickResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: const [
        'jpg',
        'png',
        'pdf',
      ],
    );
    if (pickResult == null) {
      // nothing picked
      return;
    }

    pickResult.files.map(_readPlatformFile).forEach((element) async {
      widget.onAdd?.call(await element);
    });
  }

  Future<InvoiceSource> _readPlatformFile(PlatformFile file) {
    if (file.bytes != null) {
      return SynchronousFuture(InvoiceSource(file.bytes!,
          name: file.name,
          type: file.extension == 'pdf'
              ? InvoiceSourceType.pdf
              : InvoiceSourceType.image));
    } else {
      assert(file.path != null); // cannot be on web
      return _invoiceReader.read(file.path);
    }
  }

  void _onContentDropped(dynamic content) {
    updateDraggingState(false);
    _logger.info('File = ${content.name}, '
        'type = ${content.type}, '
        'size = ${content.size}');

    if (!kAcceptFileTypes.hasMatch(content.type)) {
      _logger.warning('unsupported file type: ${content.type}');
      // TODO: 处理不支持的文件
      return;
    }

    _invoiceReader.read(content).then((value) {
      widget.onAdd?.call(value);
    });
  }
}

class _InvoicesPreview extends StatelessWidget {
  static const _kMinCardWidth = 360.0;

  final _logger = Logger('InvoicesPreview');

  final Iterable<InvoiceSource> sourcesOfInvoices;

  final ValueChanged<InvoiceSource>? onRemove;

  final VoidCallback? onRemoveAll;

  _InvoicesPreview({
    Key? key,
    required this.sourcesOfInvoices,
    this.onRemove,
    this.onRemoveAll,
  })  : assert(sourcesOfInvoices.isNotEmpty),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      assert(constraints.hasBoundedWidth);

      final columnCount = max(constraints.maxWidth ~/ _kMinCardWidth, 1);
      _logger.fine(
          'Constraint width = ${constraints.maxWidth}, column count = $columnCount');

      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 4 / 3,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 8.0,
        ),
        itemCount: sourcesOfInvoices.length,
        itemBuilder: (context, index) {
          final item = sourcesOfInvoices.elementAt(index);
          return InvoiceCard(
            source: item,
            onRemove: onRemove != null ? () => onRemove!(item) : null,
          );
        },
      );
    });
  }
}

final kAcceptFileTypes = RegExp('application/pdf|image/.*');
