import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadTemplatePage extends StatefulWidget {
  const UploadTemplatePage({super.key});

  @override
  State<UploadTemplatePage> createState() => _UploadTemplatePageState();
}

class _UploadTemplatePageState extends State<UploadTemplatePage> {
  Uint8List? _imageBytes;
  String? _fileName;
  List<String> headers = [];
  List<Map<String, dynamic>> excelData = [];
  String? emailColumn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      headers = List<String>.from(args['headers']);
      excelData = List<Map<String, dynamic>>.from(args['excelData']);
      emailColumn = args['emailColumn'] as String?;
    }
  }

  Future<void> pickTemplateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true, // Important for web support
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

void proceedToDesign() async {
  if (_imageBytes != null) {
 print("➡️ Navigating with:");
print("Headers: $headers");
print("Excel: $excelData");
print("Bytes: ${_imageBytes!.length}");


    Navigator.pushNamed(
  context,
  '/design_template',
  arguments: {
    'headers': headers, // Must be a List<String>
    'imageBytes': _imageBytes, // Must be Uint8List
    'excelData': excelData, // Must be List<Map<String, dynamic>>
    'emailColumn': emailColumn, // Pass email column
  },
);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Template")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickTemplateFile,
              child: const Text("Pick Template Image"),
            ),
            const SizedBox(height: 20),
            if (_imageBytes != null) ...[
              Text("Selected: $_fileName", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Image.memory(_imageBytes!, height: 200),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _imageBytes != null ? proceedToDesign : null,
              child: const Text("Design Certificate"),
            ),
          ],
        ),
      ),
    );
  }
}
