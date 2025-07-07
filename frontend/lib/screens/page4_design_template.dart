import 'dart:io';
import 'package:flutter/material.dart';

class DesignTemplatePage extends StatefulWidget {
  final File templateFile;
  final List<String> headers;
  final List<Map<String, dynamic>> excelData;

  const DesignTemplatePage({
    super.key,
    required this.templateFile,
    required this.headers,
    required this.excelData,
  });

  @override
  State<DesignTemplatePage> createState() => _DesignTemplatePageState();
}

class _DesignTemplatePageState extends State<DesignTemplatePage> {
  late List<String> headers;
  String? selectedHeader;
  final GlobalKey imageKey = GlobalKey();
  final Map<String, Offset> headerPositions = {};

  @override
  void initState() {
    super.initState();
    headers = widget.headers;
  }

  void onTapImage(TapUpDetails details) {
    if (selectedHeader == null) return;

    final box = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final localPosition = box.globalToLocal(details.globalPosition);
      final size = box.size;
      final relativeOffset = Offset(
        localPosition.dx / size.width,
        localPosition.dy / size.height,
      );

      setState(() {
        headerPositions[selectedHeader!] = relativeOffset;
      });
    }
  }

  Widget _buildLabel(String key, Offset relativeOffset, Size imageSize) {
    return Positioned(
      left: relativeOffset.dx * imageSize.width,
      top: relativeOffset.dy * imageSize.height,
      child: Container(
        color: Colors.yellow,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Text(
          key,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void previewCertificate() {
    if (headerPositions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please place at least one header on the template.")),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/certificate_preview',
      arguments: {
        'templateFile': widget.templateFile,
        'headerPositions': headerPositions,
        'excelData': widget.excelData,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Design Template")),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text("Tap to place each header on the template image"),
          DropdownButton<String>(
            hint: const Text("Select Header"),
            value: selectedHeader,
            onChanged: (val) => setState(() => selectedHeader = val),
            items: headers.map((header) {
              return DropdownMenuItem(value: header, child: Text(header));
            }).toList(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: onTapImage,
                  child: Stack(
                    children: [
                      Image.file(
                        widget.templateFile,
                        key: imageKey,
                        width: constraints.maxWidth,
                        fit: BoxFit.contain,
                      ),
                      Builder(
                        builder: (_) {
                          final imageContext = imageKey.currentContext;
                          if (imageContext == null) return const SizedBox();
                          final size = imageContext.size!;
                          return Stack(
                            children: headerPositions.entries.map((entry) {
                              return _buildLabel(entry.key, entry.value, size);
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: previewCertificate,
              icon: const Icon(Icons.visibility),
              label: const Text("Preview Certificate"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
        ],
      ),
    );
  }
}
