import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import '../constants/api_constants.dart';

/// MQTT服务
class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  final _messageController = StreamController<IoTMessage>.broadcast();
  final _connectionController = StreamController<MqttConnectionState>.broadcast();

  bool get isConnected =>
      _client != null && _client!.connectionStatus?.state == MqttConnectionState.connected;

  /// 消息流
  Stream<IoTMessage> get messageStream => _messageController.stream;

  /// 连接状态流
  Stream<MqttConnectionState> get connectionStream => _connectionController.stream;

  /// 连接到MQTT Broker
  Future<bool> connect({
    required String clientId,
    String? username,
    String? password,
  }) async {
    try {
      // 创建客户端
      _client = MqttServerClient(ApiConstants.mqttBroker, clientId);
      _client!.port = ApiConstants.mqttPort;
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 60;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;

      // 设置连接消息
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);

      if (username != null && password != null) {
        connMessage.authenticateAs(username, password);
      }

      _client!.connectionMessage = connMessage;

      // 连接
      await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        print('MQTT: 连接成功');
        
        // 监听消息
        _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
          if (messages == null) return;
          for (final message in messages) {
            final recMess = message.payload as MqttPublishMessage;
            final topic = message.topic;
            final payload =
                MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
            
            print('MQTT: 收到消息 - Topic: $topic, Payload: $payload');
            
            _messageController.add(IoTMessage(
              topic: topic,
              payload: payload,
            ));
          }
        });

        return true;
      } else {
        print('MQTT: 连接失败 - ${_client!.connectionStatus}');
        return false;
      }
    } catch (e) {
      print('MQTT: 连接异常 - $e');
      return false;
    }
  }

  /// 订阅主题
  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    if (_client == null || !isConnected) {
      print('MQTT: 未连接，无法订阅');
      return;
    }

    _client!.subscribe(topic, qos);
    print('MQTT: 订阅主题 - $topic');
  }

  /// 取消订阅
  void unsubscribe(String topic) {
    if (_client == null) return;
    _client!.unsubscribe(topic);
    print('MQTT: 取消订阅 - $topic');
  }

  /// 发布消息
  void publish(String topic, String message, {MqttQos qos = MqttQos.atMostOnce}) {
    if (_client == null || !isConnected) {
      print('MQTT: 未连接，无法发布消息');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, qos, builder.payload!);
    print('MQTT: 发布消息 - Topic: $topic, Message: $message');
  }

  /// 断开连接
  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
      _client = null;
      print('MQTT: 已断开连接');
    }
  }

  /// 连接回调
  void _onConnected() {
    print('MQTT: 连接回调');
    _connectionController.add(MqttConnectionState.connected);
  }

  /// 断开回调
  void _onDisconnected() {
    print('MQTT: 断开回调');
    _connectionController.add(MqttConnectionState.disconnected);
  }

  /// 订阅回调
  void _onSubscribed(String topic) {
    print('MQTT: 订阅成功 - $topic');
  }

  /// 清理资源
  void dispose() {
    _messageController.close();
    _connectionController.close();
    disconnect();
  }
}

/// IoT消息（避免与mqtt_client包中的MqttMessage冲突）
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

