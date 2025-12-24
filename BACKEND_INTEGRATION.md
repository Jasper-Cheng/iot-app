# 后端接口集成说明

## ✅ 已完成的集成工作

### 1. API配置更新
- ✅ 更新 `lib/core/constants/api_constants.dart`
- ✅ Base URL: `http://localhost:8000/api/v1/app`
- ✅ 所有接口路径与后端一致

### 2. Repository层更新
- ✅ 创建 `AuthRepository` 处理认证相关接口
- ✅ 所有 Repository 的 `useMock` 已设置为 `false`
- ✅ 连接实际后端API

### 3. 状态管理更新
- ✅ `AuthProvider` 集成 `AuthRepository`
- ✅ 登录接口直接调用后端
- ✅ 注册接口直接返回登录信息（与后端一致）

### 4. 错误处理优化
- ✅ 支持从响应中提取 `message` 字段
- ✅ 统一HTTP状态码处理
- ✅ 401错误自动清除Token

## 🔧 环境配置

### Android模拟器
由于Android模拟器的网络限制，`localhost` 无法直接访问主机。需要修改Base URL：

```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1/app';
```

### iOS模拟器
iOS模拟器可以直接使用 `localhost`：

```dart
static const String baseUrl = 'http://localhost:8000/api/v1/app';
```

### 真机测试
使用电脑的局域网IP地址：

1. 查看电脑IP（Windows: `ipconfig`, Mac/Linux: `ifconfig`）
2. 确保手机和电脑在同一WiFi网络
3. 更新Base URL：

```dart
static const String baseUrl = 'http://192.168.1.100:8000/api/v1/app';  // 替换为实际IP
```

### 生产环境
部署到生产环境后，使用正式域名：

```dart
static const String baseUrl = 'https://api.yourdomain.com/api/v1/app';
```

## 📡 接口列表

### 1. 认证接口
- `GET /api/v1/app/auth/rsa_public_key` - 获取RSA公钥
- `POST /api/v1/app/auth/register` - 用户注册
- `POST /api/v1/app/auth/login` - 用户登录
- `POST /api/v1/app/auth/logout` - 用户登出
- `GET /api/v1/app/auth/profile` - 获取用户信息
- `GET /api/v1/app/auth/current-family` - 获取当前家庭
- `DELETE /api/v1/app/auth/account` - 删除账户

### 2. 设备管理
- `GET /api/v1/app/devices/` - 获取设备列表
- `POST /api/v1/app/devices/bind-by-sn/` - 绑定设备
- `DELETE /api/v1/app/devices/unbind-by-sn/{sn}` - 解绑设备
- `PATCH /api/v1/app/devices/{id}/name` - 修改设备名称

### 3. 家庭管理
- `GET /api/v1/app/families/` - 获取家庭列表
- `POST /api/v1/app/families/` - 创建家庭
- `DELETE /api/v1/app/families/{id}` - 删除家庭
- `POST /api/v1/app/families/{family_id}/devices/{device_id}` - 添加设备到家庭
- `DELETE /api/v1/app/families/{family_id}/devices/{device_id}` - 移除设备

### 4. 家庭成员
- `GET /api/v1/app/family-members/family/{family_id}` - 获取成员列表
- `POST /api/v1/app/family-members/join-by-invite-code` - 加入家庭
- `PATCH /api/v1/app/family-members/{id}` - 更新成员信息
- `DELETE /api/v1/app/family-members/{id}` - 移除成员

### 5. 消息通知
- `GET /api/v1/app/device-messages/` - 获取设备消息
- `PATCH /api/v1/app/device-messages/{id}/make-read` - 标记已读
- `PATCH /api/v1/app/device-messages/mark-all-read` - 标记全部已读
- `GET /api/v1/app/device-messages/unread-count` - 未读消息数
- `GET /api/v1/app/system-messages/` - 获取系统消息

### 6. 签到积分
- `POST /api/v1/app/check-in/` - 签到
- `GET /api/v1/app/check-in/calendar` - 签到日历
- `GET /api/v1/app/check-in/stats` - 签到统计
- `GET /api/v1/app/check-in/history` - 签到历史
- `GET /api/v1/app/points/balance` - 积分余额
- `GET /api/v1/app/points/history` - 积分历史

### 7. 其他
- `POST /api/v1/app/feedback/` - 提交反馈
- `GET /api/v1/app/version-info/` - 获取版本信息（无需认证）

## 🔐 认证机制

### Token认证
所有需要认证的接口（除了注册、登录和版本信息）都需要在请求头中携带Token：

```http
Authorization: Bearer {access_token}
```

应用已自动配置拦截器，会自动添加Token到请求头。

### RSA密码加密 ⭐
登录和注册时，密码会先使用RSA公钥加密再发送：

1. **获取公钥**：调用 `GET /auth/rsa_public_key` 获取RSA公钥
2. **加密密码**：使用公钥加密用户输入的明文密码
3. **发送请求**：将加密后的Base64字符串发送给后端
4. **后端解密**：后端使用私钥解密并验证

详细说明请参考 [RSA_ENCRYPTION_GUIDE.md](./RSA_ENCRYPTION_GUIDE.md)

### 注册即登录
后端的注册接口成功后会直接返回Token和用户信息，无需再次调用登录接口。

## 📊 响应格式

### 成功响应
直接返回数据对象或数组：

```json
{
  "id": 1,
  "name": "设备名称",
  ...
}
```

或

```json
[
  { "id": 1, "name": "设备1" },
  { "id": 2, "name": "设备2" }
]
```

### 错误响应
返回包含message字段的对象：

```json
{
  "message": "错误信息描述"
}
```

应用已自动处理错误响应，会提取并显示 `message` 字段的内容。

## 🧪 测试步骤

### 1. 启动后端服务
确保后端服务运行在 `http://localhost:8000`

### 2. 配置Base URL
根据测试环境修改 `lib/core/constants/api_constants.dart` 中的 `baseUrl`

### 3. 运行应用

```bash
# Android模拟器
flutter run

# iOS模拟器
flutter run -d ios

# 真机
flutter run -d <device-id>
```

### 4. 测试功能
1. **注册** - 创建新账户
2. **登录** - 使用账户登录
3. **设备管理** - 绑定/解绑设备
4. **家庭管理** - 创建家庭、添加成员
5. **消息通知** - 查看设备和系统消息
6. **签到积分** - 每日签到、查看积分

## 🐛 常见问题

### 1. 网络连接失败
- **Android模拟器**: 确保使用 `10.0.2.2` 替代 `localhost`
- **真机**: 确保手机和电脑在同一WiFi，使用局域网IP
- **防火墙**: 检查防火墙是否阻止了8000端口

### 2. 401未授权错误
- Token可能已过期，尝试重新登录
- 检查后端JWT配置

### 3. 请求超时
- 检查后端服务是否正常运行
- 增加超时时间（在 `api_constants.dart` 中修改）

### 4. 数据格式错误
- 检查后端返回的数据格式是否与模型定义一致
- 查看控制台日志获取详细错误信息

## 📝 切换Mock/真实数据

如需临时切换回Mock数据进行开发：

1. 打开对应的Repository文件
2. 将 `useMock` 改为 `true`
3. 重新运行应用

```dart
class DeviceRepository {
  final bool useMock = true; // 改为 true 使用Mock数据
  ...
}
```

## 🚀 部署建议

### 环境变量配置
建议使用环境变量或配置文件管理不同环境的API地址：

```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static String get baseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.yourdomain.com/api/v1/app';
      case 'staging':
        return 'https://staging-api.yourdomain.com/api/v1/app';
      default:
        return 'http://localhost:8000/api/v1/app';
    }
  }
}
```

运行时指定环境：

```bash
# 开发环境
flutter run --dart-define=ENVIRONMENT=development

# 生产环境
flutter run --dart-define=ENVIRONMENT=production
```

## ✨ 下一步

1. 测试所有接口功能
2. 完善错误处理和用户提示
3. 添加请求日志记录
4. 实现请求重试机制
5. 配置HTTPS证书（生产环境）

