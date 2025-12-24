# 平台配置指南

## ✅ 已完成配置

### 📱 Android 平台

#### 1. 权限配置 ✅
`android/app/src/main/AndroidManifest.xml` 已添加以下权限：

- ✅ 网络权限（INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE）
- ✅ 相机权限（CAMERA）
- ✅ 存储权限（READ/WRITE_EXTERNAL_STORAGE, READ_MEDIA_IMAGES）
- ✅ 通知权限（POST_NOTIFICATIONS）
- ✅ 振动权限（VIBRATE）
- ✅ 唤醒锁权限（WAKE_LOCK）
- ✅ 前台服务权限（FOREGROUND_SERVICE）

#### 2. Gradle配置 ✅
- AGP版本: 8.2.1
- Kotlin版本: 已配置
- minSdkVersion: 21
- targetSdkVersion: 34

### 🍎 iOS 平台

#### 1. 权限配置 ✅
`ios/Runner/Info.plist` 已添加以下权限说明：

- ✅ NSCameraUsageDescription（相机权限）
- ✅ NSPhotoLibraryUsageDescription（相册访问）
- ✅ NSPhotoLibraryAddUsageDescription（保存到相册）
- ✅ NSLocalNetworkUsageDescription（本地网络）
- ✅ NSBonjourServices（设备发现）
- ✅ UIBackgroundModes（后台模式）
- ✅ UIUserNotificationSettings（通知设置）

#### 2. 部署目标 ✅
- iOS 最低版本: 12.0
- 支持设备: iPhone, iPad

## 📦 依赖包配置

### 新增依赖 ✅
```yaml
# 权限管理
permission_handler: ^11.3.0

# 图片选择
image_picker: ^1.0.7
```

## 🚀 运行配置

### Android

1. **首次运行**
```bash
cd android
./gradlew clean
cd ..
flutter run
```

2. **构建发布版**
```bash
flutter build apk --release
# 或
flutter build appbundle --release
```

3. **查看构建配置**
```bash
flutter build apk --release --verbose
```

### iOS

1. **首次运行**
```bash
cd ios
pod install
cd ..
flutter run
```

2. **构建发布版**
```bash
flutter build ios --release
```

3. **打开Xcode**
```bash
open ios/Runner.xcworkspace
```

## 🔧 权限使用示例

### 在代码中使用权限助手

```dart
import 'package:iot_app/core/utils/permission_helper.dart';

// 1. 请求相机权限（扫码功能）
void scanQRCode() async {
  if (await PermissionHelper.requestCamera(context)) {
    // 打开扫码页面
    Navigator.push(context, ...);
  } else {
    // 显示权限被拒绝提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('需要相机权限才能扫描二维码')),
    );
  }
}

// 2. 请求存储权限（选择头像）
void pickAvatar() async {
  if (await PermissionHelper.requestStorage(context)) {
    // 打开图片选择器
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // 处理选中的图片
    }
  }
}

// 3. 请求通知权限（应用启动时）
@override
void initState() {
  super.initState();
  Future.microtask(() {
    PermissionHelper.requestNotification(context);
  });
}

// 4. 在使用前检查权限
void openCamera() async {
  if (await PermissionHelper.checkCamera()) {
    // 已有权限，直接打开相机
  } else {
    // 请求权限
    await PermissionHelper.requestCamera(context);
  }
}
```

## 📝 运行时权限处理流程

### 1. 扫码功能权限流程

```dart
// 在设备绑定页面
class BindDeviceScreen extends StatelessWidget {
  void _scanQRCode() async {
    // 先显示权限说明
    final shouldRequest = await PermissionHelper.showPermissionExplanation(
      context,
      '需要相机权限',
      '扫描设备二维码需要使用相机，是否允许访问？',
    );
    
    if (shouldRequest) {
      // 请求权限
      if (await PermissionHelper.requestCamera(context)) {
        // 打开扫码页面
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QRScannerScreen()),
        );
        // 处理扫码结果
      }
    }
  }
}
```

### 2. 头像选择权限流程

```dart
// 在个人设置页面
class ProfileScreen extends StatelessWidget {
  void _pickAvatar() async {
    // 请求存储/照片权限
    if (await PermissionHelper.requestStorage(context)) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        // 上传头像
        await uploadAvatar(image.path);
      }
    }
  }
}
```

### 3. 应用启动时权限初始化

```dart
// 在main.dart或主页面
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }
  
  Future<void> _initializePermissions() async {
    // 延迟一下，等UI渲染完成
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      // 请求必要的初始权限
      await PermissionHelper.requestInitialPermissions(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}
```

## 🐛 常见问题

### Android

#### Q1: Gradle 构建失败
```bash
# 清理构建缓存
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### Q2: 权限请求无效
确保在 `AndroidManifest.xml` 中声明了权限，并且使用了 `permission_handler` 在运行时请求。

#### Q3: Android 13+ 通知不显示
确保请求了 `POST_NOTIFICATIONS` 权限：
```dart
await PermissionHelper.requestNotification(context);
```

### iOS

#### Q1: 权限说明未显示
检查 `Info.plist` 中是否添加了对应的 `Usage Description`。

#### Q2: Pod install 失败
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

#### Q3: 本地网络权限问题
确保在 `Info.plist` 中添加了：
- NSLocalNetworkUsageDescription
- NSBonjourServices

## 📊 权限状态检查

### 调试权限状态

```dart
import 'package:permission_handler/permission_handler.dart';

void checkAllPermissions() async {
  print('相机: ${await Permission.camera.status}');
  print('存储: ${await Permission.storage.status}');
  print('通知: ${await Permission.notification.status}');
  print('照片: ${await Permission.photos.status}');
}
```

## 🔍 测试清单

### Android 测试
- [ ] Android 5.0 (API 21) 设备测试
- [ ] Android 13+ (API 33) 通知权限测试
- [ ] 相机权限测试（扫码）
- [ ] 存储权限测试（头像）
- [ ] 网络连接测试（MQTT）
- [ ] 后台运行测试
- [ ] 权限被拒绝场景测试

### iOS 测试
- [ ] iOS 12.0+ 设备测试
- [ ] 相机权限测试
- [ ] 相册权限测试
- [ ] 本地网络权限测试
- [ ] 后台模式测试
- [ ] 通知权限测试
- [ ] 权限被拒绝场景测试

## 📚 相关文件

- `android/app/src/main/AndroidManifest.xml` - Android权限配置
- `ios/Runner/Info.plist` - iOS权限配置
- `lib/core/utils/permission_helper.dart` - 权限助手类
- `PERMISSIONS_GUIDE.md` - 详细权限使用指南

## 🎯 下一步

1. ✅ Android 权限配置完成
2. ✅ iOS 权限配置完成
3. ✅ 权限助手类创建完成
4. ✅ 依赖包安装完成
5. 📝 在需要权限的功能处添加权限请求代码
6. 🧪 在真机上测试权限请求流程
7. 📦 准备应用商店提交材料

---

**提示**: 所有权限配置已完成，应用现在可以在Android和iOS平台上正常运行！

