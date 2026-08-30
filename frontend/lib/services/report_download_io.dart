import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveReportImpl(List<int> bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final dot = filename.lastIndexOf('.');
  final name = dot == -1
      ? '${filename}_$stamp'
      : '${filename.substring(0, dot)}_$stamp${filename.substring(dot)}';
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes);
  return file.path;
}
