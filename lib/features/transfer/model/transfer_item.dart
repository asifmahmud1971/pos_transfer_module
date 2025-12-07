import 'package:equatable/equatable.dart';

enum TransferType { upload, download }

enum TransferStatus {
  pending,
  inProgress,
  paused,
  completed,
  failed,
  cancelled,
}

class TransferItem extends Equatable {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final TransferType type;
  final TransferStatus status;
  final double progress;
  final String? errorMessage;
  final String? downloadUrl;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int retryCount;

  const TransferItem({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.type,
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
    this.downloadUrl,
    required this.createdAt,
    this.completedAt,
    this.retryCount = 0,
  });

  TransferItem copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? fileSize,
    TransferType? type,
    TransferStatus? status,
    double? progress,
    String? errorMessage,
    String? downloadUrl,
    DateTime? createdAt,
    DateTime? completedAt,
    int? retryCount,
  }) {
    return TransferItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'type': type.toString(),
      'status': status.toString(),
      'progress': progress,
      'errorMessage': errorMessage,
      'downloadUrl': downloadUrl,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      type: TransferType.values.firstWhere(
            (e) => e.toString() == json['type'],
      ),
      status: TransferStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
      ),
      progress: (json['progress'] as num).toDouble(),
      errorMessage: json['errorMessage'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fileName,
    filePath,
    fileSize,
    type,
    status,
    progress,
    errorMessage,
    downloadUrl,
    createdAt,
    completedAt,
    retryCount,
  ];
}