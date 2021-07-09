import 'dart:typed_data';

import 'package:invoice_reader/utils/pdf.dart';

import '../model/invoice.dart';
import 'package:flutter/material.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceSource source;

  final VoidCallback? onRemove;

  const InvoiceCard({
    Key? key,
    required this.source,
    required this.onRemove,
  }) : super(key: key);

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
                  child: Text(source.name ?? '...'),
                ),
                if (onRemove != null)
                  GestureDetector(
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onTap: onRemove,
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

    if (source.type == InvoiceSourceType.image)
      return _buildMemoryImage(source.imageSource);

    // PDF
    return FutureBuilder<Uint8List>(
      future: readPdfAsImage(source.imageSource),
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
