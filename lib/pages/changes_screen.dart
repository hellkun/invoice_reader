import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:invoice_reader/utils/constants.dart';

/// 用于展示更新日志的页面
class ChangesScreen extends StatelessWidget {
  const ChangesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: FutureBuilder<String>(
        future: rootBundle.loadString(FileConstants.assetChangesPath),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: MarkdownBody(data: snapshot.data!),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('加载更新文件异常:\n${snapshot.error}'),
            );
          }

          return Center(
            child: const CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
