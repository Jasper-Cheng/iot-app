import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message.dart';
import '../data/repositories/message_repository.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart';

/// 消息状态
class MessageState {
  final List<DeviceMessage> deviceMessages;
  final List<SystemMessage> systemMessages;
  final bool isLoading;
  final String? error;

  const MessageState({
    this.deviceMessages = const [],
    this.systemMessages = const [],
    this.isLoading = false,
    this.error,
  });

  /// 未读设备消息数量（deviceMessages已经是未读消息）
  int get unreadDeviceCount => deviceMessages.length;

  MessageState copyWith({
    List<DeviceMessage>? deviceMessages,
    List<SystemMessage>? systemMessages,
    bool? isLoading,
    String? error,
  }) {
    return MessageState(
      deviceMessages: deviceMessages ?? this.deviceMessages,
      systemMessages: systemMessages ?? this.systemMessages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 消息状态管理
class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepository _repository;
  final int? _currentFamilyId;

  MessageNotifier(
    this._repository, {
    int? currentFamilyId,
  })  : _currentFamilyId = currentFamilyId,
        super(const MessageState()) {
    // 不在构造函数中自动加载，由 MainScreen 统一管理加载时机
  }

  /// 加载消息（初始只加载未读设备消息）
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 只加载未读的设备消息
      final deviceMessages = await _repository.getDeviceMessages(
        familyId: _currentFamilyId,
        status: 'new',
      );
      final systemMessages = await _repository.getSystemMessages();

      state = state.copyWith(
        deviceMessages: deviceMessages,
        systemMessages: systemMessages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 加载已读设备消息（用于消息日志）
  Future<List<DeviceMessage>> loadReadDeviceMessages() async {
    try {
      final messages = await _repository.getDeviceMessages(
        familyId: _currentFamilyId,
        status: 'read',
      );
      return messages;
    } catch (e) {
      return [];
    }
  }

  /// 加载设备消息
  Future<void> loadDeviceMessages({
    List<String>? level,
    String? status,
    int skip = 0,
    int limit = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _repository.getDeviceMessages(
        familyId: _currentFamilyId,
        level: level,
        status: status,
        skip: skip,
        limit: limit,
      );
      state = state.copyWith(
        deviceMessages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
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
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 标记设备消息为已读
  Future<void> markDeviceMessageAsRead(int id) async {
    try {
      await _repository.markMessageAsRead(id, familyId: _currentFamilyId);
      
      // 从未读列表中移除该消息
      final updatedMessages = state.deviceMessages.where((msg) => msg.id != id).toList();

      state = state.copyWith(
        deviceMessages: updatedMessages,
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 标记所有设备消息为已读
  Future<void> markAllDeviceMessagesAsRead() async {
    try {
      await _repository.markAllAsRead(familyId: _currentFamilyId);
      
      // 清空未读消息列表
      state = state.copyWith(
        deviceMessages: [],
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 刷新
  Future<void> refresh() async {
    await loadMessages();
  }
}

/// 消息 Provider
final messageProvider = StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  // 只监听 currentFamilyId 的变化，忽略其他字段（如昵称、头像等）的变化
  // 这样修改用户信息时不会导致 messageProvider 重新创建，但切换家庭时会自动重建
  final currentFamilyId = ref.watch(authProvider.select((state) => state.account?.currentFamilyId));
  
  return MessageNotifier(
    MessageRepository(),
    currentFamilyId: currentFamilyId,
  );
});

/// 未读设备消息数量 Provider
final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(messageProvider);
  return state.unreadDeviceCount;
});

