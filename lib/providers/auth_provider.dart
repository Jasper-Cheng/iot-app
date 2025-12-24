import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../core/storage/storage_service.dart';
import '../data/repositories/auth_repository.dart';
import 'dart:convert';

/// 认证状态
class AuthState {
  final bool isAuthenticated;
  final Account? account;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.account,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    Account? account,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      account: account ?? this.account,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 认证状态管理
class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService _storage;
  final AuthRepository _authRepository = AuthRepository();

  AuthNotifier(this._storage) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// 检查认证状态
  Future<void> _checkAuthStatus() async {
    final token = _storage.getString(StorageService.keyToken);
    final userInfoStr = _storage.getString(StorageService.keyUserInfo);

    if (token != null && userInfoStr != null) {
      try {
        final userInfo = jsonDecode(userInfoStr);
        final account = Account.fromJson(userInfo);
        state = state.copyWith(
          isAuthenticated: true,
          account: account,
          token: token,
        );
      } catch (e) {
        await logout();
      }
    }
  }

  /// 登录
  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 调用实际的登录接口
      final loginResponse = await _authRepository.login(
        phone: phone,
        password: password,
      );

      // 保存 Token 和用户信息
      await _storage.setString(StorageService.keyToken, loginResponse.accessToken);
      await _storage.setString(StorageService.keyTokenType, loginResponse.tokenType);
      await _storage.setString(
        StorageService.keyUserInfo,
        jsonEncode(loginResponse.account.toJson()),
      );

      state = state.copyWith(
        isAuthenticated: true,
        account: loginResponse.account,
        token: loginResponse.accessToken,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 注册
  Future<void> register({
    required String nickname,
    required String phone,
    required String password,
    String? gender,
    String? email,
    String? avatar,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 调用实际的注册接口（后端注册成功后会自动返回登录信息）
      final loginResponse = await _authRepository.register(
        phone: phone,
        password: password,
        nickname: nickname,
        gender: gender,
        email: email,
        avatar: avatar,
      );

      // 保存 Token 和用户信息
      await _storage.setString(StorageService.keyToken, loginResponse.accessToken);
      await _storage.setString(StorageService.keyTokenType, loginResponse.tokenType);
      await _storage.setString(
        StorageService.keyUserInfo,
        jsonEncode(loginResponse.account.toJson()),
      );

      state = state.copyWith(
        isAuthenticated: true,
        account: loginResponse.account,
        token: loginResponse.accessToken,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      // 调用后端登出接口
      await _authRepository.logout();
    } catch (e) {
      // 即使后端登出失败，也要清除本地数据
      print('Logout error: $e');
    } finally {
      // 清除本地存储
      await _storage.remove(StorageService.keyToken);
      await _storage.remove(StorageService.keyTokenType);
      await _storage.remove(StorageService.keyUserInfo);
      await _storage.remove(StorageService.keyCurrentFamilyId);

      state = const AuthState();
    }
  }

  /// 更新用户信息
  Future<void> updateProfile(Account account) async {
    await _storage.setString(
      StorageService.keyUserInfo,
      jsonEncode(account.toJson()),
    );

    state = state.copyWith(account: account);
  }
}

/// 认证 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(StorageService());
});

