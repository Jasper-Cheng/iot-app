import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/family.dart' as family_models;
import '../data/models/device.dart';
import '../data/repositories/family_repository.dart';
import '../data/repositories/device_repository.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart';

/// 家庭列表状态
class FamilyListState {
  final List<family_models.Family> families;
  final family_models.Family? currentFamily;
  final List<family_models.FamilyMember> members;
  final List<Device> devices; // 当前家庭的设备列表
  final Map<int, String> familyUserRoles; // 每个家庭中当前用户的角色
  final bool isLoading;
  final String? error;

  const FamilyListState({
    this.families = const [],
    this.currentFamily,
    this.members = const [],
    this.devices = const [],
    this.familyUserRoles = const {},
    this.isLoading = false,
    this.error,
  });

  FamilyListState copyWith({
    List<family_models.Family>? families,
    family_models.Family? currentFamily,
    List<family_models.FamilyMember>? members,
    List<Device>? devices,
    Map<int, String>? familyUserRoles,
    bool? isLoading,
    String? error,
  }) {
    return FamilyListState(
      families: families ?? this.families,
      currentFamily: currentFamily ?? this.currentFamily,
      members: members ?? this.members,
      devices: devices ?? this.devices,
      familyUserRoles: familyUserRoles ?? this.familyUserRoles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 家庭列表状态管理
class FamilyListNotifier extends StateNotifier<FamilyListState> {
  final FamilyRepository _familyRepository;
  final DeviceRepository _deviceRepository;
  final int? _currentUserId;
  final int? _currentFamilyId;

  FamilyListNotifier(
    this._familyRepository,
    this._deviceRepository, {
    int? currentUserId,
    int? currentFamilyId,
  })  : _currentUserId = currentUserId,
        _currentFamilyId = currentFamilyId,
        super(const FamilyListState()) {
    // 在构造函数中自动加载家庭列表
    // 当前家庭数据会在 loadFamilies 成功后自动加载
    loadFamilies();
  }

  /// 加载当前家庭的所有数据（家庭信息、成员信息、设备信息）
  Future<void> loadCurrentFamilyData(int familyId) async {
    try {
      // 1. 从家庭列表中找到当前家庭
      final currentFamily = state.families.firstWhere(
        (f) => f.id == familyId,
        orElse: () => throw StateError('Family not found in list'),
      );

      // 2. 设置当前家庭
      state = state.copyWith(currentFamily: currentFamily);

      // 3. 并发加载成员信息和设备信息
      await Future.wait([
        loadMembers(familyId),
        loadDevices(familyId),
      ]);
    } catch (e) {
      print('[FamilyProvider] 加载当前家庭数据失败: $e');
      state = state.copyWith(
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 加载家庭列表
  Future<void> loadFamilies() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final families = await _familyRepository.getFamilies();
      state = state.copyWith(
        families: families,
        isLoading: false,
        familyUserRoles: {}, // 清空之前的角色信息
      );

      // 如果有当前家庭ID，在加载家庭列表后自动加载当前家庭数据
      if (_currentFamilyId != null) {
        try {
          final currentFamily = families.firstWhere(
            (f) => f.id == _currentFamilyId,
          );
          // 使用 Future.microtask 确保状态更新后再加载当前家庭数据
          Future.microtask(() {
            loadCurrentFamilyData(_currentFamilyId!);
          });
        } catch (e) {
          // 当前家庭不在列表中，不加载
          print('[FamilyProvider] 当前家庭 $_currentFamilyId 不在家庭列表中');
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }




  /// 加载当前家庭的设备
  Future<void> loadDevices(int familyId) async {
    try {
      // 获取所有设备（目前API没有按家庭ID过滤的接口）
      // 注意：如果后端支持按家庭ID查询，可以在这里添加查询参数
      final allDevices = await _deviceRepository.getDevices();
      
      // 目前设备没有直接的 family_id 字段，所以暂时返回所有设备
      // 如果后端支持，可以在这里过滤出属于当前家庭的设备
      // 只加载当前家庭的设备，不加载其他家庭的设备
      state = state.copyWith(devices: allDevices);
    } catch (e) {
      print('[FamilyProvider] 加载家庭 $familyId 的设备失败: $e');
      // 设备加载失败不影响其他功能，只记录错误
    }
  }

  /// 创建家庭
  Future<void> createFamily({
    required String name,
    String? avatar,
    String? description,
  }) async {
    try {
      final family = await _familyRepository.createFamily(
        name: name,
        avatar: avatar,
        description: description,
      );
      state = state.copyWith(
        families: [...state.families, family],
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 删除家庭
  Future<void> deleteFamily(int id) async {
    try {
      await _familyRepository.deleteFamily(id);
      state = state.copyWith(
        families: state.families.where((f) => f.id != id).toList(),
      );
      // 如果删除的是当前家庭，清除当前家庭数据
      if (state.currentFamily?.id == id) {
        state = state.copyWith(
          currentFamily: null,
          members: [],
          devices: [],
        );
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 加入家庭
  Future<void> joinFamily(String inviteCode, {String? nickname}) async {
    try {
      final family = await _familyRepository.joinFamily(inviteCode, nickname: nickname);
      state = state.copyWith(
        families: [...state.families, family],
        error: null, // 清除之前的错误
      );
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      rethrow; // 重新抛出异常，让调用者知道失败了
    }
  }

  /// 选择当前家庭
  Future<void> selectFamily(family_models.Family? family) async {
    state = state.copyWith(currentFamily: family);
    if (family != null) {
      // 加载当前家庭的所有数据
      await loadCurrentFamilyData(family.id);
    } else {
      state = state.copyWith(
        members: [],
        devices: [],
      );
    }
  }

  /// 加载家庭成员
  Future<void> loadMembers(int familyId) async {
    try {
      final members = await _familyRepository.getFamilyMembers(familyId);
      state = state.copyWith(members: members);
      
      // 从已加载的成员列表中获取当前用户的角色
      if (_currentUserId != null) {
        try {
          final member = members.firstWhere(
            (m) => m.accountId == _currentUserId,
          );
          state = state.copyWith(
            familyUserRoles: {
              ...state.familyUserRoles,
              familyId: member.role,
            },
          );
        } catch (e) {
          // 当前用户不在成员列表中，忽略
          print('[FamilyProvider] 当前用户 $_currentUserId 不在家庭 $familyId 的成员列表中');
        }
      }
    } catch (e) {
      print('[FamilyProvider] 加载家庭成员失败: $e');
      state = state.copyWith(
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 获取家庭成员（不更新状态，用于展开显示）
  Future<List<family_models.FamilyMember>> getFamilyMembers(int familyId) async {
    return await _familyRepository.getFamilyMembers(familyId);
  }

  /// 更新成员昵称
  Future<void> updateMemberNickname(int memberId, String nickname) async {
    try {
      final updatedMember = await _familyRepository.updateMemberNickname(
        memberId,
        nickname,
      );
      final members = state.members.map((m) {
        return m.id == memberId ? updatedMember : m;
      }).toList();
      state = state.copyWith(members: members);
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 移除成员
  Future<void> removeMember(int memberId) async {
    try {
      await _familyRepository.removeMember(memberId);
      state = state.copyWith(
        members: state.members.where((m) => m.id != memberId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 刷新
  Future<void> refresh() async {
    await loadFamilies();
    if (state.currentFamily != null) {
      await loadCurrentFamilyData(state.currentFamily!.id);
    } else if (_currentFamilyId != null) {
      // 如果状态中没有当前家庭，但提供了当前家庭ID，尝试加载
      await loadCurrentFamilyData(_currentFamilyId!);
    }
  }
}

/// 家庭列表 Provider
final familyListProvider = StateNotifierProvider<FamilyListNotifier, FamilyListState>((ref) {
  // 从 authProvider 获取当前用户 ID 和当前家庭 ID
  final authState = ref.watch(authProvider);
  final currentUserId = authState.account?.id;
  final currentFamilyId = authState.account?.currentFamilyId;
  return FamilyListNotifier(
    FamilyRepository(),
    DeviceRepository(),
    currentUserId: currentUserId,
    currentFamilyId: currentFamilyId,
  );
});

