import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/feedback.dart';

/// 设置数据仓库
class SettingsRepository {
  final _dio = DioClient().dio;

  /// 提交反馈
  Future<void> submitFeedback({
    String? name,
    required String type,
    required String content,
    String? contactInfo,
    Map<String, dynamic>? extra,
  }) async {
    await _dio.post(
      ApiConstants.feedback,
      data: {
        if (name != null) 'name': name,
        'type': type,
        'content': content,
        if (contactInfo != null) 'contact_info': contactInfo,
        if (extra != null) 'extra': extra,
      },
    );
  }

  /// 获取反馈列表
  Future<List<FeedbackModel>> getFeedbackList({
    int skip = 0,
    int limit = 20,
    String? type,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    
    if (type != null) {
      queryParams['type'] = type;
    }
    
    if (status != null) {
      queryParams['status'] = status;
    }
    
    final response = await _dio.get(
      ApiConstants.feedback,
      queryParameters: queryParams,
    );
    final List<dynamic> data = response.data;
    return data.map((e) => FeedbackModel.fromJson(e)).toList();
  }

  /// 获取版本信息
  Future<VersionInfo> getVersionInfo() async {
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

