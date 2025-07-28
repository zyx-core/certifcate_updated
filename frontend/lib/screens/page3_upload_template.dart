import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadTemplatePage extends StatefulWidget {
  const UploadTemplatePage({super.key});

  @override
  State<UploadTemplatePage> createState() => _UploadTemplatePageState();
}

class _UploadTemplatePageState extends State<UploadTemplatePage> {
  File? _templateFile;
  List<String> headers = [];
  List<Map<String, dynamic>> excelData = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      headers = List<String>.from(args['headers']);
      excelData = List<Map<String, dynamic>>.from(args['excelData']);
    }
  }

  Future<void> pickTemplateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _templateFile = File(result.files.single.path!);
      });
    }
  }

void proceedToDesign() async {
  if (_templateFile != null) {
    final imageBytes = await _templateFile!.readAsBytes();
   
 print("➡️ Navigating with:");
print("Headers: $headers");
print("Excel: $excelData");
print("Bytes: ${imageBytes.length}");


    Navigator.pushNamed(
  context,
  '/design_template',
  arguments: {
    'headers': headers, // Must be a List<String>
    'imageBytes': imageBytes, // Must be Uint8List
    'excelData': excelData, // Must be List<Map<String, dynamic>>
  },
);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Template")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickTemplateFile,
            child: const Text("Pick Template Image"),
          ),
          const SizedBox(height: 20),
          if (_templateFile != null)
            Image.file(_templateFile!, height: 200),
          const Spacer(),
          ElevatedButton(
            onPressed: _templateFile != null ? proceedToDesign : null,
            child: const Text("Design Certificate"),
          ),
        ],
      ),
    );
  }
}
