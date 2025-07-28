import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;

class DesignTemplatePage extends StatefulWidget {
  final List<String> headers;
  final Uint8List imageBytes;
  final List<Map<String, dynamic>> excelData;

  const DesignTemplatePage({
    super.key,
    required this.headers,
    required this.imageBytes,
    required this.excelData,
  });

  @override
  State<DesignTemplatePage> createState() => _DesignTemplatePageState();
}

class _DesignTemplatePageState extends State<DesignTemplatePage> {
  late List<String> headers;
  late Uint8List imageBytes;
  late List<Map<String, dynamic>> excelData;

  Size? originalImageSize;
  bool _isLoading = false;

  final Map<String, Offset> headerPositions = {};
  // ADDED: Map to store the font size for each header
  final Map<String, double> headerFontSizes = {};
  final GlobalKey imageKey = GlobalKey();
  String? selectedHeader;

  Map<String, dynamic> get previewData => excelData.isNotEmpty ? excelData[0] : {};

  @override
  void initState() {
    super.initState();
    headers = widget.headers;
    imageBytes = widget.imageBytes;
    excelData = widget.excelData;
    _getOriginalImageSize();
  }

  Future<void> _getOriginalImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        originalImageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
    }
  }

  void onImageTap(TapUpDetails details) {
    if (selectedHeader != null) {
      setState(() {
        headerPositions[selectedHeader!] = details.localPosition;
        // Set a default font size when a header is first placed
        if (!headerFontSizes.containsKey(selectedHeader!)) {
          headerFontSizes[selectedHeader!] = 1.0;
        }
      });
    } else if (headers.isNotEmpty) {
      final firstUnplaced = headers.firstWhere((h) => !headerPositions.containsKey(h), orElse: () => '');
      if (firstUnplaced.isNotEmpty) {
        setState(() {
          selectedHeader = firstUnplaced;
          headerPositions[selectedHeader!] = details.localPosition;
          headerFontSizes[selectedHeader!] = 32.0;
        });
      }
    }
  }

  Future<void> _sendToBackend({required bool isPreview}) async {
    if (originalImageSize == null || headerPositions.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a header and tap the image to place it.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      setState(() => _isLoading = false);
      return;
    }

    final displayedSize = renderBox.size;
    final fittedSizes = applyBoxFit(BoxFit.contain, originalImageSize!, displayedSize);
    final destinationSize = fittedSizes.destination;
    final scale = originalImageSize!.width / destinationSize.width;
    final offsetX = (displayedSize.width - destinationSize.width) / 2;
    final offsetY = (displayedSize.height - destinationSize.height) / 2;
    
    final uri = Uri.parse(isPreview
        ? "http://172.20.10.7:8000/generate/generate-preview"
        : "http://172.20.10.7:8000/generate/generate-and-send-uploaded");

    final placeholders = headerPositions.map((key, value) {
      final adjustedDx = value.dx - offsetX;
      final adjustedDy = value.dy - offsetY;
      return MapEntry(key, {
        "x": adjustedDx * scale,
        "y": adjustedDy * scale,
        // Use the font size from our map, with a default fallback
        "font_size": (headerFontSizes[key] ?? 32.0) * scale,
        "color": "black",
        "bold": false,
        "font": "Tinos",
      });
    });

    final sanitizedExcelData = excelData.map((row) => row.map((k, v) => MapEntry(k, v.toString()))).toList();

    final body = jsonEncode({
      "placeholders": placeholders,
      "excel_data": sanitizedExcelData,
      "template_bytes": base64Encode(imageBytes),
    });

    try {
      final response = await http.post(uri, headers: {"Content-Type": "application/json"}, body: body);
      if (mounted) setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (isPreview) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Image.memory(response.bodyBytes),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close"))],
            ),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Certificates sent successfully.")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exception: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Design Template")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12.0,
              children: [
                DropdownButton<String>(
                  hint: const Text("Select Header"),
                  value: selectedHeader,
                  items: headers.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                  onChanged: (val) => setState(() => selectedHeader = val),
                ),
                // --- ADDED: Font size slider appears when a header is selected ---
                if (selectedHeader != null && headerPositions.containsKey(selectedHeader))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Size:"),
                      Slider(
                        value: headerFontSizes[selectedHeader!] != null
                            ? headerFontSizes[selectedHeader!]!.clamp(8.0, 250.0)
                            : 32.0,
                        min: 8,
                        max: 250,
                        divisions: 242,
                        label: "${(headerFontSizes[selectedHeader!] ?? 32.0).round()}",
                        onChanged: (val) {
                          setState(() {
                            headerFontSizes[selectedHeader!] = val;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTapUp: onImageTap,
                    onPanUpdate: (details) {
                      if (selectedHeader != null && headerPositions.containsKey(selectedHeader)) {
                        setState(() {
                           headerPositions[selectedHeader!] = headerPositions[selectedHeader]! + details.delta;
                        });
                      }
                    },
                    child: Image.memory(
                      imageBytes,
                      key: imageKey,
                      fit: BoxFit.contain,
                    ),
                  ),
                  ...headerPositions.entries.map((entry) {
                    final key = entry.key;
                    final pos = entry.value;
                    
                    final renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox == null || originalImageSize == null) return Container();
                    
                    final displayedSize = renderBox.size;
                    final fittedSizes = applyBoxFit(BoxFit.contain, originalImageSize!, displayedSize);
                    final destinationSize = fittedSizes.destination;
                    final offsetX = (displayedSize.width - destinationSize.width) / 2;
                    final offsetY = (displayedSize.height - destinationSize.height) / 2;

                    return Positioned(
                      left: pos.dx + offsetX,
                      top: pos.dy + offsetY,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        color: Colors.yellow.withOpacity(0.6),
                        child: Text(
                          previewData[key]?.toString() ?? key,
                          style: TextStyle(
                            // The preview now uses the size from the slider
                            fontSize: headerFontSizes[key] ?? 32.0,
                            color: Colors.black,
                            fontFamily: 'Tinos'
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
           Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _sendToBackend(isPreview: false),
                  icon: const Icon(Icons.send),
                  label: const Text("Send All"),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _sendToBackend(isPreview: true),
                  icon: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2,)) : const Icon(Icons.visibility),
                  label: const Text("Preview"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}