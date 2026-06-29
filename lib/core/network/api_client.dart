import 'package:dio/dio.dart';
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

    // Surface the server's message when present, otherwise a generic one.
    final serverMsg = map['message'] ?? map['error'];
    throw ApiException(
      serverMsg is String ? serverMsg : 'Request failed ($status)',
      statusCode: status,
    );
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
