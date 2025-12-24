import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

/// 设置数据仓库
class SettingsRepository {
  final _dio = DioClient().dio;
  final bool useMock = false; // 是否使用 Mock 数据，改为 false 连接实际后端

  /// 提交反馈
  Future<void> submitFeedback({
    required String type,
    required String content,
    String? contact,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return;
    }

    await _dio.post(
      ApiConstants.feedback,
      data: {
        'type': type,
        'content': content,
        'contact': contact,
      },
    );
  }

  /// 获取版本信息
  Future<VersionInfo> getVersionInfo() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return const VersionInfo(
        version: '1.0.0',
        buildNumber: 1,
        updateTime: '2025-01-01',
        description: '首次发布版本',
      );
    }

    final response = await _dio.get(ApiConstants.versionInfo);
    return VersionInfo.fromJson(response.data);
  }
}

/// 版本信息
class VersionInfo {
  final String version;
  final int buildNumber;
  final String updateTime;
  final String description;

  const VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.updateTime,
    required this.description,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      updateTime: json['update_time'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'build_number': buildNumber,
      'update_time': updateTime,
      'description': description,
    };
  }
}

