# 快速开始指南

本指南将帮助你快速运行 IoT Flutter App 项目。

## 前置要求

### 1. 安装 Flutter SDK

访问 [Flutter 官网](https://flutter.dev/docs/get-started/install) 下载并安装 Flutter SDK。

**验证安装**:
```bash
flutter doctor
```

确保所有必要的组件都已正确安装。

### 2. 开发工具

推荐使用以下任一 IDE:
- **Android Studio** (推荐)
- **VS Code** + Flutter 插件
- **IntelliJ IDEA**

### 3. 设备/模拟器

**Android**:
- Android Studio 自带的 Android Emulator
- 或连接真实的 Android 设备

**iOS** (仅 macOS):
- Xcode 自带的 iOS Simulator
- 或连接真实的 iOS 设备

---

## 快速启动

### 1. 克隆/打开项目

```bash
cd iot_app
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 检查设备

```bash
flutter devices
```

确保至少有一个设备可用。

### 4. 运行应用

**在 Android 上运行**:
```bash
flutter run
```

**在 iOS 上运行** (仅 macOS):
```bash
flutter run -d ios
```

**在 Chrome 上运行** (用于快速测试):
```bash
flutter run -d chrome
```

---

## 登录测试

应用启动后，使用以下测试账号登录:

```
手机号: 13800138000
密码: 123456
```

> 注意: 当前使用 Mock 数据，任何手机号和密码组合都可以登录成功。

---

## 功能测试

### 1. 主题切换
- 点击首页右上角的主题图标
- 可以在亮色/暗色主题之间切换
- 主题设置会自动保存

### 2. 查看设备列表
- 登录后自动显示设备列表
- 下拉可以刷新列表
- 点击设备卡片查看详情（待实现）

### 3. 添加设备
- 点击右下角的"添加设备"按钮
- 输入设备序列号，例如: `AC001-250101-000001`
- 可选输入设备名称
- 点击"绑定"完成添加

### 4. 设备操作
- 点击设备卡片上的"编辑"按钮修改名称（待实现）
- 点击"解绑"按钮移除设备（待实现）

### 5. 切换页面
- 使用底部导航栏切换不同页面
- 首页: 设备列表
- 家庭: 家庭管理（占位）
- 设置: 应用设置

### 6. 退出登录
- 进入"设置"页面
- 滚动到底部
- 点击"退出登录"

---

## 开发模式

### 热重载

在应用运行时，修改代码后:
- 按 `r` 进行热重载 (Hot Reload)
- 按 `R` 进行热重启 (Hot Restart)
- 按 `q` 退出应用

### 调试模式

**启用调试模式**:
```bash
flutter run --debug
```

**查看日志**:
```bash
flutter logs
```

**性能分析**:
```bash
flutter run --profile
```

---

## 常见问题

### Q1: flutter pub get 失败

**解决方案**:
```bash
# 清理缓存
flutter clean

# 重新获取依赖
flutter pub get
```

### Q2: 找不到设备

**解决方案**:
- 确保 Android 设备已开启 USB 调试
- 确保 iOS 设备已信任电脑
- 重启 adb: `adb kill-server && adb start-server`

### Q3: 编译错误

**解决方案**:
```bash
# 清理构建缓存
flutter clean

# 重新构建
flutter run
```

### Q4: iOS 构建失败 (macOS)

**解决方案**:
```bash
cd ios
pod install
cd ..
flutter run
```

### Q5: 应用启动白屏

**解决方案**:
- 检查是否有编译错误
- 查看控制台日志
- 尝试热重启 (按 `R`)

---

## 项目结构说明

```
iot_app/
├── lib/                    # 源代码目录
│   ├── main.dart          # 应用入口
│   ├── app/               # 应用配置
│   ├── core/              # 核心功能
│   ├── data/              # 数据层
│   ├── providers/         # 状态管理
│   ├── features/          # 功能模块
│   └── shared/            # 共享组件
├── test/                  # 测试文件
├── android/               # Android 配置
├── ios/                   # iOS 配置
├── pubspec.yaml           # 依赖配置
└── README.md              # 项目说明
```

---

## 下一步

1. 查看 [README.md](README.md) 了解项目详情
2. 查看 [PROGRESS.md](PROGRESS.md) 了解开发进度
3. 阅读源代码，了解项目架构
4. 开始开发新功能

---

## 获取帮助

如果遇到问题:
1. 查看 Flutter 官方文档
2. 搜索 Stack Overflow
3. 提交 GitHub Issue
4. 查看项目 Wiki

---

## 有用的命令

```bash
# 检查 Flutter 环境
flutter doctor -v

# 列出所有设备
flutter devices

# 分析代码
flutter analyze

# 运行测试
flutter test

# 构建 APK (Android)
flutter build apk

# 构建 IPA (iOS, 仅 macOS)
flutter build ios

# 查看依赖树
flutter pub deps

# 更新依赖
flutter pub upgrade

# 清理项目
flutter clean
```

---

*祝你开发愉快! 🚀*

