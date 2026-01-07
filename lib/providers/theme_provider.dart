import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/storage_service.dart';

/// 主题模式状态
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// 加载主题模式
  Future<void> _loadThemeMode() async {
    final themeModeStr = _storage.getString(StorageService.keyThemeMode);
    if (themeModeStr != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeStr,
        orElse: () => ThemeMode.system,
      );
    }
  }

  /// 切换主题模式
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> setThemeMode(ThemeMode mode) async {
    try {
      state = mode;
      await _storage.setString(StorageService.keyThemeMode, mode.toString());
      String modeName;
      switch (mode) {
        case ThemeMode.light:
          modeName = '亮色';
          break;
        case ThemeMode.dark:
          modeName = '暗色';
          break;
        case ThemeMode.system:
          modeName = '跟随系统';
          break;
      }
      return (success: true, message: '已切换到$modeName主题');
    } catch (e) {
      return (success: false, message: '切换主题失败');
    }
  }

  /// 切换到亮色主题
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> setLightMode() async {
    return await setThemeMode(ThemeMode.light);
  }

  /// 切换到暗色主题
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> setDarkMode() async {
    return await setThemeMode(ThemeMode.dark);
  }

  /// 切换到系统主题
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> setSystemMode() async {
    return await setThemeMode(ThemeMode.system);
  }

  /// 切换主题（亮色 <-> 暗色）
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> toggleTheme() async {
    if (state == ThemeMode.light) {
      return await setDarkMode();
    } else {
      return await setLightMode();
    }
  }
}

/// 主题模式 Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(StorageService());
});

