import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 蓝牙工具类
/// 支持连接、断开、特征值写入（WiFi配置、MQTT配置）、关闭释放
class BluetoothHelper {
  static final BluetoothHelper _instance = BluetoothHelper._internal();
  factory BluetoothHelper() => _instance;
  BluetoothHelper._internal();

  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _cachedServices;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  /// 当前连接的设备
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 是否已连接
  bool get isConnected => _connectedDevice != null && 
      _connectedDevice!.isConnected;

  /// 将四位十六进制字符串转换为完整的BLE UUID
  /// [shortUuid] 四位十六进制字符串，如 "ffe1"
  /// 返回完整UUID格式: 0000XXXX-0000-1000-8000-00805f9b34fb
  Guid _convertShortUuidToGuid(String shortUuid) {
    // 移除可能的前缀和后缀，只保留四位十六进制
    final cleanUuid = shortUuid.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toLowerCase();
    if (cleanUuid.length != 4) {
      throw Exception('UUID必须是四位十六进制字符串，如 "ffe1"');
    }
    // 转换为完整的BLE标准UUID格式
    return Guid('0000$cleanUuid-0000-1000-8000-00805f9b34fb');
  }

  /// 检查蓝牙是否可用
  Future<bool> isBluetoothAvailable() async {
    try {
      return await FlutterBluePlus.isSupported && 
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    } catch (e) {
      print('[Bluetooth] 检查蓝牙状态失败: $e');
      return false;
    }
  }

  /// 开启蓝牙（Android）
  Future<bool> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
      return true;
    } catch (e) {
      print('[Bluetooth] 开启蓝牙失败: $e');
      return false;
    }
  }

  /// 扫描设备
  /// [duration] 扫描时长（秒），默认10秒
  /// [serviceUuids] 服务UUID过滤（可选，四位字符串列表，如 ["ffe0"]）
  Stream<List<ScanResult>> scanDevices({
    Duration duration = const Duration(seconds: 10),
    List<String>? serviceUuids,
  }) async* {
    try {
      // 检查蓝牙状态
      if (!await isBluetoothAvailable()) {
        throw Exception('蓝牙不可用');
      }

      // 转换服务UUID列表
      List<Guid> guidList = [];
      if (serviceUuids != null && serviceUuids.isNotEmpty) {
        guidList = serviceUuids.map((uuid) => _convertShortUuidToGuid(uuid)).toList();
      }

      // 开始扫描
      if (guidList.isEmpty) {
        await FlutterBluePlus.startScan(timeout: duration);
      } else {
        await FlutterBluePlus.startScan(
          timeout: duration,
          withServices: guidList,
        );
      }

      // 监听扫描结果
      await for (final results in FlutterBluePlus.scanResults) {
        yield results;
      }
    } catch (e) {
      print('[Bluetooth] 扫描设备失败: $e');
      rethrow;
    } finally {
      // 停止扫描
      await FlutterBluePlus.stopScan();
    }
  }

  /// 连接设备
  /// [device] 要连接的设备
  /// [timeout] 连接超时时间，默认15秒
  /// [autoConnect] 是否自动连接，默认false
  Future<bool> connectDevice(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
    bool autoConnect = false,
  }) async {
    try {
      // 如果已连接其他设备，先断开
      if (_connectedDevice != null && _connectedDevice != device) {
        await disconnectDevice();
      }

      // 如果已连接同一设备，直接返回
      if (_connectedDevice == device && await device.isConnected) {
        return true;
      }

      _connectedDevice = device;

      // 监听连接状态
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        print('[Bluetooth] 连接状态变化: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _cachedServices = null;
        }
      });

      // 连接设备
      await device.connect(
        timeout: timeout,
        autoConnect: autoConnect,
      );

      // 发现服务并缓存
      _cachedServices = await device.discoverServices();

      return await device.isConnected;
    } catch (e) {
      print('[Bluetooth] 连接设备失败: $e');
      _connectedDevice = null;
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnectDevice() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
      _connectedDevice = null;
      _cachedServices = null;
    } catch (e) {
      print('[Bluetooth] 断开连接失败: $e');
    }
  }

  /// 根据UUID查找特征值
  /// [characteristicUuid] 特征值UUID（四位字符串，如 "ffe1"）
  /// [serviceUuid] 服务UUID（可选，四位字符串，如 "ffe0"）
  Future<BluetoothCharacteristic?> findCharacteristic(
    String characteristicUuid, {
    String? serviceUuid,
  }) async {
    try {
      if (!isConnected) {
        throw Exception('设备未连接');
      }

      // 如果服务列表未缓存，重新发现
      if (_cachedServices == null) {
        if (_connectedDevice == null) {
          throw Exception('设备未连接');
        }
        _cachedServices = await _connectedDevice!.discoverServices();
      }

      // 转换UUID
      final charGuid = _convertShortUuidToGuid(characteristicUuid);
      final serviceGuid = serviceUuid != null ? _convertShortUuidToGuid(serviceUuid) : null;

      // 搜索特征值
      for (var service in _cachedServices!) {
        // 如果指定了服务UUID，只在该服务中搜索
        if (serviceGuid != null && service.uuid != serviceGuid) {
          continue;
        }

        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == charGuid) {
            return characteristic;
          }
        }
      }

      return null;
    } catch (e) {
      print('[Bluetooth] 查找特征值失败: $e');
      rethrow;
    }
  }

  /// 写入WiFi配置
  /// [ssid] WiFi名称
  /// [password] WiFi密码
  /// [characteristicUuid] 特征值UUID（四位字符串，如 "ffe1"）
  /// [serviceUuid] 服务UUID（可选，四位字符串，如 "ffe0"）
  Future<bool> writeWifiConfig({
    required String ssid,
    required String password,
    required String characteristicUuid,
    String? serviceUuid,
  }) async {
    try {
      if (!isConnected) {
        throw Exception('设备未连接');
      }

      // 查找特征值
      final targetCharacteristic = await findCharacteristic(characteristicUuid, serviceUuid: serviceUuid);
      if (targetCharacteristic == null) {
        throw Exception('未找到WiFi配置特征值');
      }

      // 检查特征值是否可写
      if (!targetCharacteristic.properties.write) {
        throw Exception('特征值不支持写入');
      }

      // 构造配置数据，格式: "SSID:password"
      final configData = '$ssid:$password';
      final bytes = Uint8List.fromList(configData.codeUnits);

      // 写入数据
      await targetCharacteristic.write(bytes, withoutResponse: false);

      return true;
    } catch (e) {
      print('[Bluetooth] 写入WiFi配置失败: $e');
      rethrow;
    }
  }

  /// 写入MQTT配置
  /// [broker] MQTT Broker地址
  /// [port] MQTT端口
  /// [clientId] 客户端ID
  /// [username] 用户名（可选）
  /// [password] 密码（可选）
  /// [characteristicUuid] 特征值UUID（四位字符串，如 "ffe2"）
  /// [serviceUuid] 服务UUID（可选，四位字符串，如 "ffe0"）
  Future<bool> writeMqttConfig({
    required String broker,
    required int port,
    required String clientId,
    String? username,
    String? password,
    required String characteristicUuid,
    String? serviceUuid,
  }) async {
    try {
      if (!isConnected) {
        throw Exception('设备未连接');
      }

      // 查找特征值
      final targetCharacteristic = await findCharacteristic(characteristicUuid, serviceUuid: serviceUuid);
      if (targetCharacteristic == null) {
        throw Exception('未找到MQTT配置特征值');
      }

      // 检查特征值是否可写
      if (!targetCharacteristic.properties.write) {
        throw Exception('特征值不支持写入');
      }

      // 构造配置数据，格式: "broker:port;clientId:xxx;username:xxx;password:xxx"
      final configMap = {
        'broker': broker,
        'port': port,
        'clientId': clientId,
        if (username != null) 'username': username,
        if (password != null) 'password': password,
      };
      final configJson = configMap.entries
          .map((e) => '${e.key}:${e.value}')
          .join(';');
      final bytes = Uint8List.fromList(configJson.codeUnits);

      // 写入数据
      await targetCharacteristic.write(bytes, withoutResponse: false);

      return true;
    } catch (e) {
      print('[Bluetooth] 写入MQTT配置失败: $e');
      rethrow;
    }
  }

  /// 读取特征值
  /// [characteristic] 特征值
  Future<Uint8List> readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      if (!isConnected) {
        throw Exception('设备未连接');
      }

      if (!characteristic.properties.read) {
        throw Exception('特征值不支持读取');
      }

      final result = await characteristic.read();
      return Uint8List.fromList(result);
    } catch (e) {
      print('[Bluetooth] 读取特征值失败: $e');
      rethrow;
    }
  }

  /// 监听特征值通知
  /// [characteristic] 特征值
  Stream<Uint8List> listenToCharacteristic(BluetoothCharacteristic characteristic) async* {
    try {
      if (!isConnected) {
        throw Exception('设备未连接');
      }

      if (!characteristic.properties.notify) {
        throw Exception('特征值不支持通知');
      }

      // 启用通知
      await characteristic.setNotifyValue(true);

      // 监听数据
      await for (final value in characteristic.onValueReceived) {
        yield Uint8List.fromList(value);
      }
    } catch (e) {
      print('[Bluetooth] 监听特征值失败: $e');
      rethrow;
    }
  }

  /// 获取设备的所有服务
  Future<List<BluetoothService>> getServices() async {
    try {
      if (!isConnected || _connectedDevice == null) {
        throw Exception('设备未连接');
      }

      return await _connectedDevice!.discoverServices();
    } catch (e) {
      print('[Bluetooth] 获取服务失败: $e');
      rethrow;
    }
  }

  /// 关闭并释放资源
  Future<void> dispose() async {
    try {
      await disconnectDevice();
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('[Bluetooth] 释放资源失败: $e');
    }
  }
}

