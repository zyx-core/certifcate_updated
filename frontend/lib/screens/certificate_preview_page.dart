import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/certificate_field.dart';

class PreviewCertificatePage extends StatefulWidget {
  final File templateFile;
  final Map<String, CertificateField> headerConfigs;
  final Map<String, dynamic> rowData;

  const PreviewCertificatePage({
    super.key,
    required this.templateFile,
    required this.headerConfigs,
    required this.rowData,
  });

  @override
  State<PreviewCertificatePage> createState() => _PreviewCertificatePageState();
}

class _PreviewCertificatePageState extends State<PreviewCertificatePage> {
  Size? imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final image = Image.file(widget.templateFile);
    final completer = Completer<Size>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        completer.complete(size);
      }),
    );

    final size = await completer.future;
    if (mounted) {
      setState(() {
        imageSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Certificate Preview")),
      body: imageSize == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final scaleFactor = constraints.maxWidth / imageSize!.width;

                return Center(
                  child: Stack(
                    children: [
                      Image.file(
                        widget.templateFile,
                        width: constraints.maxWidth,
                        fit: BoxFit.contain,
                      ),
                      ...widget.headerConfigs.entries.map((entry) {
                        final header = entry.key;
                        final config = entry.value;

                        final text = widget.rowData[header]?.toString() ?? '';

                        return Positioned(
                          left: config.position.dx * constraints.maxWidth,
                          top: config.position.dy * imageSize!.height * scaleFactor,
                          child: Text(
                            text,
                            style: config.style,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
