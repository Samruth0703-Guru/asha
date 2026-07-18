import 'dart:js' as js;

void printReportLogs(List<Map<String, dynamic>> logs) {
  try {
    final printWindow = js.context.callMethod('open', ['', '_blank', 'width=900,height=600']);
    if (printWindow != null) {
      String html = '''
        <html>
        <head>
          <title>ASHA CARE+ Clinical Scan Reports</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 30px; color: #1e293b; }
            h1 { color: #0f172a; font-size: 24px; border-bottom: 2px solid #3b82f6; padding-bottom: 12px; margin-bottom: 6px; }
            p.meta { color: #64748b; font-size: 13px; margin-bottom: 24px; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { border: 1px solid #e2e8f0; padding: 12px 14px; text-align: left; font-size: 13px; }
            th { background-color: #f8fafc; color: #475569; font-weight: 600; }
            .severity { font-weight: bold; padding: 4px 8px; border-radius: 6px; font-size: 11px; }
            .High { background-color: #fee2e2; color: #991b1b; }
            .Moderate { background-color: #ffedd5; color: #9a3412; }
            .Low { background-color: #dcfce7; color: #166534; }
          </style>
        </head>
        <body>
          <h1>ASHA CARE+ Clinical Diagnostic Scan Logs</h1>
          <p class="meta">Generated: ${DateTime.now().toString().substring(0, 19)} • Operator: ASHA worker LAKSHMI_001</p>
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Patient ID/Name</th>
                <th>Possible Disease</th>
                <th>Category</th>
                <th>Severity</th>
                <th>Confidence</th>
              </tr>
            </thead>
            <tbody>
      ''';

      for (var log in logs) {
        final date = log['dateStr'] ?? 'N/A';
        final name = log['patientName'] ?? 'N/A';
        final patId = log['patientId'] ?? 'N/A';
        final disease = log['analysis']?['possibleDisease'] ?? 'N/A';
        final cat = log['analysis']?['diseaseCategory'] ?? 'N/A';
        final sev = log['analysis']?['severity'] ?? 'N/A';
        final conf = log['confidence'] ?? 'N/A';

        html += '''
          <tr>
            <td>$date</td>
            <td>$name ($patId)</td>
            <td>$disease</td>
            <td>$cat</td>
            <td><span class="severity $sev">$sev</span></td>
            <td>$conf</td>
          </tr>
        ''';
      }

      html += '''
            </tbody>
          </table>
          <script>
            window.onload = function() {
              window.print();
              window.close();
            }
          </script>
        </body>
        </html>
      ''';

      printWindow['document'].callMethod('write', [html]);
      printWindow['document'].callMethod('close');
    }
  } catch (_) {}
}

void printHtml(String html) {
  try {
    final printWindow = js.context.callMethod('open', ['', '_blank', 'width=900,height=600']);
    if (printWindow != null) {
      printWindow['document'].callMethod('write', [html]);
      printWindow['document'].callMethod('close');
      printWindow.callMethod('print');
    }
  } catch (_) {}
}
