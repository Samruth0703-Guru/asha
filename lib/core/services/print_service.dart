import 'print_service_stub.dart'
    if (dart.library.js) 'print_service_web.dart' as impl;

void printReportLogs(List<Map<String, dynamic>> logs) {
  impl.printReportLogs(logs);
}

void printHtml(String html) {
  impl.printHtml(html);
}
