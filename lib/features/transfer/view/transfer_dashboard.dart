import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_transfer/features/transfer/model/transfer_item.dart';
import '../cubit/transfer_cubit.dart';
import '../cubit/transfer_state.dart';
import '../../../core/utils/storage_service.dart';

class TransferDashboard extends StatelessWidget {
  const TransferDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Dashboard'),
        elevation: 2,
      ),
      body: BlocBuilder<TransferCubit, TransferState>(
        builder: (context, state) {
          final activeTransfers = state.activeTransfers;
          final completedTransfers = state.completedTransfers;
          final failedTransfers = state.failedTransfers;

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Summary Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Active',
                          count: activeTransfers.length,
                          icon: Icons.sync,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Completed',
                          count: completedTransfers.length,
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Failed',
                          count: failedTransfers.length,
                          icon: Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  tabs: [
                    Tab(
                      text: 'Active (${activeTransfers.length})',
                    ),
                    Tab(
                      text: 'Completed (${completedTransfers.length})',
                    ),
                    Tab(
                      text: 'Failed (${failedTransfers.length})',
                    ),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTransferList(context, activeTransfers, 'active'),
                      _buildTransferList(context, completedTransfers, 'completed'),
                      _buildTransferList(context, failedTransfers, 'failed'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransferList(
      BuildContext context,
      List<TransferItem> transfers,
      String type,
      ) {
    if (transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'active'
                  ? Icons.inbox
                  : type == 'completed'
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'active'
                  ? 'No active transfers'
                  : type == 'completed'
                  ? 'No completed transfers'
                  : 'No failed transfers',
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
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transfer = transfers[transfers.length - 1 - index];
        return _TransferDashboardCard(transfer: transfer);
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferDashboardCard extends StatelessWidget {
  final TransferItem transfer;

  const _TransferDashboardCard({required this.transfer});

  IconData _getTypeIcon() {
    return transfer.type == TransferType.upload
        ? Icons.upload
        : Icons.download;
  }

  IconData _getStatusIcon() {
    switch (transfer.status) {
      case TransferStatus.completed:
        return Icons.check_circle;
      case TransferStatus.failed:
        return Icons.error;
      case TransferStatus.inProgress:
      case TransferStatus.pending:
        return transfer.type == TransferType.upload
            ? Icons.upload
            : Icons.download;
      case TransferStatus.paused:
        return Icons.pause_circle;
      case TransferStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor() {
    switch (transfer.status) {
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

  String _getStatusText() {
    switch (transfer.status) {
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.inProgress:
        return 'In Progress';
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.paused:
        return 'Paused';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDuration(DateTime start, DateTime? end) {
    final duration = (end ?? DateTime.now()).difference(start);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
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
                // Type Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transfer.type == TransferType.upload
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: transfer.type == TransferType.upload
                        ? Colors.blue
                        : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // File Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            storageService.formatBytes(transfer.fileSize),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Icon
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 32,
                ),
              ],
            ),

            // Progress Bar (for active transfers)
            if (transfer.status == TransferStatus.inProgress ||
                transfer.status == TransferStatus.pending)
              Column(
                children: [
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: transfer.progress,
                    backgroundColor: Colors.grey[200],
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(transfer.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDuration(transfer.createdAt, null),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // Metadata
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetadataItem(
                  icon: Icons.access_time,
                  label: 'Started',
                  value: _formatTime(transfer.createdAt),
                ),
                if (transfer.completedAt != null)
                  _MetadataItem(
                    icon: Icons.check,
                    label: 'Completed',
                    value: _formatTime(transfer.completedAt!),
                  ),
                if (transfer.retryCount > 0)
                  _MetadataItem(
                    icon: Icons.refresh,
                    label: 'Retries',
                    value: transfer.retryCount.toString(),
                  ),
              ],
            ),

            // Error Message
            if (transfer.status == TransferStatus.failed &&
                transfer.errorMessage != null)
              Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            transfer.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Action Buttons
            const SizedBox(height: 12),
            Row(
              children: [
                // Pause/Resume
                if (transfer.status == TransferStatus.inProgress ||
                    transfer.status == TransferStatus.pending)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<TransferCubit>()
                            .pauseTransfer(transfer.id);
                      },
                      icon: const Icon(Icons.pause, size: 18),
                      label: const Text('Pause'),
                    ),
                  ),

                if (transfer.status == TransferStatus.paused)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<TransferCubit>()
                            .resumeTransfer(transfer.id);
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Resume'),
                    ),
                  ),

                // Retry
                if (transfer.status == TransferStatus.failed)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<TransferCubit>()
                            .retryTransfer(transfer.id);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ),

                if (transfer.status == TransferStatus.inProgress ||
                    transfer.status == TransferStatus.pending ||
                    transfer.status == TransferStatus.paused)
                  const SizedBox(width: 8),

                // Cancel/Remove
                if (transfer.status == TransferStatus.inProgress ||
                    transfer.status == TransferStatus.pending ||
                    transfer.status == TransferStatus.paused)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<TransferCubit>()
                            .cancelTransfer(transfer.id);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<TransferCubit>()
                            .removeTransfer(transfer.id);
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Remove'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}