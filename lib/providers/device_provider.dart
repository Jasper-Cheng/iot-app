import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/device.dart';
import '../data/repositories/device_repository.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart';

/// 设备列表状态
class DeviceListState {
  final List<Device> devices;
  final bool isLoading;
  final String? error;

  const DeviceListState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
  });

  DeviceListState copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
  }) {
    return DeviceListState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 设备列表状态管理
class DeviceListNotifier extends StateNotifier<DeviceListState> {
  final DeviceRepository _repository;
  final int? _currentFamilyId;

  DeviceListNotifier(
    this._repository, {
    int? currentFamilyId,
  })  : _currentFamilyId = currentFamilyId,
        super(const DeviceListState()) {
    // 不在构造函数中自动加载，由 MainScreen 统一管理加载时机
  }

  /// 加载设备列表
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> loadDevices() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final devices = await _repository.getDevices(familyId: _currentFamilyId);
      state = state.copyWith(
        devices: devices,
        isLoading: false,
        error: null, // 清除之前的错误
      );
      return (success: true, message: '设备列表加载成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return (success: false, message: errorMessage);
    }
  }

  /// 绑定设备
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> bindDevice(String sn, {String? name}) async {
    try {
      await _repository.bindDevice(sn, name: name);
      // 如果当前在家庭模式下，重新加载设备列表（只显示家庭中的设备）
      // 如果不在家庭模式下，重新加载设备列表（显示个人设备）
      await loadDevices();
      state = state.copyWith(error: null); // 清除之前的错误
      return (success: true, message: '设备绑定成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 解绑设备
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> unbindDevice(String sn) async {
    try {
      await _repository.unbindDevice(sn);
      state = state.copyWith(
        devices: state.devices.where((d) => d.sn != sn).toList(),
        error: null, // 清除之前的错误
      );
      return (success: true, message: '设备已解绑');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 更新设备名称
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> updateDeviceName(int id, String name) async {
    try {
      final updatedDevice = await _repository.updateDeviceName(
        id,
        name,
        familyId: _currentFamilyId,
      );
      final devices = state.devices.map((d) {
        return d.id == id ? updatedDevice : d;
      }).toList();
      state = state.copyWith(
        devices: devices,
        error: null, // 清除之前的错误
      );
      return (success: true, message: '设备名称已更新');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 刷新设备列表
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> refresh() async {
    return await loadDevices();
  }
}

/// 设备列表 Provider
final deviceListProvider = StateNotifierProvider<DeviceListNotifier, DeviceListState>((ref) {
  // 只监听 currentFamilyId 的变化，忽略其他字段（如昵称、头像等）的变化
  // 这样修改用户信息时不会导致 deviceListProvider 重新创建，但切换家庭时会自动重建
  final currentFamilyId = ref.watch(authProvider.select((state) => state.account?.currentFamilyId));
  
  return DeviceListNotifier(
    DeviceRepository(),
    currentFamilyId: currentFamilyId,
  );
});

