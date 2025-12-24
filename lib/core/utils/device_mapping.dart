/// 设备类型映射工具
class DeviceMapping {
  DeviceMapping._();

  /// 设备型号到卡片类型的映射
  static const Map<String, String> deviceTypeMapping = {
    // 空调
    'AC001': 'AirCoolerCard',
    'AC002': 'AirCoolerCard',
    'AC003': 'AirCoolerCard',

    // 摄像头
    'CAM001': 'CameraCard',
    'CAM002': 'CameraCard',
    'CAM003': 'CameraCard',

    // 智能灯
    'LIGHT001': 'SmartLightCard',
    'LIGHT002': 'SmartLightCard',
    'LIGHT003': 'SmartLightCard',

    // 智能电视
    'TV001': 'SmartTvCard',
    'TV002': 'SmartTvCard',
    'TV003': 'SmartTvCard',

    // 跌倒检测器
    'FALL001': 'FallDetectionCard',
    'FALL002': 'FallDetectionCard',
    'FALL003': 'FallDetectionCard',

    // 路由器
    'WIFI001': 'WiFiCard',
    'WIFI002': 'WiFiCard',
    'WIFI003': 'WiFiCard',

    // 扫地机器人
    'ROBOT001': 'VacuumCard',
    'ROBOT002': 'VacuumCard',
    'ROBOT003': 'VacuumCard',

    // 洗衣机
    'WASH001': 'WashingMachineCard',
    'WASH002': 'WashingMachineCard',
    'WASH003': 'WashingMachineCard',

    // 冰箱
    'FRIDGE001': 'RefrigeratorCard',
    'FRIDGE002': 'RefrigeratorCard',
    'FRIDGE003': 'RefrigeratorCard',

    // 音箱
    'SPEAKER001': 'SpeakerCard',
    'SPEAKER002': 'SpeakerCard',
    'SPEAKER003': 'SpeakerCard',

    // 空气净化器
    'AIR001': 'AirPurifierCard',
    'AIR002': 'AirPurifierCard',
    'AIR003': 'AirPurifierCard',

    // 环境监测
    'M701001': 'EnvironmentMonitorCard',
  };

  /// 根据 SN 获取卡片类型
  /// SN 格式支持: MODEL-YYMMDD-SERIAL 或 MODEL_YYMMDD_SERIAL
  static String getCardTypeBySN(String sn) {
    final modelCode = getModelCodeBySN(sn);
    return deviceTypeMapping[modelCode] ?? 'UnknownCard';
  }

  /// 根据 SN 获取型号代码
  /// SN 格式支持: MODEL-YYMMDD-SERIAL 或 MODEL_YYMMDD_SERIAL
  static String getModelCodeBySN(String sn) {
    // 支持两种格式分隔符: - 或 _
    List<String> parts;
    if (sn.contains('_')) {
      parts = sn.split('_');
    } else if (sn.contains('-')) {
      parts = sn.split('-');
    } else {
      return sn; // 如果没有分隔符，整个字符串就是型号
    }
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// 根据型号代码获取设备名称
  static String getDeviceNameByModel(String modelCode) {
    const modelNames = {
      'AC001': '空调',
      'AC002': '空调',
      'AC003': '空调',
      'CAM001': '摄像头',
      'CAM002': '摄像头',
      'CAM003': '摄像头',
      'LIGHT001': '智能灯',
      'LIGHT002': '智能灯',
      'LIGHT003': '智能灯',
      'TV001': '智能电视',
      'TV002': '智能电视',
      'TV003': '智能电视',
      'FALL001': '跌倒检测器',
      'FALL002': '跌倒检测器',
      'FALL003': '跌倒检测器',
      'WIFI001': '路由器',
      'WIFI002': '路由器',
      'WIFI003': '路由器',
      'ROBOT001': '扫地机器人',
      'ROBOT002': '扫地机器人',
      'ROBOT003': '扫地机器人',
      'WASH001': '洗衣机',
      'WASH002': '洗衣机',
      'WASH003': '洗衣机',
      'FRIDGE001': '冰箱',
      'FRIDGE002': '冰箱',
      'FRIDGE003': '冰箱',
      'SPEAKER001': '音箱',
      'SPEAKER002': '音箱',
      'SPEAKER003': '音箱',
      'AIR001': '空气净化器',
      'AIR002': '空气净化器',
      'AIR003': '空气净化器',
      'M701001': '环境监测器',
    };

    return modelNames[modelCode] ?? '未知设备';
  }

  /// 根据型号代码获取设备图标
  static String getDeviceIconByModel(String modelCode) {
    if (modelCode.startsWith('AC')) return '❄️';
    if (modelCode.startsWith('CAM')) return '📷';
    if (modelCode.startsWith('LIGHT')) return '💡';
    if (modelCode.startsWith('TV')) return '📺';
    if (modelCode.startsWith('FALL')) return '🚨';
    if (modelCode.startsWith('WIFI')) return '📡';
    if (modelCode.startsWith('ROBOT')) return '🤖';
    if (modelCode.startsWith('WASH')) return '🧺';
    if (modelCode.startsWith('FRIDGE')) return '🧊';
    if (modelCode.startsWith('SPEAKER')) return '🔊';
    if (modelCode.startsWith('AIR')) return '💨';
    if (modelCode.startsWith('M701')) return '🌡️';
    return '📱';
  }
}

