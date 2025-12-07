import 'package:dio/dio.dart';
import 'package:flutter_pos_transfer/core/network/api_client.dart';
import 'package:flutter_pos_transfer/core/network/api_constants.dart';


class AuthRepository {
  final DioClient _dioClient = DioClient();

  Future<Map<String, dynamic>> getAccessToken() async {
    try {
      final dio = _dioClient.getAuthClient();
      
      final response = await dio.post(
        ApiConstants.tokenEndpoint,
        data: {
          'grant_type': ApiConstants.grantType,
          'scope': ApiConstants.scope,
          'username': ApiConstants.username,
          'password': ApiConstants.password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get access token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Auth error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}