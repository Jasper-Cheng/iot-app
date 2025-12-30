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
  final FamilyRepository _repository;
  final int? _currentUserId;

  FamilyListNotifier(this._repository, {int? currentUserId})
      : _currentUserId = currentUserId,
        super(const FamilyListState()) {
    // 在构造函数中自动加载家庭列表
    loadFamilies(currentUserId: currentUserId);
  }

  /// 加载家庭列表
  /// [currentUserId] 当前用户 ID，如果提供则在加载成功后自动加载角色信息
  Future<void> loadFamilies({int? currentUserId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final families = await _repository.getFamilies();
      state = state.copyWith(
        families: families,
        isLoading: false,
        familyUserRoles: {}, // 清空之前的角色信息
      );
      
      // 如果提供了用户 ID，在加载成功后自动加载所有家庭的角色信息
      if (currentUserId != null && families.isNotEmpty) {
        // 使用 Future.microtask 确保状态更新后再加载角色
        Future.microtask(() {
          _loadAllFamilyRolesAsync(currentUserId, families);
        });
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 异步加载所有家庭的当前用户角色（不阻塞主流程）
  Future<void> _loadAllFamilyRolesAsync(int currentUserId, List<family_models.Family> families) async {
    if (families.isEmpty) {
      return;
    }

    final Map<int, String> roles = {};
    
    // 并发加载所有家庭的成员信息
    await Future.wait(
      families.map((family) async {
        try {
          final members = await _repository.getFamilyMembers(family.id);
            final member = members.firstWhere(
              (m) => m.accountId == currentUserId,
              orElse: () => throw StateError('Member not found'),
            );
          roles[family.id] = member.role;
        } catch (e) {
          // 忽略错误，继续加载其他家庭
          print('[FamilyProvider] 加载家庭 ${family.id} 的角色失败: $e');
        }
      }),
    );

    // 更新状态（只有在当前状态仍然为空时才更新，避免覆盖）
    if (state.familyUserRoles.isEmpty && roles.isNotEmpty) {
      state = state.copyWith(familyUserRoles: roles);
      print('[FamilyProvider] 已加载 ${roles.length} 个家庭的角色信息: $roles');
    }
  }


  /// 创建家庭
  Future<void> createFamily({
    required String name,
    String? avatar,
    String? description,
  }) async {
    try {
      final family = await _repository.createFamily(
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
      await _repository.deleteFamily(id);
      state = state.copyWith(
        families: state.families.where((f) => f.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 加入家庭
  Future<void> joinFamily(String inviteCode, {String? nickname}) async {
    try {
      final family = await _repository.joinFamily(inviteCode, nickname: nickname);
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
      await loadMembers(family.id);
    } else {
      state = state.copyWith(members: []);
    }
  }

  /// 加载家庭成员
  Future<void> loadMembers(int familyId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final members = await _repository.getFamilyMembers(familyId);
      state = state.copyWith(
        members: members,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 更新成员昵称
  Future<void> updateMemberNickname(int memberId, String nickname) async {
    try {
      final updatedMember = await _repository.updateMemberNickname(
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
      await _repository.removeMember(memberId);
      state = state.copyWith(
        members: state.members.where((m) => m.id != memberId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
    }
  }

  /// 刷新
  /// [currentUserId] 当前用户 ID，如果提供则在加载成功后自动加载角色信息
  Future<void> refresh({int? currentUserId}) async {
    await loadFamilies(currentUserId: currentUserId);
    if (state.currentFamily != null) {
      await loadMembers(state.currentFamily!.id);
    }
  }

  /// 加载所有家庭的当前用户角色
  Future<void> loadAllFamilyRoles(int currentUserId) async {
    // 如果已经有角色信息或者家庭列表为空，不重复加载
    if (state.families.isEmpty || state.familyUserRoles.isNotEmpty) {
      return;
    }

    final Map<int, String> roles = {};
    
    // 并发加载所有家庭的成员信息
    await Future.wait(
      state.families.map((family) async {
        try {
          final members = await _repository.getFamilyMembers(family.id);
            final member = members.firstWhere(
              (m) => m.accountId == currentUserId,
              orElse: () => throw StateError('Member not found'),
            );
          roles[family.id] = member.role;
        } catch (e) {
          // 忽略错误，继续加载其他家庭
        }
      }),
    );

    // 更新状态（只有在当前状态仍然为空时才更新，避免覆盖）
    if (state.familyUserRoles.isEmpty) {
      state = state.copyWith(familyUserRoles: roles);
    }
  }
}

/// 家庭列表 Provider
final familyListProvider = StateNotifierProvider<FamilyListNotifier, FamilyListState>((ref) {
  // 从 authProvider 获取当前用户 ID
  final authState = ref.watch(authProvider);
  final currentUserId = authState.account?.id;
  return FamilyListNotifier(FamilyRepository(), currentUserId: currentUserId);
});

