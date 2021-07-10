import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invoice_reader/model/invoice.dart';

class ResultScreen extends StatefulWidget {
  final Iterable<InvoiceSource> invoices;
  const ResultScreen({
    Key? key,
    required this.invoices,
  }) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final Map<int, dynamic> _map = {};

  @override
  void initState() {
    super.initState();
    _startParsing();
  }

  _startParsing() async {
    for (var i = 0; i < widget.invoices.length; i++) {
      var result;
      try {
        final item = widget.invoices.elementAt(i);
        result = item.hasParsed
            ? item.peekResult()!
            : await Future.delayed(
                const Duration(milliseconds: 100), () => item.getResult());

        print('Processing index = $i');
      } catch (e) {
        result = e;
      }

      if (mounted) {
        setState(() {
          _map[i] = result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Table(
        columnWidths: {
          0: FixedColumnWidth(40.0),
          1: FlexColumnWidth(1.0),
          2: FlexColumnWidth(2.0),
        },
        children: [
          // first row: titles
          TableRow(
            decoration: BoxDecoration(
              color: Colors.black12,
            ),
            children: [
              const Text('序号'),
              const Text('文件名'),
              const Text('发票信息'),
            ],
          ),
          ...[
            for (var i = 0; i < widget.invoices.length; i++)
              TableRow(
                children: [
                  Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                  ),
                  Text(widget.invoices.elementAt(i).name ?? '-'),
                  _buildInvoiceContent(i),
                ],
              )
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceContent(int index) {
    if (_map.containsKey(index)) {
      final item = _map[index]!;

      if (item is Invoice) {
        return Text('发票代码:${item.code}');
      } else {
        // 异常
        return Text('错误: $item');
      }
    }

    return const Text('正在解析');
  }
}
