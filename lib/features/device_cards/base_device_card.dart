import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device.dart';
import '../../providers/mqtt_provider.dart';
import '../../core/constants/api_constants.dart';

/// 设备卡片基类
/// 封装了所有设备卡片的通用逻辑：
/// - MQTT 订阅管理
/// - MQTT 数据处理器注册
/// - MQTT 状态处理器注册
/// - 设备在线状态管理
/// - 生命周期管理
abstract class BaseDeviceCard extends ConsumerStatefulWidget {
  final Device device;

  const BaseDeviceCard({
    super.key,
    required this.device,
  });
}

abstract class BaseDeviceCardState<T extends BaseDeviceCard> extends ConsumerState<T> {
  // MQTT 订阅状态
  bool _isSubscribed = false;
  
  // 设备在线状态（本地维护，通过 MQTT 状态消息更新）
  late bool isOnline;

  @override
  void initState() {
    super.initState();
    // 初始化在线状态
    isOnline = widget.device.isOnline;
    // 设置 MQTT 订阅和处理器
    _setupMqttSubscription();
    _registerDataHandler();
    _registerStatusHandler();
    // 子类可以重写此方法进行额外的初始化
    onInitState();
  }

  /// 子类可以重写此方法进行额外的初始化
  void onInitState() {}

  /// 设置 MQTT 订阅
  void _setupMqttSubscription() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final mqttNotifier = ref.read(mqttProvider.notifier);
      if (mqttNotifier.state.isConnected && !_isSubscribed) {
        mqttNotifier.subscribeDeviceData(widget.device.sn);
        mqttNotifier.subscribeDeviceStatus(widget.device.sn);
        _isSubscribed = true;
      }
    });
  }
  
  /// 注册数据处理器
  void _registerDataHandler() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.registerDeviceDataHandler(widget.device.sn, _handleDeviceData);
    });
  }
  
  /// 注册状态处理器
  void _registerStatusHandler() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.registerDeviceStatusHandler(widget.device.sn, _handleDeviceStatus);
    });
  }
  
  /// 处理设备数据（内部方法）
  void _handleDeviceData(Map<String, dynamic> data) {
    if (!mounted) return;
    
    try {
      print('[${widget.device.sn}] 收到设备数据: $data');
      // 调用子类实现的数据处理方法
      onDeviceDataReceived(data);
    } catch (e) {
      print('[${widget.device.sn}] 解析设备数据失败: $e');
    }
  }
  
  /// 处理设备状态（内部方法）
  void _handleDeviceStatus(Map<String, dynamic> data) {
    if (!mounted) return;
    
    try {
      print('[${widget.device.sn}] 收到设备状态: $data');
      
      // 处理设备在线/离线状态
      bool? newOnlineStatus;
      
      // 尝试多种可能的字段名和格式
      if (data.containsKey('status')) {
        final status = data['status'];
        if (status is String) {
          // 字符串格式：'online' 或 'offline'
          newOnlineStatus = status.toLowerCase() == 'online';
        } else if (status is bool) {
          // 布尔格式
          newOnlineStatus = status;
        }
      } else if (data.containsKey('online')) {
        newOnlineStatus = data['online'] as bool?;
      } else if (data.containsKey('isOnline')) {
        newOnlineStatus = data['isOnline'] as bool?;
      }
      
      // 如果状态发生变化，更新 UI
      if (newOnlineStatus != null && newOnlineStatus != isOnline) {
        if (mounted) {
          setState(() {
            isOnline = newOnlineStatus!;
          });
          print('[${widget.device.sn}] 设备状态变更: ${isOnline ? "在线" : "离线"}');
          // 通知子类状态已变更
          onDeviceStatusChanged(isOnline);
        }
      } else if (newOnlineStatus == null) {
        print('[${widget.device.sn}] 警告：状态消息中未找到有效的状态字段');
      }
      
      // 调用子类实现的状态处理方法（用于处理其他状态信息）
      onDeviceStatusReceived(data);
    } catch (e) {
      print('[${widget.device.sn}] 解析设备状态失败: $e');
    }
  }

  @override
  void dispose() {
    // 注销数据处理器
    try {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.unregisterDeviceDataHandler(widget.device.sn);
    } catch (e) {
      print('[${widget.device.sn}] 注销数据处理器失败: $e');
    }
    
    // 注销状态处理器
    try {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.unregisterDeviceStatusHandler(widget.device.sn);
    } catch (e) {
      print('[${widget.device.sn}] 注销状态处理器失败: $e');
    }
    
    // 取消订阅设备数据和状态
    if (_isSubscribed) {
      try {
        final mqttNotifier = ref.read(mqttProvider.notifier);
        if (mqttNotifier.state.isConnected) {
          mqttNotifier.unsubscribe(ApiConstants.mqttDeviceData(widget.device.sn));
          mqttNotifier.unsubscribe(ApiConstants.mqttDeviceStatus(widget.device.sn));
        }
      } catch (e) {
        print('[${widget.device.sn}] 取消订阅失败: $e');
      }
      _isSubscribed = false;
    }
    
    // 子类可以重写此方法进行额外的清理
    onDispose();
    
    super.dispose();
  }

  /// 子类可以重写此方法进行额外的清理
  void onDispose() {}

  // ============ 子类必须实现的抽象方法 ============

  /// 处理设备数据
  /// 子类必须实现此方法来处理接收到的设备数据
  void onDeviceDataReceived(Map<String, dynamic> data);

  // ============ 子类可选实现的方法 ============

  /// 处理设备状态数据（除了在线/离线状态外的其他状态）
  /// 子类可以重写此方法来处理额外的状态信息
  void onDeviceStatusReceived(Map<String, dynamic> data) {}

  /// 设备在线状态变更回调
  /// 子类可以重写此方法来响应设备在线状态的变化
  void onDeviceStatusChanged(bool isOnline) {}
}

