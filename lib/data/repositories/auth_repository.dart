import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user.dart';

/// 认证数据仓库
class AuthRepository {
  final _dio = DioClient().dio;

  /// 获取RSA公钥
  Future<String> getRsaPublicKey() async {
    final response = await _dio.get(ApiConstants.rsaPublicKey);
    return response.data['public_key'] as String;
  }

  /// 用户注册（注册成功后自动登录，返回Token和用户信息）
  Future<LoginResponse> register({
    required String phone,
    required String password,
    required String nickname,
    String? gender,
    String? email,
    String? avatar,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'phone': phone,
        'password': password,
        'nickname': nickname,
        if (gender != null) 'gender': gender,
        if (email != null) 'email': email,
        if (avatar != null) 'avatar': avatar,
      },
    );
    return LoginResponse.fromJson(response.data);
  }

  /// 用户登录
  Future<LoginResponse> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'phone': phone,
        'password': password,
      },
    );
    return LoginResponse.fromJson(response.data);
  }

  /// 微信登录
  /// [code] 微信授权码
  Future<LoginResponse> wechatLogin(String code) async {
    final response = await _dio.post(
      ApiConstants.wechatLogin,
      data: {
        'code': code,
      },
    );
    return LoginResponse.fromJson(response.data);
  }

  /// 用户登出
  Future<void> logout() async {
    await _dio.post(ApiConstants.logout);
  }

  /// 获取当前用户信息
  Future<Account> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    return Account.fromJson(response.data);
  }

  /// 获取当前家庭信息
  Future<Map<String, dynamic>> getCurrentFamily() async {
    final response = await _dio.get(ApiConstants.currentFamily);
    return response.data;
  }

  /// 删除当前账户
  Future<void> deleteAccount() async {
    await _dio.delete(ApiConstants.deleteAccount);
  }
}

