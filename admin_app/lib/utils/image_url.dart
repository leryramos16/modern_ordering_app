import '../config.dart';

/// "/uploads/a.jpg" → "http://localhost:8081/uploads/a.jpg"
String? fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path; // already a full address
  return '$apiBaseUrl$path';
}
