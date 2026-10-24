import 'dart:io';
import 'dart:math';

import 'package:dart_frog/dart_frog.dart';

const _maxBytes = 5 * 1024 * 1024; // 5 MB

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final formData = await context.request.formData();
  final file = formData.files['image'];
  if (file == null) return _badRequest('Choose an image to upload');

  final bytes = await file.readAsBytes();
  if (bytes.length > _maxBytes) {
    return _badRequest('Image must be 5 MB or smaller');
  }

  // Look at the file's real content, not its name or the type the app claims.
  final extension = _imageExtension(bytes);
  if (extension == null) {
    return _badRequest('Only JPG, PNG or WebP images are allowed');
  }

  // Make our OWN file name. Never use the name the phone sent.
  final random = Random.secure().nextInt(1 << 32).toRadixString(16);
  final fileName =
      '${DateTime.now().millisecondsSinceEpoch}_$random.$extension';

  final folder = Directory('public/uploads');
  await folder.create(recursive: true);
  await File('${folder.path}/$fileName').writeAsBytes(bytes);

  return Response.json(
    statusCode: HttpStatus.created,
    body: {'url': '/uploads/$fileName'},
  );
}

/// Every image format starts with special "magic bytes". Check them.
String? _imageExtension(List<int> b) {
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF)
    return 'jpg';
  if (b.length > 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return 'png';
  }
  if (b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return 'webp';
  }
  return null;
}

Response _badRequest(String error) => Response.json(
  statusCode: HttpStatus.badRequest,
  body: {'error': error},
);
