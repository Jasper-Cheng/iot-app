import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 本地存储服务
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  final _secureStorage = const FlutterSecureStorage();

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== 普通存储 ==========

  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// 获取字符串
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// 保存整数
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  /// 获取整数
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// 保存布尔值
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// 获取布尔值
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// 保存双精度浮点数
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  /// 获取双精度浮点数
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  /// 保存字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  /// 获取字符串列表
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  /// 删除指定键
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// 清空所有数据
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// 检查键是否存在
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // ========== 安全存储 (用于敏感信息) ==========

  /// 安全保存
  Future<void> setSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// 安全读取
  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// 安全删除
  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// 清空安全存储
  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  // ========== 常用键常量 ==========
  static const String keyToken = 'access_token';
  static const String keyTokenType = 'token_type';
  static const String keyUserId = 'user_id';
  static const String keyUserInfo = 'user_info';
  static const String keyThemeMode = 'theme_mode';
  static const String keyRememberPassword = 'remember_password';
  static const String keyRememberPhone = 'remember_phone';
  static const String keyRememberPasswordTime = 'remember_password_time';
  static const String keyCurrentFamilyId = 'current_family_id';
}

