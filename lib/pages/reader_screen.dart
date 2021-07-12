import 'package:flutter/material.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:invoice_reader/model/reader_model.dart';
import 'package:invoice_reader/pages/changes_screen.dart';
import 'package:invoice_reader/pages/processing_screen.dart';
import 'package:invoice_reader/widget/invoices_preview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class ReaderScreen extends StatelessWidget {
  final String title;
  final ReaderModel _model;
  ReaderScreen({
    Key? key,
    required this.title,
    List<InvoiceSource>? source,
  })  : _model = ReaderModel(
          sources: source ?? const [],
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Consumer<ReaderModel>(
        builder: (_, model, ___) =>
            LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;

          final main = InvoiceInteractionZone(
            sourcesOfInvoices: model.sourcesOfInvoices,
            onAdd: model.addInvoiceSource,
            onRemove: model.removeInvoiceSource,
            onRemoveAll: model.removeAllSources,
          );

          final actionArea = _buildActionArea(Theme.of(context), isWide);

          // 根据屏幕宽度选择横向、纵向排列
          final body = isWide
              ? Row(children: [
                  Flexible(child: main, flex: 3),
                  Flexible(child: actionArea, flex: 1),
                ])
              : Column(children: [
                  Expanded(child: main),
                  actionArea,
                ]);

          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  onPressed: () => _showChangelog(context),
                  tooltip: '查看更新日志',
                  icon: const Icon(Icons.table_rows),
                )
              ],
            ),
            body: body,
          );
        }),
      ),
    );
  }

  Widget _buildActionArea(ThemeData theme, bool isWide) {
    Widget child = _buildMainActionButton();

    if (isWide) {
      // 宽屏下
      child = Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              return Text(
                '$title'
                '\n'
                '${snapshot.data?.version ?? ""}',
                style: theme.textTheme.headline6,
                textAlign: TextAlign.center,
              );
            },
          ),
          Container(
            height: 1.0,
            color: theme.colorScheme.primary,
            margin: const EdgeInsets.symmetric(
              vertical: 8.0,
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.black12,
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _model.message,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          child,
        ],
      );
    }

    return PhysicalModel(
      color: theme.colorScheme.surface,
      elevation: 8.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildMainActionButton() {
    return Builder(
      builder: (context) => ElevatedButton(
        onPressed: _model.readerState == ReaderState.decoding ||
                _model.sourcesOfInvoices.isEmpty
            ? null
            : () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: ProcessingScreen(invoices: _model.sourcesOfInvoices),
                  ),
                );
              },
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
        child: Container(
          width: double.infinity,
          child: Text(
            _model.readerState == ReaderState.decoding ? '请稍候' : '开始处理',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ChangesScreen(),
      ),
    );
  }
}
