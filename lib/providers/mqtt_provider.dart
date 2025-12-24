import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';
import '../core/mqtt/mqtt_service.dart';
import '../core/constants/api_constants.dart';

/// MQTT 状态
class MqttState {
  final MqttConnectionState connectionState;
  final List<String> subscribedTopics;
  final List<IoTMessage> recentMessages;
  final String? error;

  const MqttState({
    this.connectionState = MqttConnectionState.disconnected,
    this.subscribedTopics = const [],
    this.recentMessages = const [],
    this.error,
  });

  bool get isConnected => connectionState == MqttConnectionState.connected;

  MqttState copyWith({
    MqttConnectionState? connectionState,
    List<String>? subscribedTopics,
    List<IoTMessage>? recentMessages,
    String? error,
  }) {
    return MqttState(
      connectionState: connectionState ?? this.connectionState,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
      recentMessages: recentMessages ?? this.recentMessages,
      error: error,
    );
  }
}

/// MQTT 状态管理
class MqttNotifier extends StateNotifier<MqttState> {
  final MqttService _service = MqttService();

  MqttNotifier() : super(const MqttState()) {
    _init();
  }

  void _init() {
    // 监听连接状态
    _service.connectionStream.listen((connectionState) {
      state = state.copyWith(connectionState: connectionState);
    });

    // 监听消息
    _service.messageStream.listen((message) {
      _handleMessage(message);
    });
  }

  /// 连接
  Future<void> connect({
    required String userId,
    String? username,
    String? password,
  }) async {
    try {
      final clientId = '${ApiConstants.mqttClientPrefix}$userId';
      final success = await _service.connect(
        clientId: clientId,
        username: username,
        password: password,
      );

      if (success) {
        // 自动订阅系统通知主题
        subscribe(ApiConstants.mqttSystemNotice);
      } else {
        state = state.copyWith(error: '连接失败');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 订阅主题
  void subscribe(String topic) {
    if (!state.subscribedTopics.contains(topic)) {
      _service.subscribe(topic);
      state = state.copyWith(
        subscribedTopics: [...state.subscribedTopics, topic],
      );
    }
  }

  /// 取消订阅
  void unsubscribe(String topic) {
    _service.unsubscribe(topic);
    state = state.copyWith(
      subscribedTopics: state.subscribedTopics.where((t) => t != topic).toList(),
    );
  }

  /// 订阅家庭通知
  void subscribeHomeNotice(int homeId) {
    subscribe(ApiConstants.mqttHomeNotice(homeId));
  }

  /// 订阅设备数据
  void subscribeDeviceData(String sn) {
    subscribe(ApiConstants.mqttDeviceData(sn));
  }

  /// 订阅设备状态
  void subscribeDeviceStatus(String sn) {
    subscribe(ApiConstants.mqttDeviceStatus(sn));
  }

  /// 发送设备控制指令
  void controlDevice(String sn, Map<String, dynamic> command) {
    final topic = ApiConstants.mqttDeviceControl(sn);
    final message = jsonEncode(command);
    _service.publish(topic, message);
  }

  /// 处理接收到的消息
  void _handleMessage(IoTMessage message) {
    // 保留最近100条消息
    final messages = [...state.recentMessages, message];
    if (messages.length > 100) {
      messages.removeAt(0);
    }

    state = state.copyWith(recentMessages: messages);

    // 可以在这里根据不同的topic做不同的处理
    if (message.topic.contains('/data')) {
      // 处理设备数据
      _handleDeviceData(message);
    } else if (message.topic.contains('/status')) {
      // 处理设备状态
      _handleDeviceStatus(message);
    } else if (message.topic.contains('/notice')) {
      // 处理通知
      _handleNotice(message);
    }
  }

  /// 处理设备数据
  void _handleDeviceData(IoTMessage message) {
    try {
      final data = jsonDecode(message.payload);
      print('设备数据: $data');
      // 这里可以更新设备状态到 device provider
    } catch (e) {
      print('解析设备数据失败: $e');
    }
  }

  /// 处理设备状态
  void _handleDeviceStatus(IoTMessage message) {
    try {
      final data = jsonDecode(message.payload);
      print('设备状态: $data');
      // 这里可以更新设备在线状态到 device provider
    } catch (e) {
      print('解析设备状态失败: $e');
    }
  }

  /// 处理通知
  void _handleNotice(IoTMessage message) {
    try {
      final data = jsonDecode(message.payload);
      print('收到通知: $data');
      // 这里可以触发通知提醒
    } catch (e) {
      print('解析通知失败: $e');
    }
  }

  /// 断开连接
  void disconnect() {
    _service.disconnect();
    state = const MqttState();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// MQTT Provider
final mqttProvider = StateNotifierProvider<MqttNotifier, MqttState>((ref) {
  return MqttNotifier();
});

/// MQTT 连接状态 Provider
final mqttConnectionStateProvider = Provider<MqttConnectionState>((ref) {
  return ref.watch(mqttProvider).connectionState;
});

/// MQTT 是否已连接 Provider
final mqttIsConnectedProvider = Provider<bool>((ref) {
  return ref.watch(mqttProvider).isConnected;
});

