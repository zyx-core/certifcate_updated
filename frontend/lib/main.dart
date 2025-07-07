import 'package:flutter/material.dart';

// Import your pages
import 'screens/page1_home.dart';
import 'screens/page2_upload_excel.dart';
import 'screens/page3_upload_template.dart';
import 'screens/page4_design_template.dart';
import 'screens/certificate_preview_page.dart'; // ✅ Correct import

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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/page2': (context) => const UploadExcelPage(),
        '/page3': (context) => const UploadTemplatePage(),
        '/design_template': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          return DesignTemplatePage(
            templateFile: args['templateFile'],
            headers: List<String>.from(args['headers']),
            excelData: List<Map<String, dynamic>>.from(args['excelData']),
          );
        },
        '/certificate_preview': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          return CertificatePreviewPage( // ✅ fixed name
            templateFile: args['templateFile'],
            headerPositions: Map<String, Offset>.from(args['headerPositions']),
            rowData: Map<String, dynamic>.from(args['rowData']),
          );
        },
      },
    );
  }
}
