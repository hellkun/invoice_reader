import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:invoice_reader/model/invoice.dart';
import 'package:invoice_reader/utils/reader/file_reader.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';

class InvoiceProvideScreen extends StatefulWidget {
  final ValueChanged<InvoiceSource> onAdd;

  const InvoiceProvideScreen({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  _InvoiceProvideScreenState createState() => _InvoiceProvideScreenState();
}

class _InvoiceProvideScreenState extends State<InvoiceProvideScreen> {
  final ValueNotifier<bool> _showShadowListenable = ValueNotifier(false);

  DropzoneViewController? _controller;

  @override
  void dispose() {
    _showShadowListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget widget = Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.15,
      ),
      child: Column(
        children: [
          Text(
            '电子发票归档',
            style: theme.textTheme.headline4,
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
              onPressed: pickFile,
              child: const Text(
                '选择文件',
              ),
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      widget = ValueListenableBuilder<bool>(
        valueListenable: _showShadowListenable,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              DropzoneView(
                onCreated: (ctrl) => _controller = ctrl,
                onDrop: (v) {
                  _showShadowListenable.value = false;
                  _onContentDropped(v);
                },
                onHover: () => _showShadowListenable.value = true,
                onLeave: () {
                  print('onLeave');
                  _showShadowListenable.value = false;
                },
              ),
              child!,
              if (value)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: Text(
                      '拖拽到这里',
                      style: theme.textTheme.headline6,
                    ),
                  ),
                ),
            ],
          );
        },
        child: widget,
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        alignment: Alignment.topCenter,
        child: widget,
      ),
    );
  }

  void pickFile() {
    if (_controller == null) {
      // TODO: 非Web，需要使用
      return;
    }

    _controller!.pickFiles().then((value) {
      assert(value.length == 1);
      _onContentDropped(value.first);
    });
  }

  void _onContentDropped(dynamic content) {
    print('File = ${content.name}, '
        'type = ${content.type}, '
        'size = ${content.size}');

    if (!kAcceptFileTypes.hasMatch(content.type)) {
      print('not an image');
      // TODO: 处理不支持的文件
      return;
    }

    InvoiceReader().read(content).then((value) {
      print('read value = ${value.name}');
      widget.onAdd(value);
    });

    /* final reader = FileReader();
      reader.onLoadStart.listen((event) {
        print('onLoadStart');
      });
      reader.onLoadEnd.listen((event) async {
        print('onLoadEnd: $event');
        var result = reader.result;
        String? name = content.name;

        if (result is Uint8List) {
          if (content.type == 'application/pdf') {
            result = await _readPdfAsImage(result);
            name = '.png';
          }

          final source = InvoiceSource(
            result,
            name: name,
          );

          widget.onAdd(source);
        } else {
          print('result type = ${result.runtimeType}');
        }
      }); 
      reader.readAsArrayBuffer(content); */
  }
}

Future<Uint8List> _readPdfAsImage(Uint8List data) async {
  final document = await PdfDocument.openData(data);

  final page = await document.getPage(1);
  print('Page size = ${page.width}/${page.height}');
  final image = await page.render(
    width: page.width * 3,
    height: page.height * 3,
    format: PdfPageFormat.PNG,
  );

  await page.close();

  return image!.bytes;
}

final kAcceptFileTypes = RegExp('application/pdf|image/.*');
