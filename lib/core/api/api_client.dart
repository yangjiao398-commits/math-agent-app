import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/env.dart';

class MultipartImage {
  const MultipartImage({
    required this.bytes,
    required this.filename,
    this.mime = 'image/jpeg',
  });

  final Uint8List bytes;
  final String filename;
  final String mime;
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  bool get needsLogin => status == 401;
  bool get needsPay => status == 402;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient, String? token})
      : _http = httpClient ?? http.Client(),
        _token = token;

  final http.Client _http;
  String? _token;

  void setToken(String? token) => _token = token;

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBase}$path');

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) headers['Content-Type'] = 'application/json';
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _http.get(_uri(path), headers: _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final res = await _http.post(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body ?? const {}),
    );
    return _decode(res);
  }

  Future<Uint8List> getBytes(String path) async {
    final res = await _http.get(
      _uri(path),
      headers: {
        ..._headers(),
        'Accept': 'application/pdf, application/json',
      },
    );
    final type = res.headers['content-type'] ?? '';
    if (res.statusCode >= 400 || type.contains('application/json')) {
      _decode(res);
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, '下载失败（${res.statusCode}）');
    }
    return res.bodyBytes;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    required List<MultipartImage> files,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    req.headers.addAll(_headers());
    req.fields.addAll(fields);
    for (final file in files) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes,
          filename: file.filename,
          contentType: MediaType.parse(file.mime),
        ),
      );
    }
    final streamed = await _http.send(req);
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(res.statusCode, '接口未返回 JSON（${res.statusCode}）');
    }
    if (res.statusCode >= 400) {
      final detail = data['detail'];
      throw ApiException(
        res.statusCode,
        detail is String ? detail : jsonEncode(detail ?? data),
      );
    }
    return data;
  }
}
