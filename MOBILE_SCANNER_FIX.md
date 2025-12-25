# Mobile Scanner 插件错误修复指南

## 错误信息
```
MissingPluginException(No implementation found for method state on channel dev.steenbakker.mobile_scanner/scanner/method)
```

## 原因
这个错误通常发生在添加新的原生插件后，原生代码没有正确注册或应用没有完全重新构建。

## 解决方案

### 方法 1：完全重新构建应用（推荐）

1. **停止当前运行的应用**
   - 如果应用正在运行，先完全停止它

2. **清理构建缓存**
   ```bash
   flutter clean
   ```

3. **重新获取依赖**
   ```bash
   flutter pub get
   ```

4. **重新构建并运行应用**
   ```bash
   flutter run
   ```
   或者如果使用 Android Studio/VS Code，完全停止应用后重新运行。

### 方法 2：如果是热重载导致的问题

- **不要使用热重载（Hot Reload）**
- **使用完全重启（Hot Restart）** 或 **完全重新运行应用**

### 方法 3：检查 Android 配置

确保 `android/app/src/main/AndroidManifest.xml` 中包含相机权限：

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

### 方法 4：如果问题仍然存在

1. **删除构建文件夹**
   ```bash
   rm -rf build/
   rm -rf android/app/build/
   ```

2. **重新构建**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 注意事项

- **首次添加原生插件后，必须完全重新构建应用，不能使用热重载**
- 如果是在模拟器上运行，确保模拟器支持相机功能
- 如果是在真机上运行，确保应用有相机权限

## 验证

重新构建后，点击"扫一扫"按钮应该能正常打开相机扫描页面，不再出现 `MissingPluginException` 错误。

