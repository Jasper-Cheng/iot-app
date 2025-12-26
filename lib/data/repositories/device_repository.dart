import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/device.dart';

/// 设备数据仓库
class DeviceRepository {
  final _dio = DioClient().dio;

  /// 获取设备列表
  Future<List<Device>> getDevices() async {
    final response = await _dio.get(ApiConstants.devices);
    final List<dynamic> data = response.data;
    return data.map((e) => Device.fromJson(e)).toList();
  }

  /// 绑定设备
  Future<Device> bindDevice(String sn, {String? name}) async {
    final request = BindDeviceRequest(sn: sn, name: name??'新设备');
    final response = await _dio.post(
      ApiConstants.bindDevice,
      data: request.toJson(),
    );
    return Device.fromJson(response.data);
  }

  /// 解绑设备
  Future<void> unbindDevice(String sn) async {
    await _dio.delete(ApiConstants.unbindDevice(sn));
  }

  /// 修改设备名称
  Future<Device> updateDeviceName(int id, String name) async {
    final request = UpdateDeviceNameRequest(name: name);
    final response = await _dio.patch(
      ApiConstants.updateDeviceName(id),
      data: request.toJson(),
    );
    return Device.fromJson(response.data);
  }
}

