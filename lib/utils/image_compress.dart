import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Compress image bytes to at most [maxBytes] (default 2 MB), JPEG output.
Future<Uint8List> compressImageForUpload(
  Uint8List input, {
  int maxBytes = 2 * 1024 * 1024,
  int maxDimension = 2000,
}) async {
  if (input.length <= maxBytes) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;
  }

  var decoded = img.decodeImage(input);
  if (decoded == null) return input;

  final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
  if (longest > maxDimension) {
    decoded = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxDimension : null,
      height: decoded.height > decoded.width ? maxDimension : null,
    );
  }

  var quality = 88;
  Uint8List output = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));

  while (output.length > maxBytes && quality > 40) {
    quality -= 8;
    output = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }

  if (output.length > maxBytes && (decoded.width > 800 || decoded.height > 800)) {
    decoded = img.copyResize(
      decoded,
      width: (decoded.width * 0.75).round(),
      height: (decoded.height * 0.75).round(),
    );
    quality = 82;
    output = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    while (output.length > maxBytes && quality > 35) {
      quality -= 8;
      output = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    }
  }

  return output;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
