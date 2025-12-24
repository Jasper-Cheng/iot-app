import 'package:flutter/material.dart';
import '../../../data/models/device.dart';
import '../../../core/utils/device_mapping.dart';
import '../../device_cards/air_cooler_card.dart';
import '../../device_cards/smart_light_card.dart';
import '../../device_cards/camera_card.dart';
import '../../device_cards/smart_tv_card.dart';
import '../../device_cards/fall_detection_card.dart';
import '../../device_cards/wifi_card.dart';
import '../../device_cards/vacuum_card.dart';
import '../../device_cards/washing_machine_card.dart';
import '../../device_cards/refrigerator_card.dart';
import '../../device_cards/speaker_card.dart';
import '../../device_cards/air_purifier_card.dart';
import '../../device_cards/environment_monitor_card.dart';
import 'device_card.dart'; // 通用设备卡片

/// 设备卡片工厂
/// 根据设备SN动态创建对应的设备卡片
class DeviceCardFactory {
  /// 根据设备创建对应的卡片Widget
  static Widget createCard(Device device) {
    // 从SN中解析卡片类型
    final cardType = DeviceMapping.getCardTypeBySN(device.sn);
    
    // 根据卡片类型返回对应的Widget
    switch (cardType) {
      case 'AirCoolerCard':
        return AirCoolerCard(device: device);
      
      case 'SmartLightCard':
        return SmartLightCard(device: device);
      
      case 'CameraCard':
        return CameraCard(device: device);
      
      case 'SmartTvCard':
        return SmartTvCard(device: device);
      
      case 'FallDetectionCard':
        return FallDetectionCard(device: device);
      
      case 'WiFiCard':
        return WiFiCard(device: device);
      
      case 'VacuumCard':
        return VacuumCard(device: device);
      
      case 'WashingMachineCard':
        return WashingMachineCard(device: device);
      
      case 'RefrigeratorCard':
        return RefrigeratorCard(device: device);
      
      case 'SpeakerCard':
        return SpeakerCard(device: device);
      
      case 'AirPurifierCard':
        return AirPurifierCard(device: device);
      
      case 'EnvironmentMonitorCard':
        return EnvironmentMonitorCard(device: device);
      
      default:
        // 未知设备类型，使用通用卡片
        return DeviceCard(device: device);
    }
  }
  
  /// 判断是否支持该设备类型
  static bool isSupported(String sn) {
    final cardType = DeviceMapping.getCardTypeBySN(sn);
    return cardType != 'UnknownCard';
  }
  
  /// 获取设备类型显示名称
  static String getDeviceTypeName(String sn) {
    final modelCode = DeviceMapping.getModelCodeBySN(sn);
    return DeviceMapping.getDeviceNameByModel(modelCode);
  }
  
  /// 获取设备图标
  static String getDeviceIcon(String sn) {
    final modelCode = DeviceMapping.getModelCodeBySN(sn);
    return DeviceMapping.getDeviceIconByModel(modelCode);
  }
}

