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
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};

    if (status >= 200 && status < 300) return map;

    // Log the raw failure so validation errors are visible during debugging.
    debugPrint('❌ API ${res.requestOptions.method} '
        '${res.requestOptions.path} → $status | body: $data');

    // Fall back to the raw body so the error is readable even without a
    // console (shown in the toast). Truncated to keep it presentable.
    final raw = data == null ? '' : data.toString();
    final fallback = raw.isEmpty
        ? 'Request failed ($status)'
        : 'Request failed ($status): '
            '${raw.length > 300 ? '${raw.substring(0, 300)}…' : raw}';

    throw ApiException(_extractError(map) ?? fallback, statusCode: status);
  }

  /// Digs a human-readable message out of the common error-body shapes:
  /// {message}, {error}, {error:{message}}, or {errors:[{msg|message}]}.
  String? _extractError(Map<String, dynamic> map) {
    final msg = map['message'] ?? map['error'] ?? map['msg'];
    if (msg is String && msg.isNotEmpty) return msg;
    if (msg is Map && msg['message'] is String) return msg['message'] as String;

    final errors = map['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String) return first;
      if (first is Map) {
        final m = first['msg'] ?? first['message'];
        if (m is String) return m;
      }
    }
    return null;
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
