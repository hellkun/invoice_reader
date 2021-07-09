import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:invoice_reader/model/reader_model.dart';
import 'package:invoice_reader/pages/provide_screen.dart';
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
    return ChangeNotifierProvider.value(
      value: _model,
      child: Consumer<ReaderModel>(
        builder: (context, value, child) {
          return Scaffold(
            body: LayoutBuilder(builder: (context, constraints) {
              if (_model.sourcesOfInvoices.isEmpty) {
                return InvoiceProvideScreen(
                  onAdd: _model.addInvoiceSource,
                );
              }

              print('width = ${constraints.maxWidth}');
              if (constraints.maxWidth <= 500) {
                return _buildForNarrowWindow(context, constraints);
              }

              return _buildForWideScreen(context, constraints);
            }),
          );
        },
      ),
    );
  }

  Widget _buildForNarrowWindow(
      BuildContext context, BoxConstraints constraints) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              InvoicesPreview(
                width: constraints.maxWidth,
                sourcesOfInvoices: _model.sourcesOfInvoices,
                onRemove: _model.removeInvoiceSource,
                onRemoveAll: _model.removeAllSources,
              ),
              if (_model.readerState == ReaderState.decoding)
                Positioned.fill(
                  child: Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(_model.message),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        PhysicalModel(
          color: Theme.of(context).colorScheme.surface,
          elevation: 8.0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: _buildMainActionButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildForWideScreen(BuildContext context, BoxConstraints constraints) {
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: InvoicesPreview(
            width: constraints.maxWidth,
            sourcesOfInvoices: _model.sourcesOfInvoices,
            onRemove: _model.removeInvoiceSource,
            onRemoveAll: _model.removeAllSources,
          ),
        ),
        Flexible(
          flex: 1,
          child: _buildActionArea(Theme.of(context)),
        ),
      ],
    );
  }

  Widget _buildActionArea(ThemeData theme) {
    return PhysicalModel(
      color: theme.colorScheme.surface,
      elevation: 8.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            _buildMainActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return ElevatedButton(
      onPressed: _model.readerState == ReaderState.decoding
          ? null
          : () {
              SchedulerBinding.instance!
                  .scheduleTask(_model.decodeAndSave, Priority.animation);
            },
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
    );
  }
}
