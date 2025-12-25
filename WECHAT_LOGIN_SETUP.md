# 微信登录配置指南

## 概述

项目已集成微信登录功能的基础框架，但需要完成以下配置才能正常使用。

## 配置步骤

### 1. 注册微信开放平台账号

1. 前往 [微信开放平台](https://open.weixin.qq.com/) 注册开发者账号
2. 创建移动应用，获取 **AppID** 和 **AppSecret**
3. 配置应用信息（应用名称、描述、图标等）

### 2. 配置 Android

在 `android/app/build.gradle` 中添加：

```gradle
android {
    defaultConfig {
        // 添加微信AppID
        manifestPlaceholders = [
            WX_APP_ID: "YOUR_WECHAT_APP_ID"
        ]
    }
}
```

在 `android/app/src/main/AndroidManifest.xml` 中添加权限：

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### 3. 配置 iOS

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_WECHAT_APP_ID</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>weixinULAPI</string>
</array>
```

### 4. 启用代码

在 `lib/features/auth/screens/login_screen.dart` 中：

1. 取消注释 `import 'package:fluwx/fluwx.dart';`
2. 取消注释 `_initWechat();` 调用
3. 取消注释 `_initWechat()` 方法实现，并替换 `YOUR_WECHAT_APP_ID`
4. 取消注释 `_handleWechatLogin()` 方法中的实际实现代码
5. 删除临时提示代码

### 5. 后端接口

确保后端已实现微信登录接口：

- **接口路径**: `POST /api/v1/app/auth/login/wechat`
- **请求参数**: 
  ```json
  {
    "code": "微信授权码"
  }
  ```
- **响应格式**: 与普通登录接口相同，返回 `LoginResponse`

## 功能说明

### 已实现的功能

1. ✅ 微信登录按钮UI
2. ✅ 微信登录Provider方法
3. ✅ 微信登录Repository方法
4. ✅ 微信登录API接口定义
5. ✅ 登录成功自动跳转

### 待配置的功能

1. ⏳ 微信SDK初始化（需要AppID）
2. ⏳ 微信授权流程（需要AppID）
3. ⏳ Android/iOS原生配置（需要AppID）

## 测试

配置完成后，测试流程：

1. 确保设备已安装微信
2. 点击"微信登录"按钮
3. 跳转到微信授权页面
4. 用户同意授权后，返回应用
5. 自动调用后端接口完成登录
6. 登录成功后跳转到首页

## 注意事项

1. **AppSecret 安全**: AppSecret 必须存储在服务器端，不要在客户端代码中暴露
2. **回调域名**: 确保授权回调域名与微信开放平台配置一致
3. **测试环境**: 开发阶段可以使用测试号进行测试
4. **审核**: 正式发布前需要通过微信开放平台的审核

## 相关文件

- `lib/features/auth/screens/login_screen.dart` - 登录页面
- `lib/providers/auth_provider.dart` - 认证状态管理
- `lib/data/repositories/auth_repository.dart` - 数据仓库
- `lib/core/constants/api_constants.dart` - API常量

## 参考文档

- [微信开放平台文档](https://developers.weixin.qq.com/doc/)
- [fluwx 包文档](https://pub.dev/packages/fluwx)

