import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message.dart';
import '../data/repositories/message_repository.dart';

/// 消息状态
class MessageState {
  final List<DeviceMessage> deviceMessages;
  final List<SystemMessage> systemMessages;
  final int unreadDeviceCount;
  final int unreadSystemCount;
  final bool isLoading;
  final String? error;

  const MessageState({
    this.deviceMessages = const [],
    this.systemMessages = const [],
    this.unreadDeviceCount = 0,
    this.unreadSystemCount = 0,
    this.isLoading = false,
    this.error,
  });

  int get totalUnread => unreadDeviceCount + unreadSystemCount;

  MessageState copyWith({
    List<DeviceMessage>? deviceMessages,
    List<SystemMessage>? systemMessages,
    int? unreadDeviceCount,
    int? unreadSystemCount,
    bool? isLoading,
    String? error,
  }) {
    return MessageState(
      deviceMessages: deviceMessages ?? this.deviceMessages,
      systemMessages: systemMessages ?? this.systemMessages,
      unreadDeviceCount: unreadDeviceCount ?? this.unreadDeviceCount,
      unreadSystemCount: unreadSystemCount ?? this.unreadSystemCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 消息状态管理
class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepository _repository;

  MessageNotifier(this._repository) : super(const MessageState()) {
    loadMessages();
  }

  /// 加载消息
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deviceMessages = await _repository.getDeviceMessages();
      final systemMessages = await _repository.getSystemMessages();
      final unreadCount = await _repository.getUnreadCount();

      state = state.copyWith(
        deviceMessages: deviceMessages,
        systemMessages: systemMessages,
        unreadDeviceCount: unreadCount.deviceMessages,
        unreadSystemCount: unreadCount.systemMessages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 加载设备消息
  Future<void> loadDeviceMessages({
    String? level,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _repository.getDeviceMessages(
        level: level,
        status: status,
      );
      state = state.copyWith(
        deviceMessages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 加载系统消息
  Future<void> loadSystemMessages({String? type}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _repository.getSystemMessages(type: type);
      state = state.copyWith(
        systemMessages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 标记设备消息为已读
  Future<void> markDeviceMessageAsRead(int id) async {
    try {
      await _repository.markMessageAsRead(id);
      
      // 更新本地状态
      final updatedMessages = state.deviceMessages.map((msg) {
        if (msg.id == id) {
          return DeviceMessage(
            id: msg.id,
            deviceId: msg.deviceId,
            level: msg.level,
            message: msg.message,
            detail: msg.detail,
            status: 'read',
            createdAt: msg.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return msg;
      }).toList();

      state = state.copyWith(
        deviceMessages: updatedMessages,
        unreadDeviceCount: state.unreadDeviceCount > 0
            ? state.unreadDeviceCount - 1
            : 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 标记所有设备消息为已读
  Future<void> markAllDeviceMessagesAsRead() async {
    try {
      await _repository.markAllAsRead();
      
      // 更新本地状态
      final updatedMessages = state.deviceMessages.map((msg) {
        return DeviceMessage(
          id: msg.id,
          deviceId: msg.deviceId,
          level: msg.level,
          message: msg.message,
          detail: msg.detail,
          status: 'read',
          createdAt: msg.createdAt,
          updatedAt: DateTime.now(),
        );
      }).toList();

      state = state.copyWith(
        deviceMessages: updatedMessages,
        unreadDeviceCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 刷新
  Future<void> refresh() async {
    await loadMessages();
  }
}

/// 消息 Provider
final messageProvider = StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  return MessageNotifier(MessageRepository());
});

/// 未读消息数量 Provider
final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(messageProvider);
  return state.totalUnread;
});

