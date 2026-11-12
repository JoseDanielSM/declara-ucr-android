import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory('evidence/android')..createSync(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      final report = Map<String, dynamic>.from(data ?? {});
      final encoded = report.remove('pdfBase64');
      report.remove('screenshots');
      if (encoded is String) {
        await File('${output.path}/declaracion-android.pdf')
            .writeAsBytes(base64Decode(encoded));
      }
      final reportName =
          Platform.environment['ANDROID_REPORT_NAME'] ?? 'integration-results';
      await File('${output.path}/$reportName.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    },
  );
}
