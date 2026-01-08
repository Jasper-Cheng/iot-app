import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';
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
  void Function(String deviceSn, Map<String, dynamic> data)? onDeviceNotice;
  void Function(String accountId, Map<String, dynamic> data)? onClientNotice;
  
  // 设备数据处理器 Map: deviceSn -> handler
  final Map<String, void Function(Map<String, dynamic> data)> _deviceDataHandlers = {};
  
  // 设备状态处理器 Map: deviceSn -> handler
  final Map<String, void Function(Map<String, dynamic> data)> _deviceStatusHandlers = {};
  
  // 重连相关
  String? _userId;
  String? _username;
  String? _password;
  bool _isReconnecting = false;
  bool _isManualDisconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const Duration _reconnectDelay = Duration(seconds: 3); // 固定重连延迟：3秒

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
  
  /// 设置设备消息通知处理器
  void setDeviceNoticeHandler(void Function(String deviceSn, Map<String, dynamic> data) handler) {
    onDeviceNotice = handler;
  }
  
  /// 设置个人消息通知处理器
  void setClientNoticeHandler(void Function(String accountId, Map<String, dynamic> data) handler) {
    onClientNotice = handler;
  }
  
  /// 注册设备数据处理器
  void registerDeviceDataHandler(String deviceSn, void Function(Map<String, dynamic> data) handler) {
    _deviceDataHandlers[deviceSn] = handler;
    print('[MQTT] 注册设备数据处理器: $deviceSn');
  }
  
  /// 注销设备数据处理器
  void unregisterDeviceDataHandler(String deviceSn) {
    _deviceDataHandlers.remove(deviceSn);
    print('[MQTT] 注销设备数据处理器: $deviceSn');
  }
  
  /// 注册设备状态处理器
  void registerDeviceStatusHandler(String deviceSn, void Function(Map<String, dynamic> data) handler) {
    _deviceStatusHandlers[deviceSn] = handler;
    print('[MQTT] 注册设备状态处理器: $deviceSn');
  }
  
  /// 注销设备状态处理器
  void unregisterDeviceStatusHandler(String deviceSn) {
    _deviceStatusHandlers.remove(deviceSn);
    print('[MQTT] 注销设备状态处理器: $deviceSn');
  }

  void _init() {
    // 监听连接状态
    _service.connectionStream.listen((connectionState) {
      final previousState = state.connectionState;
      state = state.copyWith(connectionState: connectionState);
      
      // 处理连接状态变化
      if (previousState != connectionState) {
        _handleConnectionStateChange(previousState, connectionState);
      }
    });

    // 监听消息
    _service.messageStream.listen((message) {
      _handleMessage(message);
    });
  }
  
  /// 处理连接状态变化
  void _handleConnectionStateChange(
    MqttConnectionState previousState,
    MqttConnectionState currentState,
  ) {
    // 连接成功
    if (currentState == MqttConnectionState.connected) {
      _isReconnecting = false;
      _reconnectAttempts = 0;
      _isManualDisconnect = false;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      state = state.copyWith(error: null);
      print('[MQTT] 连接成功，清除重连状态');
    }
    // 连接断开（非主动断开）- 也处理从其他状态变为断开的情况
    else if (currentState == MqttConnectionState.disconnected && 
             !_isManualDisconnect &&
             _userId != null) {
      print('[MQTT] 检测到非主动断开，准备重连');
      _scheduleReconnect();
    }
  }
  
  /// 安排重连
  void _scheduleReconnect() {
    if (_isReconnecting || _userId == null) {
      return;
    }
    
    _isReconnecting = true;
    _reconnectAttempts++;
    
    print('[MQTT] 将在 ${_reconnectDelay.inSeconds} 秒后尝试第 $_reconnectAttempts 次重连（无限重连）');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _attemptReconnect();
    });
  }
  
  /// 尝试重连
  Future<void> _attemptReconnect() async {
    if (_userId == null) {
      _isReconnecting = false;
      return;
    }
    
    print('[MQTT] 开始第 $_reconnectAttempts 次重连尝试');
    state = state.copyWith(error: '正在重连...');
    
    try {
      // 直接调用服务连接，避免触发connect方法中的重连逻辑
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final clientId = '${ApiConstants.mqttClientPrefix}${_userId!}_$timestamp';
      final success = await _service.connect(
        clientId: clientId,
        username: _username,
        password: _password,
      );
      
      if (success) {
        print('[MQTT] 重连成功');
        // 连接成功会在 _handleConnectionStateChange 中处理
        // 自动订阅系统通知主题
        subscribe(ApiConstants.mqttSystemNotice);
      } else {
        // 连接失败，继续重连
        _isReconnecting = false;
        _scheduleReconnect();
      }
    } catch (e) {
      print('[MQTT] 重连失败: $e');
      _isReconnecting = false;
      state = state.copyWith(error: '重连失败: ${ErrorHandler.extractErrorMessage(e)}');
      _scheduleReconnect();
    }
  }

  /// 连接
  Future<void> connect({
    required String userId,
    String? username,
    String? password,
  }) async {
    try {
      // 保存连接参数，用于重连
      _userId = userId;
      _username = username;
      _password = password;
      _isManualDisconnect = false;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final clientId = '${ApiConstants.mqttClientPrefix}${userId}_$timestamp';
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
        
        // 重置重连状态
        _isReconnecting = false;
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        
        // 自动订阅系统通知主题
        subscribe(ApiConstants.mqttSystemNotice);
      } else {
        state = state.copyWith(error: '连接失败');
        // 连接失败时，如果不是手动断开，则安排重连
        if (!_isManualDisconnect) {
          _scheduleReconnect();
        }
      }
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMsg);
      print('[MQTT] 连接异常: $e');
      // 连接异常时，如果不是手动断开，则安排重连
      if (!_isManualDisconnect) {
        _scheduleReconnect();
      }
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
    if (state.subscribedTopics.contains(topic)) {
      _service.unsubscribe(topic);
      state = state.copyWith(
        subscribedTopics: state.subscribedTopics.where((t) => t != topic).toList(),
      );
      print('[MQTT] 取消订阅主题: $topic');
    } else {
      print('[MQTT] 主题未订阅，跳过取消: $topic');
    }
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
  
  /// 订阅设备消息通知
  void subscribeDeviceNotice(String sn) {
    subscribe(ApiConstants.mqttDeviceNotice(sn));
  }
  
  /// 订阅个人消息通知
  void subscribeClientNotice(String accountId) {
    subscribe(ApiConstants.mqttClientNotice(accountId));
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
      
      // 从 topic 中提取设备 SN: client/{deviceSn}/data
      final topicParts = message.topic.split('/');
      if (topicParts.length >= 2) {
        final deviceSn = topicParts[1];
        
        // 调用对应设备的数据处理器
        final handler = _deviceDataHandlers[deviceSn];
        if (handler != null) {
          handler(data);
        } else {
          print('[MQTT] 未找到设备 $deviceSn 的数据处理器');
        }
      }
    } catch (e) {
      print('[MQTT] 解析设备数据失败: $e');
    }
  }

  /// 处理设备状态
  void _handleDeviceStatus(IoTMessage message) {
    try {
      final data = jsonDecode(message.payload);
      
      // 从 topic 中提取设备 SN: client/{deviceSn}/status
      final topicParts = message.topic.split('/');
      if (topicParts.length >= 2) {
        final deviceSn = topicParts[1];
        
        // 调用对应设备的状态处理器
        final handler = _deviceStatusHandlers[deviceSn];
        if (handler != null) {
          handler(data);
        } else {
          print('[MQTT] 未找到设备 $deviceSn 的状态处理器');
        }
      }
    } catch (e) {
      print('[MQTT] 解析设备状态失败: $e');
    }
  }

  /// 处理通知
  void _handleNotice(IoTMessage message) {
    try {
      final data = jsonDecode(message.payload);
      
      // 根据 topic 区分不同类型的通知
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
      } else if (message.topic.startsWith('device/') && message.topic.endsWith('/notice')) {
        // 处理设备消息通知
        // 从 topic 中提取设备 SN: device/{deviceSn}/notice
        final parts = message.topic.split('/');
        if (parts.length >= 2) {
          final deviceSn = parts[1];
          if (onDeviceNotice != null) {
            onDeviceNotice!(deviceSn, data);
          }
        }
      } else if (message.topic.startsWith('client/') && message.topic.endsWith('/notice')) {
        // 处理个人消息通知
        // 从 topic 中提取账户ID: client/{accountId}/notice
        final parts = message.topic.split('/');
        if (parts.length >= 2) {
          final accountId = parts[1];
          if (onClientNotice != null) {
            onClientNotice!(accountId, data);
          }
        }
      }
    } catch (e) {
      print('[MQTT] 解析通知失败: $e');
    }
  }

  /// 断开连接
  void disconnect() {
    _isManualDisconnect = true;
    _userId = null;
    _username = null;
    _password = null;
    _isReconnecting = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _service.disconnect();
    state = const MqttState();
    print('[MQTT] 手动断开连接');
  }
  
  /// 重置重连计数（用于手动重连）
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    print('[MQTT] 重置重连计数');
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
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

