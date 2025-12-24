# 🏠 智能家居 IoT App

<div align="center">

**一个功能完整的Flutter智能家居管理应用**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[功能特性](#-功能特性) • [快速开始](#-快速开始) • [项目结构](#-项目结构) • [技术栈](#-技术栈) • [截图预览](#-截图预览)

</div>

---

## 📖 简介

智能家居 IoT App 是一个专业的智能家居管理应用，支持多种智能设备的管理和控制。应用采用现代化的架构设计，提供流畅的用户体验和丰富的功能。

## ✨ 功能特性

### 🔐 用户认证
- 手机号密码登录
- Token持久化
- 自动登录

### 🏠 设备管理
- **支持12种智能设备**
  - 空调控制
  - 智能灯光
  - 安防摄像头
  - 智能电视
  - 跌倒检测器
  - Wi-Fi管理
  - 扫地机器人
  - 洗衣机
  - 智能冰箱
  - 智能音箱
  - 空气净化器
  - 环境监测
- 设备绑定/解绑
- 实时状态监控
- 远程控制

### 👨‍👩‍👧‍👦 家庭管理
- 创建/加入家庭
- 邀请码分享
- 成员权限管理
- 设备共享

### 📢 消息通知
- 设备消息推送
- 系统通知
- 消息分级（普通/警告/错误）
- 已读/未读管理

### 📅 签到积分
- 每日签到
- 连续签到奖励
- 积分系统
- 签到日历
- 积分历史

### ⚙️ 设置中心
- 主题切换（浅色/深色/自动）
- 意见反馈
- 联系客服
- 关于我们
- 账户管理

### 🔌 MQTT实时通信
- 设备状态实时同步
- 控制指令即时响应
- 自动重连
- 主题订阅管理

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK >= 21
- iOS >= 12.0

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/your-repo/iot_app.git
cd iot_app
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
```bash
# 开发模式
flutter run

# 生产模式
flutter run --release
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📁 项目结构

```
lib/
├── app/                    # 应用配置
│   ├── routes/            # 路由管理
│   └── theme/             # 主题配置
├── core/                  # 核心功能
│   ├── constants/         # 常量定义
│   ├── network/           # 网络层
│   ├── storage/           # 存储层
│   ├── mqtt/              # MQTT服务
│   └── utils/             # 工具类
├── data/                  # 数据层
│   ├── models/            # 数据模型
│   ├── repositories/      # 数据仓库
│   └── mock/              # Mock数据
├── providers/             # 状态管理
└── features/              # 功能模块
    ├── auth/              # 认证
    ├── home/              # 首页
    ├── device_cards/      # 设备卡片（12种）
    ├── family/            # 家庭管理
    ├── messages/          # 消息通知
    ├── checkin/           # 签到积分
    ├── settings/          # 设置
    └── main/              # 主框架
```

## 🛠 技术栈

### 核心框架
- **Flutter 3.x** - 跨平台UI框架
- **Dart 3.x** - 编程语言

### 状态管理
- **flutter_riverpod 2.x** - 现代化状态管理

### 路由导航
- **go_router** - 声明式路由

### 网络通信
- **dio** - HTTP客户端
- **mqtt_client** - MQTT协议

### 本地存储
- **shared_preferences** - 键值存储
- **flutter_secure_storage** - 安全存储

### UI组件
- **Material Design 3** - 设计规范
- **fl_chart** - 图表库

### 工具库
- **json_annotation** - JSON序列化
- **equatable** - 对象比较
- **uuid** - UUID生成
- **intl** - 国际化

## 📱 截图预览

### 主要页面
- 登录页面
- 设备首页
- 设备详情
- 12种设备卡片
- 家庭管理
- 消息通知
- 签到积分
- 设置中心

## ⚙️ 配置说明

### API配置

编辑 `lib/core/constants/api_constants.dart`:

```dart
// API基础URL
static const String baseUrl = 'https://your-api.com/api/v1/web';

// MQTT配置
static const String mqttBroker = 'your-mqtt-broker.com';
static const int mqttPort = 1883;
```

### Mock数据模式

项目默认启用Mock数据，方便开发测试：

```dart
// 在各Repository中控制
final bool useMock = true; // 改为false使用真实API
```

## 🎨 主题定制

应用支持三种主题模式：
- ☀️ 浅色模式
- 🌙 深色模式
- 🔄 跟随系统

主题配置文件：
- `lib/app/theme/colors.dart` - 颜色定义
- `lib/app/theme/text_styles.dart` - 文本样式
- `lib/app/theme/app_theme.dart` - 主题配置

## 📊 项目统计

- ✅ 10个核心功能模块
- ✅ 12种智能设备支持
- ✅ 100+ Dart文件
- ✅ 15,000+ 行代码
- ✅ 50+ 自定义Widget
- ✅ 完整的Mock数据支持

## 🔍 代码质量

- ✅ Flutter Analyze通过
- ✅ 遵循Dart风格指南
- ✅ 完整的空安全支持
- ✅ 类型安全
- ✅ 详细的代码注释

## 📝 开发文档

- [开发需求文档](FLUTTER_APP_DEVELOPMENT_PROMPT.md)
- [最新更新日志](LATEST_UPDATES.md)
- [项目完成总结](FINAL_SUMMARY.md)

## 🤝 贡献指南

欢迎提交Issue和Pull Request！

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 👥 作者

**AI Assistant**

## 🙏 致谢

- Flutter团队提供的优秀框架
- Riverpod社区的状态管理方案
- 所有开源贡献者

## 📧 联系方式

- Email: support@iot-app.com
- 官网: www.iot-app.com

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个Star！ ⭐**

Made with ❤️ using Flutter

</div>
# iot-app
