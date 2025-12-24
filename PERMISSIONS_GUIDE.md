# 权限配置指南

## 📱 Android 权限

### 已配置权限

在 `android/app/src/main/AndroidManifest.xml` 中已添加以下权限：

#### 1. 网络权限 ✅
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
```
**用途**: 
- 网络请求（API调用）
- MQTT连接
- 检查网络状态

#### 2. 相机权限 ✅
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```
**用途**:
- 扫描设备二维码
- 扫描邀请码

#### 3. 存储权限 ✅
```xml
<!-- Android 12 及以下 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>

<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```
**用途**:
- 选择用户头像
- 保存图片
- 缓存数据

#### 4. 通知权限 ✅
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
**用途**:
- 设备消息推送
- 系统通知
- 签到提醒

#### 5. 振动权限 ✅
```xml
<uses-permission android:name="android.permission.VIBRATE"/>
```
**用途**:
- 通知振动
- 操作反馈

#### 6. 唤醒锁权限 ✅
```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```
**用途**:
- 保持MQTT连接
- 后台任务

#### 7. 前台服务权限 ✅
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```
**用途**:
- 后台保持MQTT连接
- 设备状态监控

## 🍎 iOS 权限

### 已配置权限

在 `ios/Runner/Info.plist` 中已添加以下权限：

#### 1. 相机权限 ✅
```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机以扫描设备二维码</string>
```
**用途**: 扫描二维码

#### 2. 相册权限 ✅
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择头像或保存图片</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存图片到相册</string>
```
**用途**: 
- 选择用户头像
- 保存图片

#### 3. 本地网络权限 ✅
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>需要访问本地网络以连接智能设备</string>
```
**用途**:
- 连接本地MQTT Broker
- 设备发现

#### 4. Bonjour服务 ✅
```xml
<key>NSBonjourServices</key>
<array>
    <string>_mqtt._tcp</string>
    <string>_iot._tcp</string>
</array>
```
**用途**:
- 设备自动发现
- MQTT服务发现

#### 5. 后台模式 ✅
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```
**用途**:
- 后台数据获取
- 推送通知

## 💻 运行时权限请求

某些权限需要在运行时请求用户授权：

### Android 示例

```dart
import 'package:permission_handler/permission_handler.dart';

// 请求相机权限
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}

// 请求存储权限
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    // Android 13+ 需要请求媒体权限
    if (await Permission.photos.request().isGranted) {
      return true;
    }
  }
  return false;
}

// 请求通知权限（Android 13+）
Future<bool> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  return true; // iOS 自动处理
}
```

### iOS 示例

```dart
// iOS权限会在首次使用时自动弹出授权框
// 确保Info.plist中的描述清晰友好

// 检查权限状态
Future<bool> checkCameraPermission() async {
  final status = await Permission.camera.status;
  if (status.isDenied) {
    final result = await Permission.camera.request();
    return result.isGranted;
  }
  return status.isGranted;
}
```

## 🔧 权限处理最佳实践

### 1. 在需要时请求

不要在应用启动时请求所有权限，而是在用户需要使用相关功能时请求：

```dart
// ❌ 不好的做法
void initState() {
  requestAllPermissions(); // 启动时请求所有权限
}

// ✅ 好的做法
void onScanQRCode() async {
  if (await requestCameraPermission()) {
    // 打开扫码页面
  } else {
    // 显示权限说明
  }
}
```

### 2. 提供权限说明

在请求权限前，解释为什么需要这个权限：

```dart
Future<bool> requestCameraWithExplanation(BuildContext context) async {
  // 显示说明对话框
  final shouldRequest = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('需要相机权限'),
      content: const Text('扫描设备二维码需要使用相机，是否允许？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('允许'),
        ),
      ],
    ),
  );

  if (shouldRequest == true) {
    return await requestCameraPermission();
  }
  return false;
}
```

### 3. 处理权限被拒绝

如果权限被永久拒绝，引导用户去设置页面：

```dart
Future<void> handlePermissionDenied(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('权限被拒绝'),
      content: const Text('请在设置中允许相机权限以使用扫码功能'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('去设置'),
        ),
      ],
    ),
  );

  if (result == true) {
    await openAppSettings(); // 打开应用设置页面
  }
}
```

## 📋 权限检查清单

### 开发阶段
- [ ] AndroidManifest.xml 已添加所有必要权限
- [ ] Info.plist 已添加所有权限描述
- [ ] 权限描述文案清晰友好
- [ ] 运行时权限请求逻辑已实现

### 测试阶段
- [ ] 测试首次请求权限流程
- [ ] 测试权限被拒绝的情况
- [ ] 测试权限被永久拒绝的情况
- [ ] 测试在不同Android版本上的权限行为
- [ ] 测试在iOS上的权限行为

### 发布前
- [ ] 检查是否有未使用的权限声明
- [ ] 确认权限描述符合应用商店要求
- [ ] 准备权限使用说明文档

## 🚨 注意事项

### Android

1. **Android 13+ 通知权限**: 需要在运行时请求
2. **存储权限变化**: Android 13+ 使用分区存储
3. **后台限制**: Android 12+ 对后台服务有更严格的限制
4. **精确定位**: 如果需要位置信息，需要额外权限

### iOS

1. **权限描述必填**: 所有权限都必须提供使用描述
2. **隐私清单**: iOS 17+ 需要提供隐私清单
3. **后台模式审核**: 后台模式需要合理的使用理由
4. **网络权限**: 本地网络访问需要特殊配置

## 📚 相关资源

- [Android 权限文档](https://developer.android.com/guide/topics/permissions/overview)
- [iOS 权限文档](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)
- [permission_handler 插件](https://pub.dev/packages/permission_handler)

## 🔄 更新记录

- **2025-01-01**: 初始配置，添加基础权限
- Android 权限: 11个
- iOS 权限: 8个
- 支持 Android 5.0+ 和 iOS 12.0+

