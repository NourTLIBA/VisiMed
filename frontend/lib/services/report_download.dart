// Platform-neutral entrypoint for saving an exported report.
//
// The concrete implementation is selected at compile time: `dart:html` on web,
// `dart:io` + path_provider elsewhere. This replaces the unconditional
// `import 'dart:html'` that broke every non-web build
// (see inconsistencies.md §1.1).

import 'report_download_stub.dart'
    if (dart.library.html) 'report_download_web.dart'
    if (dart.library.io) 'report_download_io.dart';

/// Persists [bytes] as [filename] and returns a human-readable location
/// (a path on IO, the filename on web).
Future<String> saveReport(List<int> bytes, String filename) =>
    saveReportImpl(bytes, filename);
