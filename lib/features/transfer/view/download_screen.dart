import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_transfer/features/transfer/model/transfer_item.dart';
import 'package:flutter_pos_transfer/features/transfer/model/uploaded_file_model.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/transfer_cubit.dart';
import '../cubit/transfer_state.dart';
import '../repository/transfer_repository.dart';
import '../../../core/utils/storage_service.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  List<UploadedFileModel> _availableFiles = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableFiles();
  }

  Future<void> _loadAvailableFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await context.read<AuthCubit>().getToken();
      final repository = TransferRepository();
      final files = await repository.getUploadedFiles(token);

      setState(() {
        _availableFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startDownload(UploadedFileModel file) {
    if (file.effectiveDownloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<TransferCubit>().startDownload(
      file.effectiveDownloadUrl,
      file.displayName,
      file.fileSize ?? 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${file.displayName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferCubit, TransferState>(
      builder: (context, state) {
        final downloads = state.transfers
            .where((t) => t.type == TransferType.download)
            .toList();

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_download,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Download Files',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Download uploaded files from the server',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Available Files'),
                        Tab(text: 'My Downloads'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildAvailableFilesTab(),
                          _buildMyDownloadsTab(downloads),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableFilesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load files',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAvailableFiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No files available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAvailableFiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailableFiles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableFiles.length,
        itemBuilder: (context, index) {
          final file = _availableFiles[index];
          return _AvailableFileCard(
            file: file,
            onDownload: () => _startDownload(file),
          );
        },
      ),
    );
  }

  Widget _buildMyDownloadsTab(List<TransferItem> downloads) {
    if (downloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No downloads yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final download = downloads[downloads.length - 1 - index];
        return _DownloadItemCard(download: download);
      },
    );
  }
}

class _AvailableFileCard extends StatelessWidget {
  final UploadedFileModel file;
  final VoidCallback onDownload;

  const _AvailableFileCard({
    required this.file,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getPlatformColor(file.appPlatform).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPlatformIcon(file.appPlatform),
            size: 30,
            color: _getPlatformColor(file.appPlatform),
          ),
        ),
        title: Text(
          file.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'v${file.appVersionName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    file.appPlatform,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (file.fileExtension.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      file.fileExtension,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (file.appDesc != null && file.appDesc!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                file.appDesc!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: file.canDownload ? onDownload : null,
          color: file.canDownload ? Colors.blue : Colors.grey,
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.apple;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.computer;
      default:
        return Icons.apps;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Colors.green;
      case 'ios':
        return Colors.blue;
      case 'web':
        return Colors.orange;
      case 'windows':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// Keep the existing _DownloadItemCard widget from the previous code
class _DownloadItemCard extends StatelessWidget {
  final TransferItem download;

  const _DownloadItemCard({required this.download});

  IconData _getStatusIcon() {
    switch (download.status) {
      case TransferStatus.completed:
        return Icons.check_circle;
      case TransferStatus.failed:
        return Icons.error;
      case TransferStatus.inProgress:
      case TransferStatus.pending:
        return Icons.download;
      case TransferStatus.paused:
        return Icons.pause_circle;
      case TransferStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor() {
    switch (download.status) {
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
                        download.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storageService.formatBytes(download.fileSize),
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

            if (download.status == TransferStatus.inProgress ||
                download.status == TransferStatus.pending)
              Column(
                children: [
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: download.progress,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(download.progress * 100).toStringAsFixed(1)}%',
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
                                  .pauseTransfer(download.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            onPressed: () {
                              context.read<TransferCubit>()
                                  .cancelTransfer(download.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

            if (download.status == TransferStatus.completed)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Saved to: ${download.filePath}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

            if (download.status == TransferStatus.paused)
              Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<TransferCubit>()
                                .resumeTransfer(download.id);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          context.read<TransferCubit>()
                              .cancelTransfer(download.id);
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),

            if (download.status == TransferStatus.failed)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    download.errorMessage ?? 'Download failed',
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
                            .retryTransfer(download.id);
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