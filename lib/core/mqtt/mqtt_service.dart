import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:convert';
import '../constants/api_constants.dart';

/// MQTT服务
class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  final _messageController = StreamController<IoTMessage>.broadcast();
  final _connectionController = StreamController<MqttConnectionState>.broadcast();

  // 自动重连相关属性
  Timer? _reconnectTimer;
  bool _manualDisconnect = false; // 标记是否为手动断开
  bool _autoReconnectEnabled = true; // 是否启用自动重连
  static const Duration _reconnectInterval = Duration(seconds: 3); // 每3秒重连一次

  // 连接参数缓存
  String? _lastClientId;
  String? _lastUsername;
  String? _lastPassword;

  // 订阅主题缓存和状态管理
  final Map<String, MqttQos> _subscribedTopics = {};
  final Set<String> _pendingSubscriptions = {}; // 正在订阅中的主题
  bool _isConnecting = false; // 防止重复连接
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSubscription;

  bool get isConnected =>
      _client != null &&
          _client!.connectionStatus != null &&
          _client!.connectionStatus!.state == MqttConnectionState.connected;

  /// 消息流
  Stream<IoTMessage> get messageStream => _messageController.stream;

  /// 连接状态流
  Stream<MqttConnectionState> get connectionStream => _connectionController.stream;

  /// 设置是否启用自动重连
  void setAutoReconnect(bool enabled) {
    _autoReconnectEnabled = enabled;
    if (!enabled) {
      _cancelReconnectTimer();
    } else if (!isConnected && !_manualDisconnect && _lastClientId != null) {
      // 如果启用自动重连且当前未连接，立即开始重连
      _scheduleReconnect();
    }
  }

  /// 连接到MQTT Broker
  Future<bool> connect({
    required String clientId,
    String? username,
    String? password,
    bool enableAutoReconnect = true,
  }) async {
    // 防止重复连接
    if (_isConnecting) {
      print('[MQTT] 正在连接中，跳过重复连接请求');
      return false;
    }

    _isConnecting = true;

    try {
      // 保存连接参数用于自动重连
      _lastClientId = clientId;
      _lastUsername = username;
      _lastPassword = password;
      _autoReconnectEnabled = enableAutoReconnect;

      // 重置手动断开标记
      _manualDisconnect = false;

      // 如果已有客户端，先断开
      if (_client != null) {
        await _safeDisconnect();
        _client = null;
      }

      // 取消之前的重连定时器
      _cancelReconnectTimer();

      // 取消之前的updates监听
      if (_updatesSubscription != null) {
        await _updatesSubscription!.cancel();
        _updatesSubscription = null;
      }

      // 创建客户端
      _client = MqttServerClient.withPort(
        ApiConstants.mqttBroker,
        clientId,
        ApiConstants.mqttPort,
      );

      _client!.logging(on: false);
      _client!.keepAlivePeriod = 60;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.autoReconnect = false; // 禁用包的自动重连，使用自定义实现
      _client!.setProtocolV311();

      // 设置连接消息 - 最简单的配置
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillQos(MqttQos.atMostOnce);

      if (username != null && password != null) {
        connMessage.authenticateAs(username, password);
      }

      _client!.connectionMessage = connMessage;

      // 连接
      print('[MQTT] 正在连接到 ${ApiConstants.mqttBroker}:${ApiConstants.mqttPort}...');

      try {
        // 使用5秒超时
        await _client!.connect().timeout(Duration(seconds: 5));

        if (isConnected) {
          print('[MQTT] 连接成功 - ClientId: $clientId');

          // 设置消息监听
          _setupMessageListening();

          // 注意：这里不调用 _resubscribeTopics()，因为外部应该自己处理订阅

          return true;
        } else {
          print('[MQTT] 连接失败，状态: ${_client!.connectionStatus?.state}');
          _handleConnectionFailure();
          return false;
        }
      } on TimeoutException catch (e) {
        print('[MQTT] 连接超时: $e');
        _handleConnectionFailure();
        return false;
      } catch (e) {
        print('[MQTT] 连接异常: $e');
        _handleConnectionFailure();
        return false;
      }
    } catch (e) {
      print('[MQTT] 连接初始化异常: $e');
      _handleConnectionFailure();
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// 处理连接失败
  void _handleConnectionFailure() {
    _onDisconnected();
    _safeDisconnect().then((_) {
      _client = null;
      if (_autoReconnectEnabled && !_manualDisconnect) {
        _scheduleReconnect();
      }
    });
  }

  /// 安全断开连接
  Future<void> _safeDisconnect() async {
    if (_client != null) {
      try {
        _client!.disconnect();
      } catch (e) {
        print('[MQTT] 断开连接异常: $e');
      }
    }
  }

  /// 设置消息监听
  void _setupMessageListening() {
    if (_client == null) return;

    // 取消之前的订阅
    if (_updatesSubscription != null) {
      _updatesSubscription!.cancel();
      _updatesSubscription = null;
    }

    // 监听消息
    _updatesSubscription = _client!.updates?.listen(
          (List<MqttReceivedMessage<MqttMessage?>> messages) {
        for (final message in messages) {
          final mqttMessage = message.payload;

          // 处理普通消息
          if (mqttMessage is MqttPublishMessage) {
            try {
              final topic = message.topic;
              final payload = utf8.decode(mqttMessage.payload.message);

              _messageController.add(IoTMessage(
                topic: topic,
                payload: payload,
              ));
            } catch (e) {
              print('[MQTT] 处理消息异常: $e');
            }
          }
        }
      },
      onError: (error) {
        print('[MQTT] 消息监听错误: $error');
        if (_autoReconnectEnabled && !_manualDisconnect) {
          _scheduleReconnect();
        }
      },
      onDone: () {
        print('[MQTT] 消息流结束');
        if (_autoReconnectEnabled && !_manualDisconnect) {
          _scheduleReconnect();
        }
      },
    );
  }

  /// 订阅主题（优化版，避免重复订阅）
  Future<bool> subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) async {
    // 检查是否已经在订阅中
    if (_pendingSubscriptions.contains(topic)) {
      print('[MQTT] 主题 $topic 正在订阅中，跳过重复请求');
      return false;
    }

    // 如果已经订阅过，检查是否需要更新QoS
    if (_subscribedTopics.containsKey(topic)) {
      final existingQos = _subscribedTopics[topic];
      if (existingQos == qos) {
        print('[MQTT] 主题 $topic 已订阅，无需重复订阅');
        return true;
      }
    }

    if (_client == null || !isConnected) {
      // 缓存订阅请求，重连后自动订阅
      _subscribedTopics[topic] = qos;
      print('[MQTT] 连接未建立，已缓存订阅: $topic (QoS: $qos)');
      return false;
    }

    _pendingSubscriptions.add(topic);

    try {
      _client!.subscribe(topic, qos);
      _subscribedTopics[topic] = qos; // 缓存订阅

      // 等待一小段时间让订阅完成
      await Future.delayed(Duration(milliseconds: 50));

      return true;
    } catch (e) {
      print('[MQTT] 订阅主题 $topic 失败: $e');
      _subscribedTopics.remove(topic); // 从缓存中移除
      return false;
    } finally {
      _pendingSubscriptions.remove(topic);
    }
  }

  /// 取消订阅
  Future<bool> unsubscribe(String topic) async {
    if (_client == null || !isConnected) {
      // 从缓存中移除
      _subscribedTopics.remove(topic);
      print('[MQTT] 连接未建立，从缓存中移除订阅: $topic');
      return false;
    }

    try {
      _client!.unsubscribe(topic);
      _subscribedTopics.remove(topic); // 从缓存中移除
      print('[MQTT] 已取消订阅主题: $topic');
      return true;
    } catch (e) {
      print('[MQTT] 取消订阅主题 $topic 失败: $e');
      return false;
    }
  }

  /// 发布消息
  Future<bool> publish(String topic, String message, {MqttQos qos = MqttQos.atMostOnce}) async {
    if (_client == null || !isConnected) {
      print('[MQTT] 无法发布消息，连接未建立');
      return false;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, qos, builder.payload!);
      print('[MQTT] 已发布消息到主题: $topic');
      return true;
    } catch (e) {
      print('[MQTT] 发布消息到主题 $topic 失败: $e');
      return false;
    }
  }

  /// 断开连接
  void disconnect() {
    _manualDisconnect = true; // 标记为手动断开
    _cancelReconnectTimer();

    // 清理updates监听
    if (_updatesSubscription != null) {
      _updatesSubscription!.cancel();
      _updatesSubscription = null;
    }

    _safeDisconnect().then((_) {
      _client = null;
      _onDisconnected();
      print('[MQTT] 已手动断开连接');
    });
  }

  /// 连接回调
  void _onConnected() {
    print('[MQTT] 连接成功回调');
    _connectionController.add(MqttConnectionState.connected);
  }

  /// 断开回调
  void _onDisconnected() {
    print('[MQTT] 断开连接回调');
    _connectionController.add(MqttConnectionState.disconnected);
  }

  /// 订阅回调
  void _onSubscribed(String topic) {
    print('[MQTT] 订阅成功回调: $topic');
  }

  /// 调度重连
  void _scheduleReconnect() {
    if (_manualDisconnect || !_autoReconnectEnabled) {
      return;
    }

    _cancelReconnectTimer();

    print('[MQTT] 计划在 3 秒后重连');

    _reconnectTimer = Timer(_reconnectInterval, () {
      _attemptReconnect();
    });
  }

  /// 尝试重连
  Future<void> _attemptReconnect() async {
    if (_manualDisconnect || !_autoReconnectEnabled) {
      return;
    }

    if (_lastClientId == null) {
      print('[MQTT] 无法重连：没有保存的连接参数');
      return;
    }

    print('[MQTT] 尝试重连...');
    try {
      final success = await connect(
        clientId: _lastClientId!,
        username: _lastUsername,
        password: _lastPassword,
        enableAutoReconnect: _autoReconnectEnabled,
      );

      if (success && _subscribedTopics.isNotEmpty) {
        print('[MQTT] 重连成功，需要重新订阅 ${_subscribedTopics.length} 个主题');
        // 重连后需要外部手动重新订阅，或者在这里自动重新订阅
        await _resubscribeAfterReconnect();
      }
    } catch (e) {
      print('[MQTT] 重连尝试失败: $e');
      // 重连失败，3秒后再次尝试
      _scheduleReconnect();
    }
  }

  /// 重连后重新订阅
  Future<void> _resubscribeAfterReconnect() async {
    if (_client == null || !isConnected || _subscribedTopics.isEmpty) {
      return;
    }

    print('[MQTT] 重连后重新订阅 ${_subscribedTopics.length} 个主题...');

    // 延迟一下确保连接稳定
    await Future.delayed(Duration(milliseconds: 500));

    final topics = _subscribedTopics.entries.toList();
    for (final entry in topics) {
      final topic = entry.key;
      final qos = entry.value;

      try {
        await subscribe(topic, qos: qos);
        await Future.delayed(Duration(milliseconds: 20)); // 避免订阅太快
      } catch (e) {
        print('[MQTT] 重连后重新订阅主题 $topic 失败: $e');
      }
    }

    print('[MQTT] 重连后重新订阅完成');
  }

  /// 取消重连定时器
  void _cancelReconnectTimer() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    _manualDisconnect = true;
    _cancelReconnectTimer();

    if (_updatesSubscription != null) {
      await _updatesSubscription!.cancel();
      _updatesSubscription = null;
    }

    await _safeDisconnect();
    _client = null;

    await _messageController.close();
    await _connectionController.close();

    print('[MQTT] 服务已清理');
  }

  /// 获取当前连接状态
  MqttConnectionState? get connectionState {
    return _client?.connectionStatus?.state;
  }

  /// 获取已订阅的主题列表
  List<String> get subscribedTopics {
    return _subscribedTopics.keys.toList();
  }

  /// 检查是否正在连接中
  bool get isConnecting => _isConnecting;
}

/// IoT消息
class IoTMessage {
  final String topic;
  final String payload;

  IoTMessage({
    required this.topic,
    required this.payload,
  });

  @override
  String toString() => 'IoTMessage(topic: $topic, payload: $payload)';
}