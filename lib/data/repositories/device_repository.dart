import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/device.dart';
import '../mock/mock_data.dart';

/// 设备数据仓库
class DeviceRepository {
  final _dio = DioClient().dio;
  final bool useMock = true; // 是否使用 Mock 数据

  /// 获取设备列表
  Future<List<Device>> getDevices() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockDevices.map((e) => Device.fromJson(e)).toList();
    }

    final response = await _dio.get(ApiConstants.devices);
    final List<dynamic> data = response.data;
    return data.map((e) => Device.fromJson(e)).toList();
  }

  /// 绑定设备
  Future<Device> bindDevice(String sn, {String? name}) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newDevice = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': name ?? '新设备',
        'sn': sn,
        'status': 'bound',
        'account_id': 1,
        'model_id': 1,
        'created_at': DateTime.now().toIso8601String(),
      };
      return Device.fromJson(newDevice);
    }

    final request = BindDeviceRequest(sn: sn, name: name);
    final response = await _dio.post(
      ApiConstants.bindDevice,
      data: request.toJson(),
    );
    return Device.fromJson(response.data);
  }

  /// 解绑设备
  Future<void> unbindDevice(String sn) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    await _dio.delete(ApiConstants.unbindDevice(sn));
  }

  /// 修改设备名称
  Future<Device> updateDeviceName(int id, String name) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final device = MockData.mockDevices.firstWhere((e) => e['id'] == id);
      device['name'] = name;
      return Device.fromJson(device);
    }

    final request = UpdateDeviceNameRequest(name: name);
    final response = await _dio.patch(
      ApiConstants.updateDeviceName(id),
      data: request.toJson(),
    );
    return Device.fromJson(response.data);
  }
}

