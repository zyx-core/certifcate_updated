import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import '../widgets/progress_dialog.dart';
import '../utils/api_config.dart';


class DesignTemplatePage extends StatefulWidget {
  final List<String> headers;
  final Uint8List imageBytes;
  final List<Map<String, dynamic>> excelData;
  final String? emailColumn;

  const DesignTemplatePage({
    super.key,
    required this.headers,
    required this.imageBytes,
    required this.excelData,
    this.emailColumn,
  });

  @override
  State<DesignTemplatePage> createState() => _DesignTemplatePageState();
}

class _DesignTemplatePageState extends State<DesignTemplatePage> {
  late List<String> headers;
  late Uint8List imageBytes;
  late List<Map<String, dynamic>> excelData;
  String? emailColumn;

  Size? originalImageSize;
  bool _isLoading = false;

  final Map<String, Offset> headerPositions = {};
  final Map<String, double> headerFontSizes = {};
  final Map<String, String> headerColors = {};  // Store color for each field
  final Map<String, bool> headerBold = {};      // Store bold state
  final Map<String, bool> headerItalic = {};    // Store italic state
  final Map<String, bool> headerUnderline = {}; // Store underline state
  final Map<String, bool> headerStrikethrough = {}; // Store strikethrough state
  final Map<String, String> headerFonts = {};   // Store font name
  final Map<String, bool> headerUppercase = {}; // Store uppercase state
  final GlobalKey imageKey = GlobalKey();
  String? selectedHeader;

  Map<String, dynamic> get previewData => excelData.isNotEmpty ? excelData[0] : {};

  @override
  void initState() {
    super.initState();
    headers = widget.headers;
    imageBytes = widget.imageBytes;
    excelData = widget.excelData;
    emailColumn = widget.emailColumn;
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

  // Helper function to parse hex color strings
  Color _parseColor(String hexColor) {
    try {
      if (hexColor.startsWith('#')) {
        return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.black;
    } catch (e) {
      return Colors.black;
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
          headerFontSizes[selectedHeader!] = 22.0;
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
    
    final baseUrl = ApiConfig.baseUrl; // Use dynamic base URL
    final uri = Uri.parse(isPreview
        ? "$baseUrl/generate/generate-preview"
        : "$baseUrl/generate/generate-and-send-uploaded");


    final placeholders = headerPositions.map((key, value) {
      final adjustedDx = value.dx - offsetX;
      final adjustedDy = value.dy - offsetY;
      return MapEntry(key, {
        "x": adjustedDx * scale,
        "y": adjustedDy * scale,
        "font_size": (headerFontSizes[key] ?? 22.0) * scale,
        "color": headerColors[key] ?? "#000000",
        "bold": headerBold[key] ?? false,
        "italic": headerItalic[key] ?? false,
        "underline": headerUnderline[key] ?? false,
        "strikethrough": headerStrikethrough[key] ?? false,
        "font": headerFonts[key] ?? "Poppins",
        "uppercase": headerUppercase[key] ?? false,
      });
    });

    final sanitizedExcelData = excelData.map((row) => row.map((k, v) => MapEntry(k, v.toString()))).toList();

    final body = jsonEncode({
      "placeholders": placeholders,
      "excel_data": sanitizedExcelData,
      "template_bytes": base64Encode(imageBytes),
      "email_column": emailColumn,
      "subject": "Your Certificate",
      "content": "Congratulations! Please find your certificate attached.",
    });

    try {
      if (isPreview) {
        // Preview logic remains the same
        final response = await http.post(uri, headers: {"Content-Type": "application/json"}, body: body);
        if (mounted) setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Image.memory(response.bodyBytes),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close"))],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
        }
      } else {
        // Send All - Show live progress dialog
        if (mounted) setState(() => _isLoading = false);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SendingProgressDialog(
            url: uri.toString(),
            headers: {"Content-Type": "application/json"},
            body: body,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exception: $e")));
    }
  }

  Future<void> _downloadZip() async {
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
    
    final baseUrl = ApiConfig.baseUrl;
    final uri = Uri.parse("$baseUrl/generate/download-zip");

    final placeholders = headerPositions.map((key, value) {
      final adjustedDx = value.dx - offsetX;
      final adjustedDy = value.dy - offsetY;
      return MapEntry(key, {
        "x": adjustedDx * scale,
        "y": adjustedDy * scale,
        "font_size": (headerFontSizes[key] ?? 22.0) * scale,
        "color": headerColors[key] ?? "#000000",
        "bold": headerBold[key] ?? false,
        "italic": headerItalic[key] ?? false,
        "underline": headerUnderline[key] ?? false,
        "strikethrough": headerStrikethrough[key] ?? false,
        "font": headerFonts[key] ?? "Poppins",
        "uppercase": headerUppercase[key] ?? false,
      });
    });

    final sanitizedExcelData = excelData.map((row) => row.map((k, v) => MapEntry(k, v.toString()))).toList();

    final body = jsonEncode({
      "placeholders": placeholders,
      "excel_data": sanitizedExcelData,
      "template_bytes": base64Encode(imageBytes),
      "email_column": emailColumn,
    });

    try {
      final response = await http.post(uri, headers: {"Content-Type": "application/json"}, body: body);
      if (mounted) setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/zip');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'certificates.zip';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ZIP file downloaded successfully!")));
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
                // --- Font size slider ---
                if (selectedHeader != null && headerPositions.containsKey(selectedHeader))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        // Font Family
                        DropdownButton<String>(
                          value: headerFonts[selectedHeader!] ?? "Poppins",
                          underline: Container(), // Remove default underline
                          items: const [
                            DropdownMenuItem(value: "Poppins", child: Text("Poppins")),
                            DropdownMenuItem(value: "Roboto", child: Text("Roboto")),
                            DropdownMenuItem(value: "Tinos", child: Text("Tinos")),
                            DropdownMenuItem(value: "Arimo", child: Text("Arimo")),
                            DropdownMenuItem(value: "Manrope", child: Text("Manrope")),
                          ],
                          onChanged: (val) => setState(() => headerFonts[selectedHeader!] = val!),
                        ),
                        
                        // Vertical Divider
                        Container(height: 24, width: 1, color: Colors.grey[300]),

                        // Font Size (- 16 +)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                setState(() {
                                  double current = headerFontSizes[selectedHeader!] ?? 22.0;
                                  headerFontSizes[selectedHeader!] = (current - 1).clamp(8.0, 250.0);
                                });
                              },
                            ),
                            Text(
                              "${(headerFontSizes[selectedHeader!] ?? 22.0).round()}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                setState(() {
                                  double current = headerFontSizes[selectedHeader!] ?? 22.0;
                                  headerFontSizes[selectedHeader!] = (current + 1).clamp(8.0, 250.0);
                                });
                              },
                            ),
                          ],
                        ),

                        Container(height: 24, width: 1, color: Colors.grey[300]),

                        // Text Color
                        DropdownButton<String>(
                          underline: Container(),
                          icon: const Icon(Icons.format_color_text),
                          onChanged: (val) {
                            if (val != null) setState(() => headerColors[selectedHeader!] = val);
                          },
                          items: [
                            Colors.black, Colors.white, Colors.red, Colors.blue, 
                            Colors.green, Colors.orange, Colors.purple, Colors.brown
                          ].map((c) {
                             final hex = '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
                             return DropdownMenuItem(
                               value: hex,
                               child: Row(
                                 children: [
                                   Container(width: 16, height: 16, color: c),
                                   const SizedBox(width: 8),
                                   Text(hex),
                                 ],
                               ),
                             );
                          }).toList(),
                        ),

                        Container(height: 24, width: 1, color: Colors.grey[300]),

                        // Bold
                        IconButton(
                          icon: Icon(Icons.format_bold, 
                            color: (headerBold[selectedHeader!] ?? false) ? Colors.blue : Colors.black),
                          onPressed: () => setState(() {
                            headerBold[selectedHeader!] = !(headerBold[selectedHeader!] ?? false);
                          }),
                        ),

                        // Italic
                        IconButton(
                          icon: Icon(Icons.format_italic,
                            color: (headerItalic[selectedHeader!] ?? false) ? Colors.blue : Colors.black),
                          onPressed: () => setState(() {
                            headerItalic[selectedHeader!] = !(headerItalic[selectedHeader!] ?? false);
                          }),
                        ),

                        // Underline
                        IconButton(
                          icon: Icon(Icons.format_underlined,
                            color: (headerUnderline[selectedHeader!] ?? false) ? Colors.blue : Colors.black),
                          onPressed: () => setState(() {
                            headerUnderline[selectedHeader!] = !(headerUnderline[selectedHeader!] ?? false);
                          }),
                        ),
                        
                        // Strikethrough
                        IconButton(
                          icon: Icon(Icons.format_strikethrough,
                            color: (headerStrikethrough[selectedHeader!] ?? false) ? Colors.blue : Colors.black),
                          onPressed: () => setState(() {
                            headerStrikethrough[selectedHeader!] = !(headerStrikethrough[selectedHeader!] ?? false);
                          }),
                        ),

                        // Uppercase
                        IconButton(
                          icon: Icon(Icons.text_fields,
                            color: (headerUppercase[selectedHeader!] ?? false) ? Colors.blue : Colors.black),
                          onPressed: () => setState(() {
                            headerUppercase[selectedHeader!] = !(headerUppercase[selectedHeader!] ?? false);
                          }),
                        ),
                      ],
                    ),
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
                      left: pos.dx,
                      top: pos.dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            selectedHeader = key;
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            // Update position of the specific header being dragged
                            headerPositions[key] = headerPositions[key]! + details.delta;
                            // Also select it while dragging
                            selectedHeader = key;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: selectedHeader == key 
                                ? Colors.blue.withOpacity(0.3) 
                                : Colors.yellow.withOpacity(0.3),
                            border: selectedHeader == key 
                                ? Border.all(color: Colors.blue, width: 1) 
                                : null,
                          ),
                          child: Text(
                            // Apply uppercase transformation if enabled
                            (headerUppercase[key] ?? false)
                                ? (previewData[key]?.toString() ?? key).toUpperCase()
                                : (previewData[key]?.toString() ?? key),
                            style: TextStyle(
                              fontSize: headerFontSizes[key] ?? 22.0,
                              color: _parseColor(headerColors[key] ?? "#000000"),
                              fontFamily: headerFonts[key] ?? "Poppins",
                              fontWeight: (headerBold[key] ?? false) 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              fontStyle: (headerItalic[key] ?? false)
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              decoration: TextDecoration.combine([
                                if (headerUnderline[key] ?? false) TextDecoration.underline,
                                if (headerStrikethrough[key] ?? false) TextDecoration.lineThrough,
                              ]),
                            ),
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
                  onPressed: _isLoading ? null : _downloadZip,
                  icon: const Icon(Icons.download),
                  label: const Text("Download ZIP"),
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