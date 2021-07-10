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
    Widget child = _buildMain(true);

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
          child,
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
    Widget child = LayoutBuilder(
      builder: (_, constraints) => _InvoicesPreview(
        width: constraints.maxWidth,
        sourcesOfInvoices: widget.sourcesOfInvoices,
        onRemove: widget.onRemove,
        onRemoveAll: widget.onRemoveAll,
      ),
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
            onPressed: () {},
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

  void _onContentDropped(dynamic content) {
    updateDraggingState(false);
    _logger.info('File = ${content.name}, '
        'type = ${content.type}, '
        'size = ${content.size}');

    if (!kAcceptFileTypes.hasMatch(content.type)) {
      _logger.warning('not an image');
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

  final Iterable<InvoiceSource> sourcesOfInvoices;

  final ValueChanged<InvoiceSource>? onRemove;

  final VoidCallback? onRemoveAll;

  _InvoicesPreview({
    Key? key,
    required this.sourcesOfInvoices,
    required this.width,
    this.onRemove,
    this.onRemoveAll,
  }) : super(key: key);

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sourcesOfInvoices.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        _buildActionBar(theme),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width ~/ _kMinCardWidth,
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
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('已添加${sourcesOfInvoices.length}个文件'),

          // 清空
          if (onRemoveAll != null) ...[
            const SizedBox(width: 8.0),
            GestureDetector(
              child: Text(
                '清空',
                style: theme.textTheme.bodyText1?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              onTap: onRemoveAll,
            ),
          ]
        ],
      ),
    );
  }
}

final kAcceptFileTypes = RegExp('application/pdf|image/.*');
