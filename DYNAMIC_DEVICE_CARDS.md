# 动态设备卡片加载功能

## ✅ 功能概述

系统现在支持根据设备的SN（序列号）**自动识别设备类型**并**动态加载对应的专属设备卡片**。

## 🎯 实现效果

### 之前 ❌
```dart
// 所有设备都使用相同的通用卡片
return DeviceCard(device: device);
```

### 现在 ✅
```dart
// 根据SN自动加载对应的专属卡片
return DeviceCardFactory.createCard(device);

// 示例：
// SN: AC001_250101_000001      → AirCoolerCard (空调卡片)
// SN: LIGHT001_250101_000002   → SmartLightCard (智能灯卡片)
// SN: CAM001_250101_000003     → CameraCard (摄像头卡片)
// ... 12种设备类型自动识别
```

## 📋 SN格式规则

### 标准格式
```
modecode_时间_序列号
   ↓      ↓     ↓
型号代码  日期  编号

示例：AC001_250101_000001
     ↓      ↓       ↓
    空调  2025.1.1  第1台
```

### 兼容格式
同时支持横线分隔符（兼容旧格式）：
```
modecode-时间-序列号
AC001-250101-000001
```

## 🔧 技术实现

### 1. SN解析工具 (`lib/core/utils/device_mapping.dart`)

```dart
// 支持两种分隔符：_ 和 -
static String getModelCodeBySN(String sn) {
  List<String> parts;
  if (sn.contains('_')) {
    parts = sn.split('_');
  } else if (sn.contains('-')) {
    parts = sn.split('-');
  }
  return parts.isNotEmpty ? parts[0] : '';
}

// 根据型号代码映射到卡片类型
static String getCardTypeBySN(String sn) {
  final modelCode = getModelCodeBySN(sn);
  return deviceTypeMapping[modelCode] ?? 'UnknownCard';
}
```

### 2. 设备卡片工厂 (`lib/features/home/widgets/device_card_factory.dart`)

```dart
class DeviceCardFactory {
  static Widget createCard(Device device) {
    final cardType = DeviceMapping.getCardTypeBySN(device.sn);
    
    switch (cardType) {
      case 'AirCoolerCard':
        return AirCoolerCard(device: device);
      case 'SmartLightCard':
        return SmartLightCard(device: device);
      // ... 12种设备类型
      default:
        return DeviceCard(device: device); // 通用卡片
    }
  }
}
```

### 3. 在首页中使用 (`lib/features/home/screens/home_screen.dart`)

```dart
ListView.builder(
  itemBuilder: (context, index) {
    final device = deviceState.devices[index];
    return DeviceCardFactory.createCard(device);
    // ↑ 自动根据device.sn创建对应的卡片
  },
)
```

## 🎨 支持的12种设备类型

| 序号 | 型号代码 | 设备类型 | 卡片组件 | 示例SN |
|-----|---------|---------|---------|--------|
| 1 | AC001-003 | 空调 | AirCoolerCard | AC001_250101_000001 |
| 2 | LIGHT001-003 | 智能灯 | SmartLightCard | LIGHT001_250101_000002 |
| 3 | CAM001-003 | 摄像头 | CameraCard | CAM001_250101_000003 |
| 4 | TV001-003 | 智能电视 | SmartTvCard | TV001_250101_000004 |
| 5 | FALL001-003 | 跌倒检测器 | FallDetectionCard | FALL001_250101_000005 |
| 6 | WIFI001-003 | 路由器 | WiFiCard | WIFI001_250101_000006 |
| 7 | ROBOT001-003 | 扫地机器人 | VacuumCard | ROBOT001_250101_000007 |
| 8 | WASH001-003 | 洗衣机 | WashingMachineCard | WASH001_250101_000008 |
| 9 | FRIDGE001-003 | 冰箱 | RefrigeratorCard | FRIDGE001_250101_000009 |
| 10 | SPEAKER001-003 | 音箱 | SpeakerCard | SPEAKER001_250101_000010 |
| 11 | AIR001-003 | 空气净化器 | AirPurifierCard | AIR001_250101_000011 |
| 12 | M701001 | 环境监测器 | EnvironmentMonitorCard | M701001_250101_000012 |

## 📊 Mock数据更新

更新了12个设备的Mock数据，每种设备类型都有一个示例：

```dart
static final mockDevices = [
  {'id': 1, 'sn': 'AC001_250101_000001', 'name': '客厅空调'},
  {'id': 2, 'sn': 'LIGHT001_250101_000002', 'name': '卧室灯'},
  {'id': 3, 'sn': 'CAM001_250101_000003', 'name': '门口摄像头'},
  {'id': 4, 'sn': 'TV001_250101_000004', 'name': '客厅电视'},
  {'id': 5, 'sn': 'FALL001_250101_000005', 'name': '卧室跌倒检测器'},
  {'id': 6, 'sn': 'WIFI001_250101_000006', 'name': '主卧路由器'},
  {'id': 7, 'sn': 'ROBOT001_250101_000007', 'name': '客厅扫地机器人'},
  {'id': 8, 'sn': 'WASH001_250101_000008', 'name': '洗衣房洗衣机'},
  {'id': 9, 'sn': 'FRIDGE001_250101_000009', 'name': '厨房冰箱'},
  {'id': 10, 'sn': 'SPEAKER001_250101_000010', 'name': '书房音箱'},
  {'id': 11, 'sn': 'AIR001_250101_000011', 'name': '客厅空气净化器'},
  {'id': 12, 'sn': 'M701001_250101_000012', 'name': '阳台环境监测器'},
];
```

## 🧪 测试验证

### 1. 测试SN解析

```dart
void testSNParsing() {
  // 测试下划线格式
  print(DeviceMapping.getModelCodeBySN('AC001_250101_000001'));
  // 输出: AC001
  
  // 测试横线格式（兼容）
  print(DeviceMapping.getModelCodeBySN('AC001-250101-000001'));
  // 输出: AC001
  
  // 测试卡片类型
  print(DeviceMapping.getCardTypeBySN('AC001_250101_000001'));
  // 输出: AirCoolerCard
}
```

### 2. 测试设备卡片创建

```dart
void testCardCreation() {
  Device device = Device(
    id: 1,
    name: '客厅空调',
    sn: 'AC001_250101_000001',
    status: 'online',
    modelId: 1,
    createdAt: DateTime.now(),
  );
  
  Widget card = DeviceCardFactory.createCard(device);
  // 返回: AirCoolerCard widget
  
  print('Card Type: ${card.runtimeType}');
  // 输出: AirCoolerCard
}
```

### 3. UI测试检查清单

- [ ] 进入首页，应该能看到12种不同的设备卡片
- [ ] 每个设备卡片的UI样式应该与设备类型匹配
- [ ] 空调卡片应该显示温度、模式等控制
- [ ] 智能灯卡片应该显示亮度、颜色控制
- [ ] 摄像头卡片应该显示视频预览
- [ ] 其他设备卡片各有特色UI
- [ ] 未知设备使用通用卡片

## 💡 使用示例

### 绑定新设备

```dart
// 用户输入SN
String sn = 'LIGHT001_250101_000099';

// 系统自动识别设备类型
String deviceType = DeviceCardFactory.getDeviceTypeName(sn);
// 输出: "智能灯"

String icon = DeviceCardFactory.getDeviceIcon(sn);
// 输出: "💡"

// 检查是否支持
bool isSupported = DeviceCardFactory.isSupported(sn);
// 输出: true

// 绑定后自动显示对应的智能灯卡片
```

### 动态列表展示

```dart
// 在设备列表中
ListView.builder(
  itemCount: devices.length,
  itemBuilder: (context, index) {
    final device = devices[index];
    
    // 自动创建对应的卡片
    // AC001_xxx → 空调卡片
    // LIGHT001_xxx → 智能灯卡片
    // CAM001_xxx → 摄像头卡片
    return DeviceCardFactory.createCard(device);
  },
)
```

## ➕ 添加新设备类型

如需添加新的设备类型，按以下步骤操作：

### 1. 定义型号代码

在 `device_mapping.dart` 中添加：

```dart
static const Map<String, String> deviceTypeMapping = {
  'NEW001': 'NewDeviceCard',  // 添加新型号
};
```

### 2. 创建设备卡片

创建 `new_device_card.dart`：

```dart
class NewDeviceCard extends StatelessWidget {
  final Device device;
  const NewDeviceCard({required this.device});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(device.name),
          // 设备专属UI
        ],
      ),
    );
  }
}
```

### 3. 注册到工厂

在 `device_card_factory.dart` 中添加：

```dart
import '../../device_cards/new_device_card.dart';

switch (cardType) {
  case 'NewDeviceCard':
    return NewDeviceCard(device: device);
  // ...
}
```

## 📝 相关文件

| 文件 | 作用 |
|-----|------|
| `lib/core/utils/device_mapping.dart` | SN解析和设备类型映射 |
| `lib/features/home/widgets/device_card_factory.dart` | 动态卡片工厂 |
| `lib/features/home/screens/home_screen.dart` | 使用工厂创建卡片 |
| `lib/data/mock/mock_data.dart` | Mock数据（12个设备示例） |
| `SN_FORMAT_GUIDE.md` | SN格式详细文档 |

## ✨ 功能特点

1. **自动识别** - 根据SN自动识别设备类型
2. **动态加载** - 运行时动态创建对应的卡片组件
3. **向后兼容** - 支持两种SN格式（_ 和 -）
4. **可扩展** - 轻松添加新的设备类型
5. **类型安全** - 未知设备使用通用卡片
6. **完整支持** - 12种设备类型全覆盖

## 🎉 测试结果

✅ 代码检查通过：`flutter analyze` 无错误  
✅ SN解析正确：支持两种格式  
✅ 卡片映射正确：12种设备全部映射  
✅ Mock数据更新：12个设备示例  
✅ UI动态加载：工厂模式实现  

---

**功能状态**: 🟢 已完成  
**最后更新**: 2025-01-01  
**版本**: v1.0.0

