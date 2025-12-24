import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/message.dart';
import '../mock/mock_data.dart';

/// 消息数据仓库
class MessageRepository {
  final _dio = DioClient().dio;
  final bool useMock = true; // 是否使用 Mock 数据

  /// 获取设备消息列表
  Future<List<DeviceMessage>> getDeviceMessages({
    String? level,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockDeviceMessages
          .map((e) => DeviceMessage.fromJson(e))
          .toList();
    }

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
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    await _dio.patch(ApiConstants.markMessageRead(id));
  }

  /// 标记所有消息为已读
  Future<void> markAllAsRead() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    await _dio.patch(ApiConstants.markAllRead);
  }

  /// 获取系统消息列表
  Future<List<SystemMessage>> getSystemMessages({
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockSystemMessages
          .map((e) => SystemMessage.fromJson(e))
          .toList();
    }

    final response = await _dio.get(
      ApiConstants.systemMessages,
      queryParameters: {
        'type': type,
        'page': page,
        'page_size': pageSize,
      },
    );
    final List<dynamic> data = response.data;
    return data.map((e) => SystemMessage.fromJson(e)).toList();
  }

  /// 获取未读消息数量
  Future<MessageUnreadCount> getUnreadCount() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return const MessageUnreadCount(
        deviceMessages: 2,
        systemMessages: 1,
      );
    }

    final response = await _dio.get('${ApiConstants.deviceMessages}unread-count');
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

