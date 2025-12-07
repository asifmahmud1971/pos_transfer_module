import 'package:equatable/equatable.dart';

class UploadedFileModel extends Equatable {
  final int appId;
  final String appCode;
  final String appName;
  final String? appDesc;
  final String? appLogo;
  final String appType;
  final String appPlatform;
  final String appVersionName;
  final int appVersionCode;
  final String? appLink;
  final String? updateType;
  final int isActive;
  final int? companyId;
  final int? branchId;
  final String? remarks;
  final int? entryBy;
  final double? entryDate;
  final int? updateBy;
  final double? updateDate;
  final int? fileSize;

  const UploadedFileModel({
    required this.appId,
    required this.appCode,
    required this.appName,
    this.appDesc,
    this.appLogo,
    required this.appType,
    required this.appPlatform,
    required this.appVersionName,
    required this.appVersionCode,
    this.appLink,
    this.updateType,
    required this.isActive,
    this.companyId,
    this.branchId,
    this.remarks,
    this.entryBy,
    this.entryDate,
    this.updateBy,
    this.updateDate,
    this.fileSize,
  });

  factory UploadedFileModel.fromJson(Map<String, dynamic> json) {
    return UploadedFileModel(
      appId: json['appId'] as int? ?? 0,
      appCode: json['appCode'] as String? ?? '',
      appName: json['appName'] as String? ?? 'Unknown App',
      appDesc: json['appDesc'] as String?,
      appLogo: json['appLogo'] as String?,
      appType: json['appType'] as String? ?? 'M',
      appPlatform: json['appPlatform'] as String? ?? 'Unknown',
      appVersionName: json['appVersionName'] as String? ?? '1.0.0',
      appVersionCode: json['appVersionCode'] as int? ?? 1,
      appLink: json['appLink'] as String?,
      updateType: json['updateType'] as String?,
      isActive: json['isActive'] as int? ?? 0,
      companyId: json['companyId'] as int?,
      branchId: json['branchId'] as int?,
      remarks: json['remarks'] as String?,
      entryBy: json['entryBy'] as int?,
      entryDate: (json['entryDate'] as num?)?.toDouble(),
      updateBy: json['updateBy'] as int?,
      updateDate: (json['updateDate'] as num?)?.toDouble(),
      fileSize: json['fileSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'appCode': appCode,
      'appName': appName,
      'appDesc': appDesc,
      'appLogo': appLogo,
      'appType': appType,
      'appPlatform': appPlatform,
      'appVersionName': appVersionName,
      'appVersionCode': appVersionCode,
      'appLink': appLink,
      'updateType': updateType,
      'isActive': isActive,
      'companyId': companyId,
      'branchId': branchId,
      'remarks': remarks,
      'entryBy': entryBy,
      'entryDate': entryDate,
      'updateBy': updateBy,
      'updateDate': updateDate,
      'fileSize': fileSize,
    };
  }

  // Display helpers
  String get displayName => '$appName v$appVersionName';

  String get displaySize {
    // Since API doesn't provide file size, show version info
    return '$appPlatform - $appVersionCode';
  }

  String get effectiveDownloadUrl => appLink ?? '';

  bool get canDownload => appLink != null && appLink!.isNotEmpty;

  String get fileExtension {
    if (appLink == null) return '';
    final uri = Uri.tryParse(appLink!);
    if (uri == null) return '';
    final path = uri.path;
    if (path.contains('.')) {
      return path.split('.').last.toUpperCase();
    }
    return '';
  }

  DateTime? get entryDateTime {
    if (entryDate == null) return null;
    return DateTime.fromMillisecondsSinceEpoch((entryDate! * 1000).toInt());
  }

  DateTime? get updateDateTime {
    if (updateDate == null) return null;
    return DateTime.fromMillisecondsSinceEpoch((updateDate! * 1000).toInt());
  }

  @override
  List<Object?> get props => [
    appId,
    appCode,
    appName,
    appDesc,
    appLogo,
    appType,
    appPlatform,
    appVersionName,
    appVersionCode,
    appLink,
    updateType,
    isActive,
    fileSize
  ];
}