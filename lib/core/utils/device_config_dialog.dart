import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_helper.dart';
import 'wifi_helper.dart';

/// 配网工具类弹窗
class DeviceConfigDialog extends StatefulWidget {
  /// 设备MAC地址（可选，优先使用）
  final String? deviceMac;
  
  /// 设备名称（可选，MAC不存在时使用）
  final String? deviceName;
  
  /// WiFi配置特征值UUID（四位字符串，如 "ffe1"）
  final String wifiCharacteristicUuid;
  
  /// MQTT配置特征值UUID（四位字符串，如 "ffe2"）
  final String mqttCharacteristicUuid;
  
  /// 服务UUID（可选，四位字符串，如 "ffe0"）
  final String? serviceUuid;
  
  /// MQTT服务器地址
  final String mqttBroker;
  
  /// MQTT端口
  final int mqttPort;

  const DeviceConfigDialog({
    super.key,
    this.deviceMac,
    this.deviceName,
    required this.wifiCharacteristicUuid,
    required this.mqttCharacteristicUuid,
    this.serviceUuid,
    this.mqttBroker = '192.168.12.119',
    this.mqttPort = 1883,
  });

  @override
  State<DeviceConfigDialog> createState() => _DeviceConfigDialogState();

  /// 显示配网弹窗
  static Future<bool?> show(
    BuildContext context, {
    String? deviceMac,
    String? deviceName,
    required String wifiCharacteristicUuid,
    required String mqttCharacteristicUuid,
    String? serviceUuid,
    String mqttBroker = '192.168.12.119',
    int mqttPort = 1883,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeviceConfigDialog(
        deviceMac: deviceMac,
        deviceName: deviceName,
        wifiCharacteristicUuid: wifiCharacteristicUuid,
        mqttCharacteristicUuid: mqttCharacteristicUuid,
        serviceUuid: serviceUuid,
        mqttBroker: mqttBroker,
        mqttPort: mqttPort,
      ),
    );
  }
}

class _DeviceConfigDialogState extends State<DeviceConfigDialog> {
  final BluetoothHelper _bluetoothHelper = BluetoothHelper();
  final WifiHelper _wifiHelper = WifiHelper();
  
  // 状态
  ConfigStep _currentStep = ConfigStep.scanning;
  String _statusMessage = '正在扫描蓝牙设备...';
  BluetoothDevice? _targetDevice;
  List<ScanResult> _scanResults = [];
  List<WifiInfo> _wifiList = [];
  WifiInfo? _selectedWifi;
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startConfig();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _bluetoothHelper.dispose();
    _wifiHelper.dispose();
    super.dispose();
  }

  /// 开始配网流程
  Future<void> _startConfig() async {
    try {
      // 步骤1: 检查蓝牙
      setState(() {
        _currentStep = ConfigStep.scanning;
        _statusMessage = '检查蓝牙状态...';
        _isLoading = true;
        _errorMessage = null;
      });

      if (!await _bluetoothHelper.isBluetoothAvailable()) {
        final turnedOn = await _bluetoothHelper.turnOnBluetooth();
        if (!turnedOn) {
          throw Exception('蓝牙不可用，请开启蓝牙后重试');
        }
      }

      // 步骤2: 扫描设备
      setState(() {
        _statusMessage = '正在扫描蓝牙设备...';
      });

      BluetoothDevice? foundDevice;

      // 如果有MAC地址，优先使用MAC连接
      if (widget.deviceMac != null && widget.deviceMac!.isNotEmpty) {
        foundDevice = await _scanAndFindByMac(widget.deviceMac!);
      }
      
      // 如果MAC没找到，使用名称
      if (foundDevice == null && widget.deviceName != null && widget.deviceName!.isNotEmpty) {
        foundDevice = await _scanAndFindByName(widget.deviceName!);
      }

      if (foundDevice == null) {
        throw Exception('未找到目标设备，请确保设备已开启并处于可发现状态');
      }

      _targetDevice = foundDevice;

      // 步骤3: 连接设备
      setState(() {
        _currentStep = ConfigStep.connecting;
        _statusMessage = '正在连接设备...';
      });

      final connected = await _bluetoothHelper.connectDevice(
        foundDevice,
        timeout: const Duration(seconds: 15),
      );

      if (!connected) {
        throw Exception('连接设备失败，请重试');
      }

      // 步骤4: 获取WiFi列表
      setState(() {
        _currentStep = ConfigStep.selectingWifi;
        _statusMessage = '正在获取WiFi列表...';
      });

      await _loadWifiList();

      setState(() {
        _currentStep = ConfigStep.selectingWifi;
        _statusMessage = '请选择WiFi网络';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// 通过MAC地址扫描并查找设备
  Future<BluetoothDevice?> _scanAndFindByMac(String mac) async {
    try {
      await for (final results in _bluetoothHelper.scanDevices(
        duration: const Duration(seconds: 10),
      )) {
        setState(() {
          _scanResults = results;
        });

        for (var result in results) {
          final deviceMac = result.device.remoteId.str.toUpperCase();
          if (deviceMac == mac.toUpperCase()) {
            await FlutterBluePlus.stopScan();
            return result.device;
          }
        }
      }
    } catch (e) {
      print('[DeviceConfig] 扫描设备失败: $e');
    }
    return null;
  }

  /// 通过名称扫描并查找设备
  Future<BluetoothDevice?> _scanAndFindByName(String name) async {
    try {
      await for (final results in _bluetoothHelper.scanDevices(
        duration: const Duration(seconds: 10),
      )) {
        setState(() {
          _scanResults = results;
        });

        for (var result in results) {
          final deviceName = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.device.remoteId.str;
          if (deviceName.contains(name)) {
            await FlutterBluePlus.stopScan();
            return result.device;
          }
        }
      }
    } catch (e) {
      print('[DeviceConfig] 扫描设备失败: $e');
    }
    return null;
  }

  /// 加载WiFi列表
  Future<void> _loadWifiList() async {
    try {
      final wifiList = await _wifiHelper.scanWifiList();
      setState(() {
        _wifiList = wifiList;
      });
    } catch (e) {
      throw Exception('获取WiFi列表失败: ${e.toString()}');
    }
  }

  /// 选择WiFi
  void _selectWifi(WifiInfo wifi) {
    setState(() {
      _selectedWifi = wifi;
      _passwordController.clear();
    });
  }

  /// 开始配置
  Future<void> _startConfigure() async {
    if (_selectedWifi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择WiFi网络')),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入WiFi密码')),
      );
      return;
    }

    setState(() {
      _currentStep = ConfigStep.configuring;
      _statusMessage = '正在配置WiFi...';
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 写入WiFi配置（JSON格式）
      final wifiConfig = {
        'ssid': _selectedWifi!.ssid,
        'password': _passwordController.text,
      };
      final wifiConfigJson = jsonEncode(wifiConfig);
      final wifiBytes = Uint8List.fromList(wifiConfigJson.codeUnits);

      // 获取WiFi配置特征值
      final wifiChar = await _bluetoothHelper.findCharacteristic(
        widget.wifiCharacteristicUuid,
        serviceUuid: widget.serviceUuid,
      );

      if (wifiChar == null) {
        throw Exception('未找到WiFi配置特征值');
      }

      // 写入WiFi配置
      await wifiChar.write(wifiBytes, withoutResponse: false);

      setState(() {
        _statusMessage = 'WiFi配置成功，正在配置MQTT...';
      });

      // 等待一下，确保WiFi配置已生效
      await Future.delayed(const Duration(seconds: 1));

      // 写入MQTT配置（JSON格式）
      final mqttConfig = {
        'broker': widget.mqttBroker,
        'port': widget.mqttPort,
      };
      final mqttConfigJson = jsonEncode(mqttConfig);
      final mqttBytes = Uint8List.fromList(mqttConfigJson.codeUnits);

      // 获取MQTT配置特征值
      final mqttChar = await _bluetoothHelper.findCharacteristic(
        widget.mqttCharacteristicUuid,
        serviceUuid: widget.serviceUuid,
      );

      if (mqttChar == null) {
        throw Exception('未找到MQTT配置特征值');
      }

      // 写入MQTT配置
      await mqttChar.write(mqttBytes, withoutResponse: false);

      setState(() {
        _currentStep = ConfigStep.success;
        _statusMessage = '配网成功！';
        _isLoading = false;
      });

      // 延迟关闭弹窗
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设备配网'),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startConfig,
            child: const Text('重试'),
          ),
        ],
      );
    }

    switch (_currentStep) {
      case ConfigStep.scanning:
      case ConfigStep.connecting:
        return _buildLoadingView();
      case ConfigStep.selectingWifi:
        return _buildWifiSelectionView();
      case ConfigStep.configuring:
        return _buildLoadingView();
      case ConfigStep.success:
        return _buildSuccessView();
    }
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(_statusMessage),
      ],
    );
  }

  Widget _buildWifiSelectionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已连接设备: ${_targetDevice?.platformName.isNotEmpty == true ? _targetDevice!.platformName : _targetDevice?.remoteId.str ?? "未知"}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        const Text(
          '选择WiFi网络:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: _wifiList.isEmpty
              ? const Center(child: Text('未找到WiFi网络'))
              : ListView.builder(
                  itemCount: _wifiList.length,
                  itemBuilder: (context, index) {
                    final wifi = _wifiList[index];
                    final isSelected = _selectedWifi?.ssid == wifi.ssid;
                    return ListTile(
                      title: Text(wifi.ssid),
                      subtitle: Text(
                        '${wifi.is24GHz ? "2.4G" : wifi.is5GHz ? "5G" : "未知"} | 信号: ${wifi.level}dBm',
                      ),
                      selected: isSelected,
                      onTap: () => _selectWifi(wifi),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                    );
                  },
                ),
        ),
        if (_selectedWifi != null) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'WiFi密码',
              hintText: '请输入WiFi密码',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            enabled: !_isLoading,
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 48),
        const SizedBox(height: 16),
        Text(_statusMessage),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_currentStep == ConfigStep.success || _errorMessage != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ];
    }

    if (_currentStep == ConfigStep.selectingWifi) {
      return [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _startConfigure,
          child: const Text('开始配置'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
    ];
  }
}

/// 配网步骤
enum ConfigStep {
  scanning,      // 扫描设备
  connecting,    // 连接设备
  selectingWifi, // 选择WiFi
  configuring,   // 配置中
  success,       // 成功
}

