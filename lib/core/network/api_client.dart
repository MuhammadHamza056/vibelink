import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoints.dart';

/// Thin wrapper around [Dio] that centralises base config, timeouts and
/// error normalisation so feature code only deals with plain maps + a single
/// [ApiException] type.
class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                contentType: Headers.jsonContentType,
                // Don't throw for any status; we inspect it ourselves below.
                validateStatus: (_) => true,
              ),
            );

  final Dio _dio;

  /// Sets (or clears, when [token] is null) the bearer token sent on every
  /// subsequent request.
  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _handle(res);
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.post(path, data: body);
      return _handle(res);
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.put(path, data: body);
      return _handle(res);
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.patch(path, data: body);
      return _handle(res);
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  /// POSTs [path] as multipart/form-data: [fields] become form fields and,
  /// when [filePath] is given, the file is attached under [fileField]. Used to
  /// create a memory with a freshly picked/captured image.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    String? filePath,
    String fileField = 'image',
  }) async {
    try {
      final form = FormData.fromMap({
        ...fields,
        if (filePath != null)
          fileField: await MultipartFile.fromFile(
            filePath,
            filename: filePath.split('/').last,
          ),
      });
      debugPrint('📤 POST $path multipart | '
          'fields: ${form.fields} | '
          'files: ${form.files.map((f) => '${f.key}=${f.value.filename}').toList()}');
      final res = await _dio.post(path, data: form);
      return _handle(res);
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  /// PATCHes [path] as multipart/form-data: [fields] become form fields and,
  /// when [filePath] is given, the file is attached under [fileField]. Used to
  /// update the profile with a freshly picked/captured avatar image.
  Future<Map<String, dynamic>> patchMultipart(
    String path, {
    required Map<String, dynamic> fields,
    String? filePath,
    String fileField = 'avatar',
  }) async {
    try {
      final form = FormData.fromMap({
        ...fields,
        if (filePath != null)
          fileField: await MultipartFile.fromFile(
            filePath,
            filename: filePath.split('/').last,
          ),
      });
      final res = await _dio.patch(path, data: form);
      return _handle(res);
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.delete(path, data: body);
      return _handle(res);
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  Map<String, dynamic> _handle(Response res) {
    final status = res.statusCode ?? 0;
    final data = res.data;
    final map = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});

    if (status >= 200 && status < 300) return map;

    // Log the raw failure so validation errors are visible during debugging.
    debugPrint('❌ API ${res.requestOptions.method} '
        '${res.requestOptions.path} → $status | body: $data');

    final extracted = _extractError(data);
    final fallback = status > 0 ? 'Request failed ($status)' : 'Request failed';

    throw ApiException(extracted ?? fallback, statusCode: status);
  }

  /// Digs a human-readable message out of common API error-body shapes:
  /// - String body
  /// - {message: "..."}, {message: ["err1", "err2"]}
  /// - {error: "..."}, {error: {message: "..."}}
  /// - {errors: ["...", ...]}, {errors: [{msg|message: "..."}, ...]}
  /// - {detail: "..."}, {details: "..."}
  String? _extractError(dynamic data) {
    if (data == null) return null;

    if (data is String && data.trim().isNotEmpty) {
      final trimmed = data.trim();
      if (trimmed.startsWith('<html') || trimmed.startsWith('<!DOCTYPE')) {
        return null;
      }
      return _cleanErrorMessage(trimmed);
    }

    if (data is Map) {
      final map = data;

      // 1. Try 'message'
      final msg = map['message'];
      final extractedMsg = _parseErrorMessage(msg);
      if (extractedMsg != null) return extractedMsg;

      // 2. Try 'error'
      final err = map['error'];
      final extractedErr = _parseErrorMessage(err);
      if (extractedErr != null) return extractedErr;

      // 3. Try 'errors' list
      final errors = map['errors'];
      if (errors is List && errors.isNotEmpty) {
        final messages = <String>[];
        for (final item in errors) {
          final parsed = _parseErrorMessage(item);
          if (parsed != null) messages.add(parsed);
        }
        if (messages.isNotEmpty) return messages.join('\n');
      }

      // 4. Try 'msg', 'detail', 'details'
      for (final key in ['msg', 'detail', 'details']) {
        final val = map[key];
        final parsed = _parseErrorMessage(val);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  String? _parseErrorMessage(dynamic val) {
    if (val == null) return null;
    if (val is String && val.trim().isNotEmpty) {
      return _cleanErrorMessage(val);
    }
    if (val is List && val.isNotEmpty) {
      final list = val
          .map((e) => _parseErrorMessage(e))
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
      if (list.isNotEmpty) return list.join('\n');
    }
    if (val is Map) {
      return _extractError(val);
    }
    return null;
  }

  String _cleanErrorMessage(String msg) {
    var cleaned = msg.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:[A-Za-z0-9_]*[E|e]xception|[a-zA-Z\s]+exception|Error):\s*',
        caseSensitive: false,
      ),
      '',
    ).trim();

    if (cleaned.isEmpty) return msg;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Is the server running?';
      case DioExceptionType.connectionError:
        return 'Could not reach the server.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}

/// Exception with a user-presentable [message] and optional [statusCode].
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
