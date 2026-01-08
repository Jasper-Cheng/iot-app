import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/message.dart';

/// 消息数据仓库
class MessageRepository {
  final _dio = DioClient().dio;

  /// 获取设备消息列表
  /// [familyId] 家庭ID，如果不为 null 则作为查询参数传递
  /// [level] 消息级别数组，支持多个值：low, normal, error, fatal
  /// [status] 消息状态：new（未读）、read（已读）
  /// [skip] 跳过数量，用于分页，如果不传入则不拼接参数
  /// [limit] 限制数量，范围：1-500，如果不传入则不拼接参数
  Future<List<DeviceMessage>> getDeviceMessages({
    int? familyId,
    List<String>? level,
    String? status,
    int? skip,
    int? limit,
  }) async {
    final queryParameters = <String, dynamic>{};
    
    if (familyId != null) {
      queryParameters['family_id'] = familyId;
    }
    
    if (level != null && level.isNotEmpty) {
      // 支持多个 level 值，Dio 会自动将 List 转换为多个查询参数
      queryParameters['level'] = level;
    }
    
    if (status != null) {
      queryParameters['status'] = status;
    }
    
    if (skip != null) {
      queryParameters['skip'] = skip;
    }
    
    if (limit != null) {
      queryParameters['limit'] = limit;
    }
    
    final response = await _dio.get(
      ApiConstants.deviceMessages,
      queryParameters: queryParameters,
    );
    final List<dynamic> data = response.data;
    return data.map((e) => DeviceMessage.fromJson(e)).toList();
  }

  /// 标记消息为已读
  /// [id] 消息ID
  /// [familyId] 家庭ID，如果不为 null 则作为查询参数传递
  Future<void> markMessageAsRead(int id, {int? familyId}) async {
    final queryParameters = <String, dynamic>{};
    if (familyId != null) {
      queryParameters['family_id'] = familyId;
    }
    
    await _dio.patch(
      ApiConstants.markMessageRead(id),
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
  }

  /// 标记所有消息为已读
  /// [familyId] 家庭ID，如果不为 null 则作为查询参数传递
  Future<void> markAllAsRead({int? familyId}) async {
    final queryParameters = <String, dynamic>{};
    if (familyId != null) {
      queryParameters['family_id'] = familyId;
    }
    
    await _dio.patch(
      ApiConstants.markAllRead,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
  }

  /// 获取系统消息列表
  Future<List<SystemMessage>> getSystemMessages({
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    
    // 只在type不为null时才添加type参数
    if (type != null) {
      queryParameters['type'] = type;
    }

    final response = await _dio.get(
      ApiConstants.systemMessages,
      queryParameters: queryParameters,
    );
    final List<dynamic> data = response.data;
    return data.map((e) => SystemMessage.fromJson(e)).toList();
  }

  /// 获取未读消息数量
  Future<MessageUnreadCount> getUnreadCount() async {
    final response = await _dio.get(ApiConstants.unreadCount);
    return MessageUnreadCount.fromJson(response.data);
  }
}

/// 未读消息数量
class MessageUnreadCount {
  final int deviceMessages;
  final int systemMessages;

  const MessageUnreadCount({
    required this.deviceMessages,
    required this.systemMessages,
  });

  int get total => deviceMessages + systemMessages;

  factory MessageUnreadCount.fromJson(Map<String, dynamic> json) {
    return MessageUnreadCount(
      deviceMessages: json['device_messages'] as int,
      systemMessages: json['system_messages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_messages': deviceMessages,
      'system_messages': systemMessages,
    };
  }
}

