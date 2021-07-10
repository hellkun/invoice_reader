import 'package:flutter/material.dart';
import 'package:invoice_reader/model/invoice.dart';

import '../widget/invoice_card.dart';

class InvoicesPreview extends StatelessWidget {
  static const _kMinCardWidth = 360.0;

  final Iterable<InvoiceSource> sourcesOfInvoices;

  final ValueChanged<InvoiceSource>? onRemove;

  final VoidCallback? onRemoveAll;

  InvoicesPreview({
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
