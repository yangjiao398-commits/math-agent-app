import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePdfBytes({
  required Uint8List bytes,
  required String filename,
  Rect? origin,
}) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$filename';
  await File(path).writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(path, mimeType: 'application/pdf', name: filename)],
    sharePositionOrigin: origin ?? const Rect.fromLTWH(0, 0, 1, 1),
  );
}
