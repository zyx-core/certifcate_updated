import 'dart:ui';
import 'package:flutter/material.dart';

class CertificateField {
  final Offset position;
  final TextStyle style;

  CertificateField({
    required this.position,
    required this.style,
  });

  // Optional: Convert to/from map if you ever need serialization
  Map<String, dynamic> toMap() {
    return {
      'dx': position.dx,
      'dy': position.dy,
      'fontSize': style.fontSize,
      'fontWeight': style.fontWeight?.index,
      'fontStyle': style.fontStyle?.index,
      'color': style.color?.value,
    };
  }

  factory CertificateField.fromMap(Map<String, dynamic> map) {
    return CertificateField(
      position: Offset(map['dx'], map['dy']),
      style: TextStyle(
        fontSize: map['fontSize']?.toDouble() ?? 14,
        fontWeight: map['fontWeight'] != null
            ? FontWeight.values[map['fontWeight']]
            : FontWeight.normal,
        fontStyle: map['fontStyle'] != null
            ? FontStyle.values[map['fontStyle']]
            : FontStyle.normal,
        color: map['color'] != null ? Color(map['color']) : Colors.black,
      ),
    );
  }
}
