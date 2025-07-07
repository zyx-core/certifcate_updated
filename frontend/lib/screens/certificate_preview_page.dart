import 'dart:io';
import 'package:flutter/material.dart';

class CertificatePreviewPage extends StatelessWidget {
  final File templateFile;
  final Map<String, Offset> headerPositions;
  final Map<String, dynamic> rowData;

  const CertificatePreviewPage({
    super.key,
    required this.templateFile,
    required this.headerPositions,
    required this.rowData,
  });

  Widget _buildLabel(String text, Offset relativeOffset, Size imageSize) {
    return Positioned(
      left: relativeOffset.dx * imageSize.width,
      top: relativeOffset.dy * imageSize.height,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey imageKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(title: const Text("Certificate Preview")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Stack(
              children: [
                Image.file(
                  templateFile,
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
                        final headerKey = entry.key;
                        final offset = entry.value;
                        final text = rowData[headerKey]?.toString() ?? '';
                        return _buildLabel(text, offset, size);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
