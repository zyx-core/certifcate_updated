// page2_upload_excel.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class UploadExcelPage extends StatefulWidget {
  const UploadExcelPage({Key? key}) : super(key: key);

  @override
  State<UploadExcelPage> createState() => _UploadExcelPageState();
}

class _UploadExcelPageState extends State<UploadExcelPage> {
  List<String> headers = [];
  List<Map<String, dynamic>> excelData = [];
  Uint8List? excelBytes;

  void _pickExcelFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true,
  );

  if (result == null || result.files.single.bytes == null) {
    print("Excel file not picked or bytes are null.");
    return;
  }

  Uint8List fileBytes = result.files.single.bytes!;
  setState(() {
    excelBytes = fileBytes;
  });

  try {
    var excel = Excel.decodeBytes(fileBytes);
    var sheet = excel.tables[excel.tables.keys.first];
    if (sheet != null && sheet.maxRows > 1) {
      headers = sheet.rows.first.map((e) => e?.value.toString() ?? '').toList();
      excelData = [];

      for (var i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        Map<String, dynamic> rowData = {};
        for (var j = 0; j < headers.length; j++) {
          rowData[headers[j]] = j < row.length ? row[j]?.value : null;
        }
        excelData.add(rowData);
      }

      Navigator.pushNamed(
        context,
        '/page3',
        arguments: {
          'headers': headers,
          'excelData': excelData,
          'excelBytes': excelBytes,
        },
      );
    } else {
      print("Excel sheet is empty or invalid.");
    }
  } catch (e) {
    print("Error decoding Excel file: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Excel File updated")),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickExcelFile,
          child: const Text("Pick Excel File"),
        ),
      ),
    );
  }
}
