import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/family.dart' as family_models;
import '../data/repositories/family_repository.dart';
import '../core/utils/error_handler.dart';

/// 家庭列表状态
class FamilyListState {
  final List<family_models.Family> families;
  final family_models.Family? currentFamily;
  final List<family_models.FamilyMember> members;
  final bool isLoading;
  final String? error;

  const FamilyListState({
    this.families = const [],
    this.currentFamily,
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  FamilyListState copyWith({
    List<family_models.Family>? families,
    family_models.Family? currentFamily,
    List<family_models.FamilyMember>? members,
    bool? isLoading,
    String? error,
  }) {
    return FamilyListState(
      families: families ?? this.families,
      currentFamily: currentFamily ?? this.currentFamily,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 家庭列表状态管理
class FamilyListNotifier extends StateNotifier<FamilyListState> {
  final FamilyRepository _repository;

  FamilyListNotifier(this._repository) : super(const FamilyListState()) {
    loadFamilies();
  }

  /// 加载家庭列表
  Future<void> loadFamilies() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final families = await _repository.getFamilies();
      state = state.copyWith(
        families: families,
        isLoading: false,
      );
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
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
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
  Future<void> refresh() async {
    await loadFamilies();
    if (state.currentFamily != null) {
      await loadMembers(state.currentFamily!.id);
    }
  }
}

/// 家庭列表 Provider
final familyListProvider = StateNotifierProvider<FamilyListNotifier, FamilyListState>((ref) {
  return FamilyListNotifier(FamilyRepository());
});

