import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/family.dart' as family_models;
import '../data/repositories/family_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart';
import 'device_provider.dart';
import 'message_provider.dart';
import 'mqtt_provider.dart';
import '../core/constants/api_constants.dart';

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
  final Ref? _ref; // 用于访问其他 provider

  FamilyListNotifier(
    this._familyRepository, {
    int? currentUserId,
    int? currentFamilyId,
    Ref? ref,
  })  : _currentUserId = currentUserId,
        _currentFamilyId = currentFamilyId,
        _ref = ref,
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
          // 当前家庭不在列表中，自动切回个人设备管理
          print('[FamilyProvider] 当前家庭 $_currentFamilyId 不在家庭列表中，自动切回个人设备管理');
          await _switchToPersonalMode();
        }
      } else {
        // 如果没有当前家庭ID，确保清除当前家庭状态
        state = state.copyWith(
          currentFamily: null,
          members: [],
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }





  /// 创建家庭
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> createFamily({
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
        error: null, // 清除之前的错误
      );
      return (success: true, message: '家庭创建成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 删除家庭
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> deleteFamily(int id) async {
    try {
      await _familyRepository.deleteFamily(id);
      state = state.copyWith(
        families: state.families.where((f) => f.id != id).toList(),
        error: null, // 清除之前的错误
      );
      // 如果删除的是当前家庭，清除当前家庭数据
      if (state.currentFamily?.id == id) {
        state = state.copyWith(
          currentFamily: null,
          members: [],
        );
      }
      return (success: true, message: '已删除家庭');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 加入家庭
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> joinFamily(String inviteCode, {String? nickname}) async {
    try {
      // 调用API加入家庭，返回family_id
      await _familyRepository.joinFamily(inviteCode, nickname: nickname);
      // 重新加载家庭列表，获取最新的家庭信息（包括新加入的家庭）
      await loadFamilies();
      return (success: true, message: '加入家庭成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
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
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        error: errorMessage,
      );
      
      // 如果是"无权访问此家庭"的错误，说明用户已经不在该家庭中，需要切回个人设备管理
      if (errorMessage.contains('无权访问') || errorMessage.contains('无权访问此家庭')) {
        print('[FamilyProvider] 检测到无权访问家庭，自动切回个人设备管理');
        if (familyId == _currentFamilyId) {
          // 只有在加载当前家庭成员时遇到此错误才切换
          await _switchToPersonalMode();
        }
      }
    }
  }

  /// 获取家庭成员（不更新状态，用于展开显示）
  Future<List<family_models.FamilyMember>> getFamilyMembers(int familyId) async {
    return await _familyRepository.getFamilyMembers(familyId);
  }

  /// 更新成员昵称
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> updateMemberNickname(int memberId, String nickname) async {
    try {
      final updatedMember = await _familyRepository.updateMemberNickname(
        memberId,
        nickname,
      );
      final members = state.members.map((m) {
        return m.id == memberId ? updatedMember : m;
      }).toList();
      state = state.copyWith(
        members: members,
        error: null, // 清除之前的错误
      );
      return (success: true, message: '昵称更新成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 移除成员
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> removeMember(int memberId) async {
    try {
      await _familyRepository.removeMember(memberId);
      state = state.copyWith(
        members: state.members.where((m) => m.id != memberId).toList(),
        error: null, // 清除之前的错误
      );
      return (success: true, message: '成员已移除');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 添加设备到家庭
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> addDeviceToFamily(int familyId, int deviceId) async {
    try {
      await _familyRepository.addDeviceToFamily(familyId, deviceId);
      state = state.copyWith(error: null); // 清除之前的错误
      return (success: true, message: '设备已添加到家庭');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 从家庭移除设备
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> removeDeviceFromFamily(int familyId, int deviceId) async {
    try {
      await _familyRepository.removeDeviceFromFamily(familyId, deviceId);
      state = state.copyWith(error: null); // 清除之前的错误
      return (success: true, message: '设备已从家庭中移除');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage);
    }
  }

  /// 刷新
  Future<void> refresh() async {
    // loadFamilies() 已经会加载当前家庭数据（如果有 currentFamilyId）
    // 所以这里只需要调用 loadFamilies() 即可，避免重复加载
    await loadFamilies();
  }

  /// 切换到个人设备管理
  Future<void> _switchToPersonalMode() async {
    // 如果没有 ref，无法切换，只清除状态
    if (_ref == null) {
      if (mounted) {
        state = state.copyWith(
          currentFamily: null,
          members: [],
        );
      }
      return;
    }

    try {
      final previousFamilyId = _currentFamilyId;
      
      // 1. 先清除当前家庭状态（在 refreshProfile 之前）
      if (mounted) {
        state = state.copyWith(
          currentFamily: null,
          members: [],
        );
      }
      
      // 2. 调用接口切换到个人模式
      final authRepository = AuthRepository();
      await authRepository.updateCurrentFamily(null);

      // 3. 刷新用户信息（更新 authProvider 中的 currentFamilyId 为 null）
      // 注意：这会导致 familyListProvider 重建，所以之后不能再访问 state
      await _ref!.read(authProvider.notifier).refreshProfile();

      // 4. 刷新设备列表（在新的 provider 实例中）
      final deviceNotifier = _ref!.read(deviceListProvider.notifier);
      await deviceNotifier.refresh();

      // 5. 刷新消息列表
      final messageNotifier = _ref!.read(messageProvider.notifier);
      await messageNotifier.refresh();

      // 6. 取消订阅之前的家庭通知（如果存在）
      if (previousFamilyId != null) {
        final mqttNotifier = _ref!.read(mqttProvider.notifier);
        final mqttState = _ref!.read(mqttProvider);
        if (mqttState.isConnected) {
          final topic = ApiConstants.mqttHomeNotice(previousFamilyId);
          mqttNotifier.unsubscribe(topic);
        }
      }

      print('[FamilyProvider] 已自动切回个人设备管理');
    } catch (e) {
      print('[FamilyProvider] 切换到个人模式失败: $e');
      // 即使失败，也清除当前家庭状态（如果还 mounted）
      if (mounted) {
        state = state.copyWith(
          currentFamily: null,
          members: [],
        );
      }
    }
  }
}

/// 家庭列表 Provider
final familyListProvider = StateNotifierProvider<FamilyListNotifier, FamilyListState>((ref) {
  // 只监听 userId 和 currentFamilyId 的变化，忽略其他字段（如昵称、头像等）的变化
  // 这样修改用户信息时不会导致 familyListProvider 重新创建，但切换家庭时会自动重建
  final currentUserId = ref.watch(authProvider.select((state) => state.account?.id));
  final currentFamilyId = ref.watch(authProvider.select((state) => state.account?.currentFamilyId));
  
  return FamilyListNotifier(
    FamilyRepository(),
    currentUserId: currentUserId,
    currentFamilyId: currentFamilyId,
    ref: ref, // 传递 ref 以便访问其他 provider
  );
});

