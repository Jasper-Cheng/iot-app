import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';
import '../core/mqtt/mqtt_service.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/error_handler.dart';

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
  
  // Handler 回调函数
  void Function(Map<String, dynamic> data)? onSystemMessage;
  void Function(int homeId, Map<String, dynamic> data)? onFamilyMessage;

  MqttNotifier() : super(const MqttState()) {
    _init();
  }
  
  /// 设置系统消息处理器
  void setSystemMessageHandler(void Function(Map<String, dynamic> data) handler) {
    onSystemMessage = handler;
  }
  
  /// 设置家庭消息处理器
  void setFamilyMessageHandler(void Function(int homeId, Map<String, dynamic> data) handler) {
    onFamilyMessage = handler;
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
        // 输出连接成功信息
        print('[MQTT] 连接成功');
        print('[MQTT]   Broker: ${ApiConstants.mqttBroker}:${ApiConstants.mqttPort}');
        print('[MQTT]   ClientId: $clientId');
        print('[MQTT]   UserId: $userId');
        print('[MQTT]   认证: ${username != null && password != null ? "是" : "否"}');
        
        // 自动订阅系统通知主题
        subscribe(ApiConstants.mqttSystemNotice);
      } else {
        state = state.copyWith(error: '连接失败');
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 订阅主题
  void subscribe(String topic) {
    if (!state.subscribedTopics.contains(topic)) {
      _service.subscribe(topic);
      state = state.copyWith(
        subscribedTopics: [...state.subscribedTopics, topic],
      );
      print('[MQTT] 订阅主题: $topic');
    } else {
      print('[MQTT] 主题已订阅，跳过: $topic');
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
    // 先处理消息，再更新状态（避免不必要的状态更新）
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
    
    // 只在需要时才更新 recentMessages（避免每次消息都触发状态更新）
    // 如果不需要保留消息历史，可以注释掉这部分
    // final messages = [...state.recentMessages, message];
    // if (messages.length > 100) {
    //   messages.removeAt(0);
    // }
    // state = state.copyWith(recentMessages: messages);
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
      
      // 根据 topic 区分系统消息和家庭消息
      if (message.topic == ApiConstants.mqttSystemNotice) {
        // 处理系统消息
        if (onSystemMessage != null) {
          onSystemMessage!(data);
        }
      } else if (message.topic.startsWith('home/') && message.topic.endsWith('/notice')) {
        // 处理家庭消息
        // 从 topic 中提取家庭ID: home/{homeId}/notice
        final parts = message.topic.split('/');
        if (parts.length >= 2) {
          final homeId = int.tryParse(parts[1]);
          if (homeId != null && onFamilyMessage != null) {
            onFamilyMessage!(homeId, data);
          }
        }
      }
    } catch (e) {
      print('[MQTT] 解析通知失败: $e');
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

