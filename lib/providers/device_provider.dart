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
  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final devices = await _repository.getDevices(familyId: _currentFamilyId);
      state = state.copyWith(
        devices: devices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 绑定设备
  Future<void> bindDevice(String sn, {String? name}) async {
    try {
      await _repository.bindDevice(sn, name: name);
      // 如果当前在家庭模式下，重新加载设备列表（只显示家庭中的设备）
      // 如果不在家庭模式下，重新加载设备列表（显示个人设备）
      await loadDevices();
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
      rethrow; // 重新抛出异常，让UI层能够捕获
    }
  }

  /// 解绑设备
  Future<void> unbindDevice(String sn) async {
    try {
      await _repository.unbindDevice(sn);
      state = state.copyWith(
        devices: state.devices.where((d) => d.sn != sn).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 更新设备名称
  Future<void> updateDeviceName(int id, String name) async {
    try {
      final updatedDevice = await _repository.updateDeviceName(id, name);
      final devices = state.devices.map((d) {
        return d.id == id ? updatedDevice : d;
      }).toList();
      state = state.copyWith(devices: devices);
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 刷新设备列表
  Future<void> refresh() async {
    await loadDevices();
  }
}

/// 设备列表 Provider
final deviceListProvider = StateNotifierProvider<DeviceListNotifier, DeviceListState>((ref) {
  // 从 authProvider 获取当前家庭 ID
  final authState = ref.watch(authProvider);
  final currentFamilyId = authState.account?.currentFamilyId;
  return DeviceListNotifier(
    DeviceRepository(),
    currentFamilyId: currentFamilyId,
  );
});

