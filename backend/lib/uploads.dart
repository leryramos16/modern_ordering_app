import 'dart:io';

/// A photo is optional, but if one is sent it must be one of OUR uploads.
String? imageUrlError(String url) {
  if (url.isEmpty) return null;
  if (!url.startsWith('/uploads/') || url.contains('..') || url.length > 255) {
    return 'Invalid image';
  }
  return null;
}

/// Deletes an uploaded photo from disk. Quietly ignores anything that isn't ours.
Future<void> deleteUpload(String? url) async {
  if (url == null || url.isEmpty || imageUrlError(url) != null) return;
  final file = File('public$url'); // "/uploads/a.jpg" → "public/uploads/a.jpg"
  if (await file.exists()) await file.delete();
}
