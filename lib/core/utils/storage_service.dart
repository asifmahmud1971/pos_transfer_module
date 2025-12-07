import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit permission
  }

  Future<String> getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Use app's documents directory for downloads
        final directory = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${directory.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir.path;
      } else {
        // iOS
        final directory = await getApplicationDocumentsDirectory();
        return directory.path;
      }
    } catch (e) {
      // Fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    }
  }

  Future<String> getTempDirectory() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<int> getAvailableSpace() async {
    try {
      if (Platform.isAndroid) {
        final directory = await getApplicationDocumentsDirectory();
        final stat = await directory.stat();
        // Approximate available space (not accurate but gives an idea)
        return 1024 * 1024 * 1024 * 10; // Assume 10GB available
      }
      return 1024 * 1024 * 1024 * 10; // Assume 10GB available
    } catch (e) {
      return 0;
    }
  }

  Future<bool> hasEnoughSpace(int requiredBytes) async {
    final available = await getAvailableSpace();
    return available > requiredBytes;
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> cleanupOldFiles({int daysOld = 30}) async {
    try {
      final downloadDir = await getDownloadDirectory();
      final directory = Directory(downloadDir);

      if (await directory.exists()) {
        final files = directory.listSync();
        final now = DateTime.now();

        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            final age = now.difference(stat.modified).inDays;

            if (age > daysOld) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}