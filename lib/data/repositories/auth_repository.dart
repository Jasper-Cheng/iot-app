import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/rsa_helper.dart';
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

  /// 更新用户信息
  /// 支持部分更新，只更新请求中提供的字段
  /// 密码需要使用RSA加密（先调用 getRsaPublicKey 获取公钥）
  Future<Account> updateProfile({
    String? nickname,
    String? phone,
    String? gender,
    String? email,
    String? avatar,
    String? password,
    int? currentFamilyId,
  }) async {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (phone != null) data['phone'] = phone;
    if (gender != null) data['gender'] = gender;
    if (email != null) data['email'] = email;
    if (avatar != null) data['avatar'] = avatar;
    if (currentFamilyId != null) data['current_family_id'] = currentFamilyId;
    
    if (password != null && password.isNotEmpty) {
      // 密码需要使用RSA加密（Base64编码）
      final publicKey = await getRsaPublicKey();
      data['password'] = RsaHelper.encryptWithPublicKey(password, publicKey);
    }

    // 使用 PATCH 方法进行部分更新
    final response = await _dio.patch(
      ApiConstants.updateProfile,
      data: data,
    );
    return Account.fromJson(response.data);
  }

  /// 获取当前家庭信息
  Future<Map<String, dynamic>> getCurrentFamily() async {
    final response = await _dio.get(ApiConstants.currentFamily);
    return response.data;
  }

  /// 更新当前家庭
  /// [familyId] 家庭ID，如果为 null 则切换到个人模式
  Future<void> updateCurrentFamily(int? familyId) async {
    final queryParameters = <String, dynamic>{};
    if (familyId != null) {
      queryParameters['family_id'] = familyId;
    }
    
    await _dio.patch(
      ApiConstants.currentFamily,
      queryParameters: queryParameters,
    );
  }

  /// 删除当前账户
  Future<void> deleteAccount() async {
    await _dio.delete(ApiConstants.deleteAccount);
  }
}

