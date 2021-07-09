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
              child: Image.memory(
                source.imageSource,
                fit: BoxFit.cover,
              ),
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
}
