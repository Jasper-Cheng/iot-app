import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/message.dart';

/// 消息数据仓库
class MessageRepository {
  final _dio = DioClient().dio;

  /// 获取设备消息列表
  Future<List<DeviceMessage>> getDeviceMessages({
    String? level,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.deviceMessages,
      queryParameters: {
        'level': level,
        'status': status,
        'page': page,
        'page_size': pageSize,
      },
    );
    final List<dynamic> data = response.data;
    return data.map((e) => DeviceMessage.fromJson(e)).toList();
  }

  /// 标记消息为已读
  Future<void> markMessageAsRead(int id) async {
    await _dio.patch(ApiConstants.markMessageRead(id));
  }

  /// 标记所有消息为已读
  Future<void> markAllAsRead() async {
    await _dio.patch(ApiConstants.markAllRead);
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

