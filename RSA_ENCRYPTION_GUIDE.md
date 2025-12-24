# RSA密码加密实现指南

## 📋 概述

为了保证密码传输的安全性，应用实现了RSA加密机制。在用户登录和注册时，密码会先使用服务器提供的RSA公钥加密，然后再发送到后端。

## 🔐 加密流程

### 登录流程
```
用户输入密码 
    ↓
获取RSA公钥 (GET /auth/rsa_public_key)
    ↓
使用公钥加密密码
    ↓
发送加密后的密码 (POST /auth/login)
    ↓
后端使用私钥解密验证
```

### 注册流程
```
用户输入密码
    ↓
获取RSA公钥 (GET /auth/rsa_public_key)
    ↓
使用公钥加密密码
    ↓
发送加密后的密码 (POST /auth/register)
    ↓
后端使用私钥解密并保存
```

## 🛠️ 技术实现

### 1. 依赖包

已添加到 `pubspec.yaml`：

```yaml
dependencies:
  # 加密
  encrypt: ^5.0.3
  pointycastle: ^3.9.1
```

### 2. RSA加密工具类

位置：`lib/core/utils/rsa_helper.dart`

提供的方法：
- `encryptWithPublicKey(String data, String publicKeyPem)` - 使用公钥加密数据
- `isValidPublicKey(String publicKeyPem)` - 验证公钥是否有效
- `formatPublicKey(String publicKey)` - 格式化公钥为标准PEM格式

### 3. AuthRepository

位置：`lib/data/repositories/auth_repository.dart`

新增方法：
```dart
Future<String> getRsaPublicKey() async {
  final response = await _dio.get(ApiConstants.rsaPublicKey);
  return response.data['public_key'] as String;
}
```

### 4. AuthProvider更新

位置：`lib/providers/auth_provider.dart`

**登录方法**：
```dart
Future<void> login(String phone, String password) async {
  // 1. 获取RSA公钥
  final publicKey = await _authRepository.getRsaPublicKey();
  
  // 2. 使用公钥加密密码
  final encryptedPassword = RsaHelper.encryptWithPublicKey(password, publicKey);
  
  // 3. 调用登录接口（使用加密后的密码）
  final loginResponse = await _authRepository.login(
    phone: phone,
    password: encryptedPassword,
  );
  
  // 4. 保存Token和用户信息
  ...
}
```

**注册方法**：
```dart
Future<void> register(...) async {
  // 1. 获取RSA公钥
  final publicKey = await _authRepository.getRsaPublicKey();
  
  // 2. 使用公钥加密密码
  final encryptedPassword = RsaHelper.encryptWithPublicKey(password, publicKey);
  
  // 3. 调用注册接口（使用加密后的密码）
  final loginResponse = await _authRepository.register(
    password: encryptedPassword,
    ...
  );
  
  // 4. 保存Token和用户信息
  ...
}
```

## 📡 API交互

### 获取公钥接口

**请求**：
```http
GET /api/v1/app/auth/rsa_public_key
```

**响应**：
```json
{
  "public_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----"
}
```

### 登录接口

**请求**：
```http
POST /api/v1/app/auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "Base64加密后的密码字符串"
}
```

**响应**：
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "role": "user",
  "account": { ... }
}
```

### 注册接口

**请求**：
```http
POST /api/v1/app/auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "Base64加密后的密码字符串",
  "nickname": "用户昵称",
  "gender": "male"
}
```

**响应**（与登录接口相同）：
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "role": "user",
  "account": { ... }
}
```

## 🔍 加密细节

### 公钥格式

后端返回的公钥应为PEM格式：

```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----
```

### 加密算法

- **算法**：RSA
- **填充模式**：PKCS1
- **输出格式**：Base64

### 加密过程

1. 接收PEM格式的公钥字符串
2. 清理公钥（移除头尾标记和换行符）
3. 解析公钥为RSAPublicKey对象
4. 使用RSA算法加密明文密码
5. 返回Base64编码的加密结果

## 🧪 测试示例

```dart
void testRsaEncryption() {
  const publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----
''';

  const password = '123456';
  
  try {
    // 加密密码
    final encrypted = RsaHelper.encryptWithPublicKey(password, publicKeyPem);
    print('加密后的密码: $encrypted');
    
    // 验证公钥
    final isValid = RsaHelper.isValidPublicKey(publicKeyPem);
    print('公钥是否有效: $isValid');
  } catch (e) {
    print('加密失败: $e');
  }
}
```

## ⚠️ 注意事项

### 1. 公钥缓存
建议考虑缓存公钥以提高性能：
- 公钥通常不会频繁变更
- 可以缓存一段时间（如1小时）
- 如果加密失败，重新获取公钥

### 2. 错误处理
- 网络异常：无法获取公钥时给出友好提示
- 加密失败：公钥格式错误或数据异常
- 后端验证失败：密码错误或解密失败

### 3. 安全性
- ✅ 密码在客户端加密，传输过程中是密文
- ✅ 使用HTTPS可进一步保护传输安全
- ✅ 后端使用私钥解密，私钥不泄露
- ⚠️ 客户端代码可以被反编译，RSA主要防止网络窃听

### 4. 性能考虑
- RSA加密相对较慢
- 只加密密码这种小数据量
- 每次登录/注册需要先获取公钥（增加一次网络请求）

## 🚀 后续优化建议

### 1. 公钥缓存机制
```dart
class RsaKeyCache {
  static String? _cachedPublicKey;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 1);
  
  static Future<String> getPublicKey(AuthRepository repo) async {
    if (_cachedPublicKey != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedPublicKey!;
    }
    
    _cachedPublicKey = await repo.getRsaPublicKey();
    _cacheTime = DateTime.now();
    return _cachedPublicKey!;
  }
}
```

### 2. 重试机制
```dart
Future<String> getPublicKeyWithRetry({int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await _authRepository.getRsaPublicKey();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: i + 1));
    }
  }
  throw Exception('Failed to get public key');
}
```

### 3. 公钥预加载
在应用启动时预先获取公钥：
```dart
class App extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    // 预加载公钥
    ref.read(authProvider.notifier).preloadPublicKey();
  }
}
```

## 📚 相关资源

- [encrypt包文档](https://pub.dev/packages/encrypt)
- [pointycastle包文档](https://pub.dev/packages/pointycastle)
- [RSA加密算法](https://zh.wikipedia.org/wiki/RSA加密演算法)
- [PEM格式说明](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail)

## ✅ 完成清单

- [x] 添加加密依赖包
- [x] 创建RSA加密工具类
- [x] 实现公钥获取接口
- [x] 更新登录流程添加加密
- [x] 更新注册流程添加加密
- [x] 错误处理优化
- [ ] 添加公钥缓存机制（可选优化）
- [ ] 添加重试机制（可选优化）
- [ ] 添加公钥预加载（可选优化）

