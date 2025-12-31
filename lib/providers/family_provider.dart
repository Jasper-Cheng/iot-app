import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/family.dart' as family_models;
import '../data/repositories/family_repository.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart';

/// 家庭列表状态
class FamilyListState {
  final List<family_models.Family> families;
  final family_models.Family? currentFamily;
  final List<family_models.FamilyMember> members;
  final Map<int, String> familyUserRoles; // 每个家庭中当前用户的角色
  final bool isLoading;
  final String? error;

  const FamilyListState({
    this.families = const [],
    this.currentFamily,
    this.members = const [],
    this.familyUserRoles = const {},
    this.isLoading = false,
    this.error,
  });

  FamilyListState copyWith({
    List<family_models.Family>? families,
    family_models.Family? currentFamily,
    List<family_models.FamilyMember>? members,
    Map<int, String>? familyUserRoles,
    bool? isLoading,
    String? error,
  }) {
    return FamilyListState(
      families: families ?? this.families,
      currentFamily: currentFamily ?? this.currentFamily,
      members: members ?? this.members,
      familyUserRoles: familyUserRoles ?? this.familyUserRoles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 家庭列表状态管理
class FamilyListNotifier extends StateNotifier<FamilyListState> {
  final FamilyRepository _familyRepository;
  final int? _currentUserId;
  final int? _currentFamilyId;

  FamilyListNotifier(
    this._familyRepository, {
    int? currentUserId,
    int? currentFamilyId,
  })  : _currentUserId = currentUserId,
        _currentFamilyId = currentFamilyId,
        super(const FamilyListState()) {
    // 不在构造函数中自动加载，由 FamilyScreen 统一管理加载时机
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

      // 3. 加载成员信息
      // 注意：设备列表已在 deviceListProvider 中统一管理，不需要重复加载
      await loadMembers(familyId);
    } catch (e) {
      print('[FamilyProvider] 加载当前家庭数据失败: $e');
      state = state.copyWith(
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 加载家庭列表
  Future<void> loadFamilies() async {
    // 如果未登录（没有用户ID），不加载家庭列表
    if (_currentUserId == null) {
      state = state.copyWith(
        families: [],
        currentFamily: null,
        members: [],
        familyUserRoles: {},
        isLoading: false,
      );
      return;
    }

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
          // 直接加载当前家庭数据，确保顺序执行
          await loadCurrentFamilyData(_currentFamilyId!);
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
        );
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 加入家庭
  Future<void> joinFamily(String inviteCode, {String? nickname}) async {
    try {
      // 调用API加入家庭，返回family_id
      await _familyRepository.joinFamily(inviteCode, nickname: nickname);
      // 重新加载家庭列表，获取最新的家庭信息（包括新加入的家庭）
      await loadFamilies();
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
            (m) => m.account.id == _currentUserId,
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
      rethrow; // 重新抛出异常，让调用者知道失败了
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

  /// 添加设备到家庭
  Future<void> addDeviceToFamily(int familyId, int deviceId) async {
    try {
      await _familyRepository.addDeviceToFamily(familyId, deviceId);
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
      rethrow;
    }
  }

  /// 从家庭移除设备
  Future<void> removeDeviceFromFamily(int familyId, int deviceId) async {
    try {
      await _familyRepository.removeDeviceFromFamily(familyId, deviceId);
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
      rethrow;
    }
  }

  /// 刷新
  Future<void> refresh() async {
    // loadFamilies() 已经会加载当前家庭数据（如果有 currentFamilyId）
    // 所以这里只需要调用 loadFamilies() 即可，避免重复加载
    await loadFamilies();
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
    currentUserId: currentUserId,
    currentFamilyId: currentFamilyId,
  );
});

