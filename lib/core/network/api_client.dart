import 'package:dio/dio.dart';
import 'package:flutter_pos_transfer/core/network/api_constants.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: ApiConstants.timeoutSeconds),
        receiveTimeout: Duration(seconds: ApiConstants.timeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;

  // Auth client with basic auth
  Dio getAuthClient() {
    final authDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.authBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': ApiConstants.basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );
    return authDio;
  }

  // API client with bearer token
  Dio getApiClient(String token) {
    final apiDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: Duration(seconds: ApiConstants.timeoutSeconds),
        receiveTimeout: Duration(seconds: ApiConstants.timeoutSeconds),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    apiDio.interceptors.add(LogInterceptor(
      requestBody: false, // Don't log file data
      responseBody: true,
      error: true,
    ));

    return apiDio;
  }
}