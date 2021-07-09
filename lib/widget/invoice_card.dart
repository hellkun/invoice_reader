import 'dart:typed_data';

import 'package:invoice_reader/utils/pdf.dart';

import '../model/invoice.dart';
import 'package:flutter/material.dart';

class InvoiceCard extends StatefulWidget {
  final InvoiceSource source;

  final VoidCallback? onRemove;

  InvoiceCard({
    Key? key,
    required this.source,
    required this.onRemove,
  }) : super(key: key);

  @override
  _InvoiceCardState createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<InvoiceCard> {
  Future<Uint8List>? _future;

  @override
  void initState() {
    _future = widget.source.type == InvoiceSourceType.pdf
        ? readPdfAsImage(widget.source.imageSource)
        : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: _buildImage(),
            ),
            const SizedBox(
              height: 4.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(widget.source.name ?? '...'),
                ),
                if (widget.onRemove != null)
                  GestureDetector(
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onTap: widget.onRemove,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    Widget _buildMemoryImage(Uint8List source) => Image.memory(
          source,
          fit: BoxFit.cover,
        );

    if (widget.source.type == InvoiceSourceType.image)
      return _buildMemoryImage(widget.source.imageSource);

    // PDF
    assert(_future != null);
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: const CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          print('Error while rendering PDF: ${snapshot.error}');
          return Center(
            child: const Text('解析失败'),
          );
        }

        if (snapshot.hasData) {
          return _buildMemoryImage(snapshot.data!);
        }

        assert(false);
        return Container();
      },
    );
  }
}
