import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'screens/page1_home.dart';
import 'screens/page2_upload_excel.dart';
import 'screens/page3_upload_template.dart' hide UploadExcelPage;
import 'screens/page4_design_template.dart';
import 'screens/certificate_preview_page.dart';
import 'models/certificate_field.dart';

void main() {
  runApp(const CertificateApp());
}

class CertificateApp extends StatelessWidget {
  const CertificateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certificate Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/page2': (context) => const UploadExcelPage(),
        '/page3': (context) => const UploadTemplatePage(),

        // ✅ Design Template Route
        '/design_template': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args == null || args is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing navigation arguments.")),
            );
          }

          try {
            final headers = args['headers'];
            final imageBytes = args['imageBytes'];
            final excelData = args['excelData'];
            final emailColumn = args['emailColumn'];

            if (headers == null || imageBytes == null || excelData == null) {
              return const Scaffold(
                body: Center(
                    child: Text("❌ One or more required arguments are null.")),
              );
            }

            final headerList = List<String>.from(headers);
            final imageUint8 = imageBytes as Uint8List;
            final excelList = List<Map<String, dynamic>>.from(excelData);

            if (headerList.isEmpty || imageUint8.isEmpty || excelList.isEmpty) {
              return const Scaffold(
                body: Center(
                    child: Text("❌ Headers, Excel data, or Image is empty.")),
              );
            }

            return DesignTemplatePage(
              headers: headerList,
              imageBytes: imageUint8,
              excelData: excelList,
              emailColumn: emailColumn as String?,
            );
          } catch (e) {
            return Scaffold(
              body: Center(
                  child: Text("❌ Error parsing arguments:\n${e.toString()}")),
            );
          }
        },

        // ✅ Certificate Preview Route
        '/certificate_preview': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args == null || args is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing preview arguments.")),
            );
          }

          try {
            return PreviewCertificatePage(
              templateFile: args['templateFile'],
              headerConfigs:
                  Map<String, CertificateField>.from(args['headerConfigs']),
              rowData: Map<String, dynamic>.from(args['rowData']),
            );
          } catch (e) {
            return Scaffold(
              body: Center(
                  child: Text("❌ Error parsing preview arguments:\n${e.toString()}")),
            );
          }
        },
      },
    );
  }
}
