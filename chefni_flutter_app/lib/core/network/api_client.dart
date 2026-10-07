import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown for any non-success response or transport failure. Callers get a
/// real error instead of a silent fallback to fake data.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNetworkError => statusCode == null;

  /// First validation message for [field], if the server reported one.
  String? errorFor(String field) => fieldErrors?[field]?.first;

  @override
  String toString() => message;
}

/// HTTP transport for the Chefni API: base URL resolution, bearer-token
/// persistence, JSON decoding and error mapping.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? resolveBaseUrl();

  final http.Client _http;
  final String _baseUrl;

  static const String _tokenKey = 'chefni_access_token';
  static const Duration _timeout = Duration(seconds: 20);

  String? _token;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Emulators cannot reach the host via 127.0.0.1: Android maps it to
  /// 10.0.2.2. Override at build time with
  /// `--dart-define=CHEFNI_API_URL=https://api.example.com`.
  static String resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('CHEFNI_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  /// Uploads a file as multipart/form-data, reporting progress from 0.0 to 1.0.
  ///
  /// Video uploads run far longer than the ordinary request timeout and need
  /// byte-level progress, so this bypasses [_send] rather than extending it.
  /// Uploads a file as multipart.
  ///
  /// Takes a byte stream rather than a [File] because the web build has no
  /// filesystem — the picker hands back bytes there, and a path only on
  /// mobile and desktop.
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String field,
    required Stream<List<int>> byteStream,
    required int totalBytes,
    required String filename,
    Map<String, String> fields = const {},
    void Function(double progress)? onProgress,
    Duration timeout = const Duration(minutes: 30),
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          if (hasToken) 'Authorization': 'Bearer $_token',
        })
        ..fields.addAll(fields)
        ..files.add(
          http.MultipartFile(
            field,
            _countingStream(byteStream, totalBytes, onProgress),
            totalBytes,
            filename: filename,
          ),
        );

      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);

      // The bytes are handed to the socket before the server replies; report
      // completion only once a response actually comes back.
      onProgress?.call(1.0);

      return _decode(response);
    } on TimeoutException {
      throw ApiException(
        'The upload took too long. Check your connection and try again.',
      );
    } on SocketException {
      throw ApiException(
        'Lost connection while uploading. Check your network and try again.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Upload failed: ${e.message}');
    }
  }

  /// Wraps the file stream so each emitted chunk advances the progress callback.
  Stream<List<int>> _countingStream(
    Stream<List<int>> source,
    int totalBytes,
    void Function(double)? onProgress,
  ) async* {
    var sent = 0;
    await for (final chunk in source) {
      sent += chunk.length;
      if (totalBytes > 0) {
        // Hold back the last percent for the server's response.
        onProgress?.call((sent / totalBytes).clamp(0.0, 0.99));
      }
      yield chunk;
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: query?.isEmpty ?? true ? null : query,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (hasToken) 'Authorization': 'Bearer $_token',
    };

    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);

      final streamed = await _http.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on TimeoutException {
      throw ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw ApiException(
        'Cannot reach the Chefni server. Check your connection and that the '
        'API is running at $_baseUrl.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } on FormatException {
      throw ApiException(
        'Unexpected response from the server (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    throw ApiException(
      json['message'] as String? ?? 'Request failed (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
      fieldErrors: _parseFieldErrors(json['errors']),
    );
  }

  Map<String, List<String>>? _parseFieldErrors(dynamic errors) {
    if (errors is! Map) return null;
    return errors.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as List?)?.map((e) => e.toString()).toList() ?? const [],
      ),
    );
  }

  void close() => _http.close();
}
