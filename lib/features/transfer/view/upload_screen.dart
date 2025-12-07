import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pos_transfer/features/transfer/model/transfer_item.dart';
import '../cubit/transfer_cubit.dart';
import '../cubit/transfer_state.dart';
import '../../../core/utils/storage_service.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  Future<void> _pickAndUploadFile(BuildContext context) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        _showError(context, 'Could not access file');
        return;
      }

      // Check file size
      final fileSize = file.size;
      if (fileSize == 0) {
        _showError(context, 'File is empty');
        return;
      }

      // Check available storage
      final storageService = StorageService();
      final hasSpace = await storageService.hasEnoughSpace(fileSize);

      if (!hasSpace) {
        _showError(context, 'Not enough storage space');
        return;
      }

      // Start upload
      if (context.mounted) {
        context.read<TransferCubit>().startUpload(
          filePath,
          file.name,
          fileSize,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading ${file.name}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick file: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferCubit, TransferState>(
      builder: (context, state) {
        final uploads = state.transfers
            .where((t) => t.type == TransferType.upload)
            .toList();

        return Column(
          children: [
            // Upload Button Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Upload Files',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select files to upload to the server',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _pickAndUploadFile(context),
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Pick File'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Recent Uploads List
            Expanded(
              child: uploads.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No uploads yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: uploads.length,
                itemBuilder: (context, index) {
                  final upload = uploads[uploads.length - 1 - index];
                  return _UploadItemCard(upload: upload);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UploadItemCard extends StatelessWidget {
  final TransferItem upload;

  const _UploadItemCard({required this.upload});

  IconData _getStatusIcon() {
    switch (upload.status) {
      case TransferStatus.completed:
        return Icons.check_circle;
      case TransferStatus.failed:
        return Icons.error;
      case TransferStatus.inProgress:
      case TransferStatus.pending:
        return Icons.upload;
      case TransferStatus.paused:
        return Icons.pause_circle;
      case TransferStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor() {
    switch (upload.status) {
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.inProgress:
      case TransferStatus.pending:
        return Colors.blue;
      case TransferStatus.paused:
        return Colors.orange;
      case TransferStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upload.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storageService.formatBytes(upload.fileSize),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (upload.status == TransferStatus.inProgress ||
                upload.status == TransferStatus.pending)
              Column(
                children: [
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: upload.progress,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(upload.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.pause),
                            iconSize: 20,
                            onPressed: () {
                              context.read<TransferCubit>()
                                  .pauseTransfer(upload.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            onPressed: () {
                              context.read<TransferCubit>()
                                  .cancelTransfer(upload.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

            if (upload.status == TransferStatus.paused)
              Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<TransferCubit>()
                                .resumeTransfer(upload.id);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          context.read<TransferCubit>()
                              .cancelTransfer(upload.id);
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),

            if (upload.status == TransferStatus.failed)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    upload.errorMessage ?? 'Upload failed',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<TransferCubit>()
                            .retryTransfer(upload.id);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}