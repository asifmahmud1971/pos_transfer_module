import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_transfer/features/transfer/model/transfer_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // Import Dio for CancelToken
import '../../../core/utils/notification_service.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../repository/transfer_repository.dart';
import 'transfer_state.dart';

class TransferCubit extends Cubit<TransferState> {
  final TransferRepository transferRepository;
  final AuthCubit authCubit;
  final NotificationService _notificationService = NotificationService();

  final Map<String, CancelToken> _cancelTokens = {};

  TransferCubit({
    required this.transferRepository,
    required this.authCubit,
  }) : super(const TransferState());

  Future<void> loadPersistedTransfers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transfersJson = prefs.getStringList('transfers') ?? [];

      final transfers = transfersJson
          .map((json) => TransferItem.fromJson(jsonDecode(json)))
          .toList();

      // Filter out very old completed transfers (keep last 50)
      final filtered = transfers.where((t) {
        if (t.status == TransferStatus.completed) {
          final age = DateTime.now().difference(t.createdAt).inDays;
          return age < 7; // Keep completed transfers for 7 days
        }
        return true;
      }).take(50).toList();

      emit(state.copyWith(transfers: filtered));
    } catch (e) {
      // Ignore persistence errors
    }
  }

  Future<void> _persistTransfers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transfersJson = state.transfers
          .map((t) => jsonEncode(t.toJson()))
          .toList();
      await prefs.setStringList('transfers', transfersJson);
    } catch (e) {
      // Ignore persistence errors
    }
  }

  Future<void> startUpload(String filePath, String fileName, int fileSize) async {
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();

    final transfer = TransferItem(
      id: transferId,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      type: TransferType.upload,
      status: TransferStatus.pending,
      createdAt: DateTime.now(),
    );

    _addTransfer(transfer);
    await _upload(transferId);
  }

  Future<void> _upload(String transferId) async {
    final transfer = state.getTransferById(transferId);
    if (transfer == null) return;

    try {
      // Update status to in progress
      _updateTransfer(
        transferId,
        transfer.copyWith(status: TransferStatus.inProgress),
      );

      // Get auth token
      final token = await authCubit.getToken();

      // Create cancel token
      final cancelToken = CancelToken();
      _cancelTokens[transferId] = cancelToken;

      // Upload file with progress callback
      final result = await transferRepository.uploadFile(
        filePath: transfer.filePath,
        fileName: transfer.fileName,
        token: token,
        cancelToken: cancelToken,
        onProgress: (progress) {
          _updateTransfer(
            transferId,
            transfer.copyWith(progress: progress),
          );

          // Update notification
          _notificationService.showTransferNotification(
            id: transferId,
            title: 'Uploading ${transfer.fileName}',
            body: '${(progress * 100).toStringAsFixed(0)}% complete',
            progress: (progress * 100).toInt(),
            showProgress: true,
          );
        },
      );

      // Upload completed
      final downloadUrl = result['downloadUrl'] as String?;

      _updateTransfer(
        transferId,
        transfer.copyWith(
          status: TransferStatus.completed,
          progress: 1.0,
          downloadUrl: downloadUrl,
          completedAt: DateTime.now(),
        ),
      );

      // Show completion notification
      await _notificationService.showCompletionNotification(
        id: transferId,
        title: 'Upload Complete',
        body: '${transfer.fileName} uploaded successfully',
        isSuccess: true,
      );

      _cancelTokens.remove(transferId);
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        // Upload was cancelled, don't update to failed
        return;
      }

      _updateTransfer(
        transferId,
        transfer.copyWith(
          status: TransferStatus.failed,
          errorMessage: e.toString(),
        ),
      );

      await _notificationService.showCompletionNotification(
        id: transferId,
        title: 'Upload Failed',
        body: transfer.fileName,
        isSuccess: false,
      );

      _cancelTokens.remove(transferId);
    }
  }

  Future<void> startDownload(String downloadUrl, String fileName, int fileSize) async {
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();

    final transfer = TransferItem(
      id: transferId,
      fileName: fileName,
      filePath: '', // Will be set after download
      fileSize: fileSize,
      type: TransferType.download,
      status: TransferStatus.pending,
      downloadUrl: downloadUrl,
      createdAt: DateTime.now(),
    );

    _addTransfer(transfer);
    await _download(transferId);
  }

  Future<void> _download(String transferId) async {
    final transfer = state.getTransferById(transferId);
    if (transfer == null || transfer.downloadUrl == null) return;

    try {
      _updateTransfer(
        transferId,
        transfer.copyWith(status: TransferStatus.inProgress),
      );

      final token = await authCubit.getToken();
      final cancelToken = CancelToken();
      _cancelTokens[transferId] = cancelToken;

      final savePath = await transferRepository.downloadFile(
        url: transfer.downloadUrl!,
        fileName: transfer.fileName,
        token: token,
        cancelToken: cancelToken,
        onProgress: (progress) {
          _updateTransfer(
            transferId,
            transfer.copyWith(progress: progress),
          );

          _notificationService.showTransferNotification(
            id: transferId,
            title: 'Downloading ${transfer.fileName}',
            body: '${(progress * 100).toStringAsFixed(0)}% complete',
            progress: (progress * 100).toInt(),
            showProgress: true,
          );
        },
      );

      _updateTransfer(
        transferId,
        transfer.copyWith(
          status: TransferStatus.completed,
          progress: 1.0,
          filePath: savePath,
          completedAt: DateTime.now(),
        ),
      );

      await _notificationService.showCompletionNotification(
        id: transferId,
        title: 'Download Complete',
        body: '${transfer.fileName} saved to Downloads',
        isSuccess: true,
      );

      _cancelTokens.remove(transferId);
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        return;
      }

      _updateTransfer(
        transferId,
        transfer.copyWith(
          status: TransferStatus.failed,
          errorMessage: e.toString(),
        ),
      );

      await _notificationService.showCompletionNotification(
        id: transferId,
        title: 'Download Failed',
        body: transfer.fileName,
        isSuccess: false,
      );

      _cancelTokens.remove(transferId);
    }
  }

  void pauseTransfer(String transferId) {
    final transfer = state.getTransferById(transferId);
    if (transfer == null) return;

    // Cancel the ongoing request
    _cancelTokens[transferId]?.cancel('Paused by user');
    _cancelTokens.remove(transferId);

    _updateTransfer(
      transferId,
      transfer.copyWith(status: TransferStatus.paused),
    );

    _notificationService.cancelNotification(transferId);
  }

  Future<void> resumeTransfer(String transferId) async {
    final transfer = state.getTransferById(transferId);
    if (transfer == null) return;

    if (transfer.type == TransferType.upload) {
      await _upload(transferId);
    } else {
      await _download(transferId);
    }
  }

  Future<void> retryTransfer(String transferId) async {
    final transfer = state.getTransferById(transferId);
    if (transfer == null) return;

    _updateTransfer(
      transferId,
      transfer.copyWith(
        status: TransferStatus.pending,
        progress: 0.0,
        errorMessage: null,
        retryCount: transfer.retryCount + 1,
      ),
    );

    if (transfer.type == TransferType.upload) {
      await _upload(transferId);
    } else {
      await _download(transferId);
    }
  }

  void cancelTransfer(String transferId) {
    final transfer = state.getTransferById(transferId);
    if (transfer == null) return;

    _cancelTokens[transferId]?.cancel('Cancelled by user');
    _cancelTokens.remove(transferId);

    _updateTransfer(
      transferId,
      transfer.copyWith(status: TransferStatus.cancelled),
    );

    _notificationService.cancelNotification(transferId);
  }

  void removeTransfer(String transferId) {
    final transfers = state.transfers.where((t) => t.id != transferId).toList();
    emit(state.copyWith(transfers: transfers));
    _persistTransfers();
  }

  void _addTransfer(TransferItem transfer) {
    final transfers = [...state.transfers, transfer];
    emit(state.copyWith(transfers: transfers));
    _persistTransfers();
  }

  void _updateTransfer(String transferId, TransferItem updatedTransfer) {
    final transfers = state.transfers.map((t) {
      return t.id == transferId ? updatedTransfer : t;
    }).toList();

    emit(state.copyWith(transfers: transfers));
    _persistTransfers();
  }
}