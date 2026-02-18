import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      // In production (served from same origin), use the current origin
      // html.window.location.origin gives "http://domain.com" without trailing slash
      // But we need to be careful if we are not on web. 
      // Since this is a web build, we can rely on relative paths or origin.
      if (kIsWeb) {
         final origin = html.window.location.origin;
         return origin;
      }
      return "http://localhost:8000"; // Fallback for release data desktop?
    } else {
      // In debug mode, assume standard FastAPI port
      return "http://localhost:8000";
    }
  }
}
