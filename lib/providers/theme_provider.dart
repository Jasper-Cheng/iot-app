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
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.setString(StorageService.keyThemeMode, mode.toString());
  }

  /// 切换到亮色主题
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  /// 切换到暗色主题
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// 切换到系统主题
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }

  /// 切换主题（亮色 <-> 暗色）
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }
}

/// 主题模式 Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(StorageService());
});

