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
  String? selectedEmailColumn;

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

      setState(() {
        // Auto-select email column if it exists
        selectedEmailColumn = headers.firstWhere(
          (h) => h.toLowerCase().contains('email'),
          orElse: () => headers.isNotEmpty ? headers[0] : '',
        );
      });
    } else {
      print("Excel sheet is empty or invalid.");
    }
  } catch (e) {
    print("Error decoding Excel file: $e");
  }
}

  void _proceedToNextPage() {
    if (headers.isEmpty || selectedEmailColumn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload Excel file and select email column")),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/page3',
      arguments: {
        'headers': headers,
        'excelData': excelData,
        'excelBytes': excelBytes,
        'emailColumn': selectedEmailColumn,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Excel File")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickExcelFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Pick Excel File"),
            ),
            const SizedBox(height: 20),
            if (headers.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Excel file loaded successfully!",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Rows: ${excelData.length}"),
                      Text("Columns: ${headers.length}"),
                      const SizedBox(height: 16),
                      const Text(
                        "Select Email Column:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedEmailColumn,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Choose column containing emails",
                        ),
                        items: headers.map((header) {
                          return DropdownMenuItem(
                            value: header,
                            child: Text(header),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedEmailColumn = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _proceedToNextPage,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Continue to Upload Template"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
