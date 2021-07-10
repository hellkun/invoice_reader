import 'package:flutter/material.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:invoice_reader/model/reader_model.dart';
import 'package:invoice_reader/widget/invoices_preview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class ReaderScreen extends StatelessWidget {
  final ReaderModel _model;
  ReaderScreen({
    Key? key,
    List<InvoiceSource>? source,
  })  : _model = ReaderModel(
          sources: source ?? const [],
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider.value(
        value: _model,
        child: Consumer<ReaderModel>(
          builder: (context, value, child) {
            return LayoutBuilder(builder: (context, constraints) {
              /* if (_model.sourcesOfInvoices.isEmpty) {
                  return InvoiceProvideScreen(
                    onAdd: _model.addInvoiceSource,
                  );
                } */
              final isWide = constraints.maxWidth > 500;

              final main = InvoiceInteractionZone(
                sourcesOfInvoices: _model.sourcesOfInvoices,
                onAdd: _model.addInvoiceSource,
                onRemove: _model.removeInvoiceSource,
                onRemoveAll: _model.removeAllSources,
              );

              final actionArea = _buildActionArea(Theme.of(context), isWide);

              return isWide
                  ? Row(
                      children: [
                        Flexible(child: main, flex: 3),
                        Flexible(child: actionArea, flex: 1),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: main),
                        actionArea,
                      ],
                    );
            });
          },
        ),
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
                '解析电子发票'
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
        onPressed: _model.readerState == ReaderState.decoding
            ? null
            : _model.decodeAndSave,
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
        child: Container(
          width: double.infinity,
          child: Text(
            _model.readerState == ReaderState.decoding ? '请稍候' : '解析并下载',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
