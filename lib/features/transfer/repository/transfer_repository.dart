import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_pos_transfer/core/network/api_client.dart';
import 'package:flutter_pos_transfer/core/network/api_constants.dart';
import 'package:flutter_pos_transfer/features/transfer/model/uploaded_file_model.dart';

import '../../../core/utils/storage_service.dart';


typedef ProgressCallback = void Function(double progress);

class TransferRepository {
  final DioClient _dioClient = DioClient();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    required String token,
    required CancelToken cancelToken,
    required ProgressCallback onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final dio = _dioClient.getApiClient(token);

      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'jsonPatch': '[{"op":"replace","path":"/updateBy","value":123}]',
      });

      final response = await dio.patch(
        ApiConstants.updateAppEndpoint,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          final progress = sent / total;
          onProgress(progress);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        String? downloadUrl;

        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          downloadUrl = data['fileUrl'] as String? ??
              data['downloadUrl'] as String? ??
              data['url'] as String? ??
              data['appLink'] as String?;
        }

        downloadUrl ??= '${ApiConstants.apiBaseUrl}/files/$fileName';

        return {
          'success': true,
          'downloadUrl': downloadUrl,
          'fileName': fileName,
        };
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Upload cancelled');
      } else if (e.response != null) {
        throw Exception('Upload error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<String> downloadFile({
    required String url,
    required String fileName,
    required String token,
    required CancelToken cancelToken,
    required ProgressCallback onProgress,
  }) async {
    try {
      await _storageService.requestStoragePermission();

      final downloadDir = await _storageService.getDownloadDirectory();
      final savePath = '$downloadDir/$fileName';

      final dio = _dioClient.getApiClient(token);

      await dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      return savePath;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Download cancelled');
      } else if (e.response != null) {
        throw Exception('Download error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// Get uploaded files with proper model parsing
  Future<List<UploadedFileModel>> getUploadedFiles(String token) async {
    try {
      final dio = _dioClient.getApiClient(token);

      final response = await dio.get(
        ApiConstants.getAppsEndpoint,
        queryParameters: {
          'companyId': ApiConstants.companyId,
        },
      );

      print('📥 API Response Status: ${response.statusCode}');
      print('📥 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> dataList = [];

        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;

          // Check for dataList (your API format)
          if (data.containsKey('dataList') && data['dataList'] is List) {
            dataList = data['dataList'] as List;
            print('✅ Found dataList with ${dataList.length} items');
          }
          // Fallback to other common formats
          else if (data.containsKey('data') && data['data'] is List) {
            dataList = data['data'] as List;
            print('✅ Found data with ${dataList.length} items');
          }
          else if (data.containsKey('items') && data['items'] is List) {
            dataList = data['items'] as List;
            print('✅ Found items with ${dataList.length} items');
          }
          else if (data.containsKey('files') && data['files'] is List) {
            dataList = data['files'] as List;
            print('✅ Found files with ${dataList.length} items');
          } else {
            print('⚠️ No recognized list key found in response');
            print('Available keys: ${data.keys.toList()}');
          }
        } else if (response.data is List) {
          dataList = response.data as List;
          print('✅ Response is a direct list with ${dataList.length} items');
        }

        // Filter only active items with download links
        final files = dataList
            .map((json) => UploadedFileModel.fromJson(json as Map<String, dynamic>))
            .where((file) =>
        file.isActive == 1 &&
            file.canDownload
        )
            .toList();

        print('✅ Parsed ${files.length} downloadable files');

        return files;
      } else {
        throw Exception('Failed to get files: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      if (e.response != null) {
        print('❌ Response: ${e.response?.data}');
        throw Exception('Error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('❌ Exception: $e');
      throw Exception('Failed to get files: $e');
    }
  }

  /// Get raw uploaded files (backward compatibility)
  Future<List<Map<String, dynamic>>> getUploadedFilesRaw(String token) async {
    final files = await getUploadedFiles(token);
    return files.map((file) => file.toJson()).toList();
  }
}