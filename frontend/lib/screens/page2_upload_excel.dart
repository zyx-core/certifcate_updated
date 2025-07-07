import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class UploadExcelPage extends StatefulWidget {
  const UploadExcelPage({super.key});

  @override
  State<UploadExcelPage> createState() => _UploadExcelPageState();
}

class _UploadExcelPageState extends State<UploadExcelPage> {
  List<Map<String, dynamic>> excelData = [];
  List<String> headers = [];

  Future<void> pickAndParseExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) return;

      final headerRow = sheet.rows.first;
      headers = headerRow.map((cell) => cell?.value.toString() ?? '').toList();

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length; j++) {
          rowData[headers[j]] = row[j]?.value;
        }
        excelData.add(rowData);
      }

      Navigator.pushNamed(
        context,
        '/page3',
        arguments: {
          'headers': headers,
          'excelData': excelData,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Excel")),
      body: Center(
        child: ElevatedButton(
          onPressed: pickAndParseExcel,
          child: const Text("Pick Excel File"),
        ),
      ),
    );
  }
}
