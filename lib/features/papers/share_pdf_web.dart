import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

Future<void> sharePdfBytes({
  required Uint8List bytes,
  required String filename,
  Rect? origin,
}) async {
  try {
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: filename,
        ),
      ],
      fileNameOverrides: [filename],
      sharePositionOrigin: origin ?? const Rect.fromLTWH(0, 0, 1, 1),
    );
    return;
  } catch (_) {
    // Desktop Chrome has no WeChat share target; fall back to download.
  }
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}
