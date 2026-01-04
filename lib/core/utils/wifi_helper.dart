import 'dart:async';
import 'dart:io';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// WiFi信息模型
class WifiInfo {
  final String ssid;
  final String bssid;
  final int frequency; // MHz
  final int level; // dBm
  final String? capabilities;
  final bool is24GHz;
  final bool is5GHz;

  WifiInfo({
    required this.ssid,
    required this.bssid,
    required this.frequency,
    required this.level,
    this.capabilities,
  })  : is24GHz = frequency >= 2400 && frequency < 5000,
        is5GHz = frequency >= 5000;

  @override
  String toString() {
    return 'WifiInfo(ssid: $ssid, frequency: ${frequency}MHz, level: ${level}dBm, ${is24GHz ? "2.4G" : is5GHz ? "5G" : "Unknown"})';
  }
}

/// WiFi工具类
/// 支持获取2.4G WiFi列表、5G WiFi列表、动态刷新
class WifiHelper {
  static final WifiHelper _instance = WifiHelper._internal();
  factory WifiHelper() => _instance;
  WifiHelper._internal();

  final NetworkInfo _networkInfo = NetworkInfo();
  StreamSubscription<List<WifiInfo>>? _scanSubscription;
  Timer? _refreshTimer;

  /// 检查WiFi是否可用
  Future<bool> isWifiEnabled() async {
    try {
      if (Platform.isAndroid) {
        return await WiFiForIoTPlugin.isEnabled();
      } else if (Platform.isIOS) {
        // iOS上无法直接检查WiFi状态，返回true
        return true;
      }
      return false;
    } catch (e) {
      print('[WiFi] 检查WiFi状态失败: $e');
      return false;
    }
  }

  /// 开启WiFi（Android）
  Future<bool> enableWifi() async {
    try {
      if (Platform.isAndroid) {
        return await WiFiForIoTPlugin.setEnabled(true);
      }
      return false;
    } catch (e) {
      print('[WiFi] 开启WiFi失败: $e');
      return false;
    }
  }

  /// 关闭WiFi（Android）
  Future<bool> disableWifi() async {
    try {
      if (Platform.isAndroid) {
        return await WiFiForIoTPlugin.setEnabled(false);
      }
      return false;
    } catch (e) {
      print('[WiFi] 关闭WiFi失败: $e');
      return false;
    }
  }

  /// 请求WiFi权限
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 10+ 需要位置权限来扫描WiFi
        final locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          return false;
        }

        // Android 12+ 需要精确位置权限
        final locationWhenInUseStatus = await Permission.locationWhenInUse.request();
        if (!locationWhenInUseStatus.isGranted) {
          return false;
        }

        return true;
      } else if (Platform.isIOS) {
        // iOS需要位置权限
        final locationStatus = await Permission.location.request();
        return locationStatus.isGranted;
      }
      return false;
    } catch (e) {
      print('[WiFi] 请求权限失败: $e');
      return false;
    }
  }

  /// 获取当前连接的WiFi信息
  Future<WifiInfo?> getCurrentWifi() async {
    try {
      if (Platform.isAndroid) {
        final ssid = await WiFiForIoTPlugin.getSSID();
        final bssid = await WiFiForIoTPlugin.getBSSID();
        final frequency = await WiFiForIoTPlugin.getFrequency();
        final ip = await WiFiForIoTPlugin.getIP();
        
        if (ssid != null && ssid.isNotEmpty && ssid != '<unknown ssid>') {
          return WifiInfo(
            ssid: ssid.replaceAll('"', ''),
            bssid: bssid ?? '',
            frequency: frequency ?? 0,
            level: 0, // 当前连接的WiFi无法获取信号强度
          );
        }
      } else if (Platform.isIOS) {
        final wifiName = await _networkInfo.getWifiName();
        final wifiBSSID = await _networkInfo.getWifiBSSID();
        
        if (wifiName != null && wifiName.isNotEmpty && wifiName != '<unknown ssid>') {
          return WifiInfo(
            ssid: wifiName.replaceAll('"', ''),
            bssid: wifiBSSID ?? '',
            frequency: 0, // iOS无法获取频率
            level: 0,
          );
        }
      }
      return null;
    } catch (e) {
      print('[WiFi] 获取当前WiFi失败: $e');
      return null;
    }
  }

  /// 扫描WiFi列表（Android）
  /// 注意：iOS上无法扫描WiFi列表，这是Apple的限制
  Future<List<WifiInfo>> scanWifiList() async {
    try {
      if (Platform.isAndroid) {
        // 检查权限
        if (!await requestPermissions()) {
          throw Exception('缺少WiFi扫描权限');
        }

        // 检查WiFi是否开启
        if (!await isWifiEnabled()) {
          throw Exception('WiFi未开启');
        }

        // 加载WiFi列表（触发扫描并获取结果）
        final wifiAPs = await WiFiForIoTPlugin.loadWifiList();

        // 转换为WifiInfo列表
        final wifiList = wifiAPs.map((ap) {
          return WifiInfo(
            ssid: ap.ssid ?? '',
            bssid: ap.bssid ?? '',
            frequency: ap.frequency ?? 0,
            level: ap.level ?? 0,
            capabilities: ap.capabilities,
          );
        }).toList();

        // 去重（相同SSID只保留信号最强的）
        final Map<String, WifiInfo> uniqueWifi = {};
        for (var wifi in wifiList) {
          if (wifi.ssid.isEmpty) continue;
          
          if (!uniqueWifi.containsKey(wifi.ssid) ||
              uniqueWifi[wifi.ssid]!.level < wifi.level) {
            uniqueWifi[wifi.ssid] = wifi;
          }
        }

        return uniqueWifi.values.toList();
      } else if (Platform.isIOS) {
        // iOS无法扫描WiFi列表，返回空列表或当前连接的WiFi
        final currentWifi = await getCurrentWifi();
        if (currentWifi != null) {
          return [currentWifi];
        }
        return [];
      }
      return [];
    } catch (e) {
      print('[WiFi] 扫描WiFi列表失败: $e');
      rethrow;
    }
  }

  /// 获取2.4G WiFi列表
  Future<List<WifiInfo>> get24GHzWifiList() async {
    try {
      final allWifi = await scanWifiList();
      return allWifi.where((wifi) => wifi.is24GHz).toList();
    } catch (e) {
      print('[WiFi] 获取2.4G WiFi列表失败: $e');
      rethrow;
    }
  }

  /// 获取5G WiFi列表
  Future<List<WifiInfo>> get5GHzWifiList() async {
    try {
      final allWifi = await scanWifiList();
      return allWifi.where((wifi) => wifi.is5GHz).toList();
    } catch (e) {
      print('[WiFi] 获取5G WiFi列表失败: $e');
      rethrow;
    }
  }

  /// 开始动态刷新WiFi列表
  /// [onUpdate] 更新回调
  /// [interval] 刷新间隔，默认5秒
  /// [include24GHz] 是否包含2.4G WiFi，默认true
  /// [include5GHz] 是否包含5G WiFi，默认true
  void startRefresh({
    required Function(List<WifiInfo>) onUpdate,
    Duration interval = const Duration(seconds: 5),
    bool include24GHz = true,
    bool include5GHz = true,
  }) {
    stopRefresh();

    // 立即执行一次
    _performRefresh(onUpdate, include24GHz, include5GHz);

    // 定时刷新
    _refreshTimer = Timer.periodic(interval, (_) {
      _performRefresh(onUpdate, include24GHz, include5GHz);
    });
  }

  /// 执行刷新
  Future<void> _performRefresh(
    Function(List<WifiInfo>) onUpdate,
    bool include24GHz,
    bool include5GHz,
  ) async {
    try {
      final allWifi = await scanWifiList();
      final filteredWifi = allWifi.where((wifi) {
        if (include24GHz && wifi.is24GHz) return true;
        if (include5GHz && wifi.is5GHz) return true;
        return false;
      }).toList();

      onUpdate(filteredWifi);
    } catch (e) {
      print('[WiFi] 刷新WiFi列表失败: $e');
      onUpdate([]);
    }
  }

  /// 停止动态刷新
  void stopRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 连接WiFi（Android）
  /// [ssid] WiFi名称
  /// [password] WiFi密码
  /// [security] 安全类型（WPA, WPA2, WEP等）
  Future<bool> connectToWifi({
    required String ssid,
    required String password,
    NetworkSecurity security = NetworkSecurity.WPA,
  }) async {
    try {
      if (Platform.isAndroid) {
        return await WiFiForIoTPlugin.connect(
          ssid,
          password: password,
          security: security,
          joinOnce: false,
        );
      }
      return false;
    } catch (e) {
      print('[WiFi] 连接WiFi失败: $e');
      return false;
    }
  }

  /// 断开WiFi连接（Android）
  Future<bool> disconnectWifi() async {
    try {
      if (Platform.isAndroid) {
        return await WiFiForIoTPlugin.disconnect();
      }
      return false;
    } catch (e) {
      print('[WiFi] 断开WiFi失败: $e');
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    stopRefresh();
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }
}

