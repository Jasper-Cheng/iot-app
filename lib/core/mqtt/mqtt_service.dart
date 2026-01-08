import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:convert';
import '../constants/api_constants.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;

  final _messageController = StreamController<IoTMessage>.broadcast();
  final _connectionController = StreamController<MqttConnectionState>.broadcast();

  Stream<IoTMessage> get messageStream => _messageController.stream;
  Stream<MqttConnectionState> get connectionStream => _connectionController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// ===== 重连控制 =====
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;
  bool _isConnecting = false;

  static const Duration _reconnectInterval = Duration(seconds: 3);

  /// ===== 连接参数缓存 =====
  String? _lastClientId;
  String? _lastUsername;
  String? _lastPassword;

  /// ===== 订阅缓存（仅用于重连恢复）=====
  final Map<String, MqttQos> _subscribedTopics = {};

  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>?
  _updatesSubscription;

  /* -------------------------------------------------------------------------- */
  /*                                  CONNECT                                   */
  /* -------------------------------------------------------------------------- */

  Future<bool> connect({
    required String clientId,
    String? username,
    String? password,
  }) async {
    if (_isConnecting) return false;

    _isConnecting = true;
    _manualDisconnect = false;

    _lastClientId = clientId;
    _lastUsername = username;
    _lastPassword = password;

    await _disposeClient();

    try {
      _client = MqttServerClient(ApiConstants.mqttBroker, clientId);
      _client!
        ..port = ApiConstants.mqttPort
        ..logging(on: false)
        ..keepAlivePeriod = 60
        ..autoReconnect = false
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..setProtocolV311();

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillQos(MqttQos.atMostOnce)
          .startClean(); // ⭐ clean session

      if (username != null && password != null) {
        connMessage.authenticateAs(username, password);
      }

      _client!.connectionMessage = connMessage;

      print('[MQTT] Connecting...');
      await _client!.connect();

      if (isConnected) {
        print('[MQTT] Connected ClientId: $clientId');

        _setupMessageListener();
        _resubscribeAllTopics();

        _isConnecting = false;
        return true;
      }
    } catch (e) {
      print('[MQTT] Connect error: $e');
    }

    _isConnecting = false;
    _scheduleReconnect();
    return false;
  }

  /* -------------------------------------------------------------------------- */
  /*                              MESSAGE LISTENER                              */
  /* -------------------------------------------------------------------------- */

  void _setupMessageListener() {
    _updatesSubscription?.cancel();

    _updatesSubscription = _client!.updates?.listen(
          (messages) {
        for (final msg in messages) {
          final payload = msg.payload;
          if (payload is MqttPublishMessage) {
            final data = utf8.decode(payload.payload.message);
            _messageController.add(
              IoTMessage(topic: msg.topic, payload: data),
            );
          }
        }
      },
      onError: (_) => _handleDisconnect(),
      onDone: _handleDisconnect,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                SUBSCRIBE                                   */
  /* -------------------------------------------------------------------------- */

  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    _subscribedTopics[topic] = qos;

    if (isConnected) {
      _client!.subscribe(topic, qos);
      print('[MQTT] Subscribe: $topic');
    }
  }

  void unsubscribe(String topic) {
    _subscribedTopics.remove(topic);
    _client?.unsubscribe(topic);
  }

  void _resubscribeAllTopics() {
    if (!isConnected || _subscribedTopics.isEmpty) return;

    print('[MQTT] Resubscribing topics...');
    for (final entry in _subscribedTopics.entries) {
      _client!.subscribe(entry.key, entry.value);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                  PUBLISH                                   */
  /* -------------------------------------------------------------------------- */

  void publish(String topic, String message,
      {MqttQos qos = MqttQos.atMostOnce}) {
    if (!isConnected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, qos, builder.payload!);
  }

  /* -------------------------------------------------------------------------- */
  /*                               DISCONNECT                                   */
  /* -------------------------------------------------------------------------- */

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _disposeClient();
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void _handleDisconnect() {
    if (_manualDisconnect) return;
    _connectionController.add(MqttConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _isConnecting) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (_lastClientId != null) {
        print('[MQTT] Reconnecting...');
        connect(
          clientId: _lastClientId!,
          username: _lastUsername,
          password: _lastPassword,
        );
      }
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                                   CLEAN                                    */
  /* -------------------------------------------------------------------------- */

  Future<void> _disposeClient() async {
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _client?.disconnect();
    _client = null;
  }

  void _onConnected() {
    _connectionController.add(MqttConnectionState.connected);
  }

  void _onDisconnected() {
    _handleDisconnect();
  }

  void _onSubscribed(String topic) {
    print('[MQTT] Subscribed OK: $topic');
  }

  Future<void> dispose() async {
    _manualDisconnect = true;
    await _disposeClient();
    await _messageController.close();
    await _connectionController.close();
  }
}

/* -------------------------------------------------------------------------- */
/*                                   MODEL                                    */
/* -------------------------------------------------------------------------- */

class IoTMessage {
  final String topic;
  final String payload;

  IoTMessage({required this.topic, required this.payload});

  @override
  String toString() => 'IoTMessage(topic: $topic, payload: $payload)';
}
