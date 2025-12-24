# 设备SN格式说明

## 📋 SN格式规则

设备序列号（SN）格式：`modecode_时间_序列号`

### 格式说明

```
modecode_YYMMDD_NNNNNN
   ↓       ↓       ↓
型号代码  日期   序列号
```

### 示例

```
AC001_250101_000001
  ↓      ↓      ↓
空调   2025年  第1台
       1月1日

CAM001_250115_000123
   ↓       ↓       ↓
摄像头  2025年   第123台
       1月15日
```

## 🔧 支持的设备类型

### 1. 空调系列
- **型号代码**: `AC001`, `AC002`, `AC003`
- **设备卡片**: AirCoolerCard
- **示例SN**: 
  - `AC001_250101_000001`
  - `AC002_250101_000002`
  - `AC003_250101_000003`

### 2. 智能灯系列
- **型号代码**: `LIGHT001`, `LIGHT002`, `LIGHT003`
- **设备卡片**: SmartLightCard
- **示例SN**: 
  - `LIGHT001_250101_000001`
  - `LIGHT002_250101_000002`

### 3. 摄像头系列
- **型号代码**: `CAM001`, `CAM002`, `CAM003`
- **设备卡片**: CameraCard
- **示例SN**: 
  - `CAM001_250101_000001`
  - `CAM002_250101_000002`

### 4. 智能电视系列
- **型号代码**: `TV001`, `TV002`, `TV003`
- **设备卡片**: SmartTVCard
- **示例SN**: 
  - `TV001_250101_000001`
  - `TV002_250101_000002`

### 5. 跌倒检测器系列
- **型号代码**: `FALL001`, `FALL002`, `FALL003`
- **设备卡片**: FallDetectionCard
- **示例SN**: 
  - `FALL001_250101_000001`
  - `FALL002_250101_000002`

### 6. 路由器/Wi-Fi系列
- **型号代码**: `WIFI001`, `WIFI002`, `WIFI003`
- **设备卡片**: WiFiCard
- **示例SN**: 
  - `WIFI001_250101_000001`
  - `WIFI002_250101_000002`

### 7. 扫地机器人系列
- **型号代码**: `ROBOT001`, `ROBOT002`, `ROBOT003`
- **设备卡片**: VacuumCard
- **示例SN**: 
  - `ROBOT001_250101_000001`
  - `ROBOT002_250101_000002`

### 8. 洗衣机系列
- **型号代码**: `WASH001`, `WASH002`, `WASH003`
- **设备卡片**: WashingMachineCard
- **示例SN**: 
  - `WASH001_250101_000001`
  - `WASH002_250101_000002`

### 9. 冰箱系列
- **型号代码**: `FRIDGE001`, `FRIDGE002`, `FRIDGE003`
- **设备卡片**: RefrigeratorCard
- **示例SN**: 
  - `FRIDGE001_250101_000001`
  - `FRIDGE002_250101_000002`

### 10. 音箱系列
- **型号代码**: `SPEAKER001`, `SPEAKER002`, `SPEAKER003`
- **设备卡片**: SpeakerCard
- **示例SN**: 
  - `SPEAKER001_250101_000001`
  - `SPEAKER002_250101_000002`

### 11. 空气净化器系列
- **型号代码**: `AIR001`, `AIR002`, `AIR003`
- **设备卡片**: AirPurifierCard
- **示例SN**: 
  - `AIR001_250101_000001`
  - `AIR002_250101_000002`

### 12. 环境监测器系列
- **型号代码**: `M701001`
- **设备卡片**: EnvironmentMonitorCard
- **示例SN**: 
  - `M701001_250101_000001`

## 🔄 兼容性

系统同时支持两种SN格式：

### 格式1：下划线分隔 ✅ (推荐)
```
modecode_YYMMDD_NNNNNN
AC001_250101_000001
```

### 格式2：横线分隔 ✅ (兼容)
```
modecode-YYMMDD-NNNNNN
AC001-250101-000001
```

**注意**: 系统会自动识别并解析这两种格式。

## 💻 代码实现

### 1. SN解析

```dart
import 'package:iot_app/core/utils/device_mapping.dart';

// 解析SN获取型号代码
String sn = 'AC001_250101_000001';
String modelCode = DeviceMapping.getModelCodeBySN(sn);
// 结果: 'AC001'

// 获取设备类型名称
String deviceName = DeviceMapping.getDeviceNameByModel(modelCode);
// 结果: '空调'

// 获取设备图标
String icon = DeviceMapping.getDeviceIconByModel(modelCode);
// 结果: '❄️'
```

### 2. 动态创建设备卡片

```dart
import 'package:iot_app/features/home/widgets/device_card_factory.dart';
import 'package:iot_app/data/models/device.dart';

// 创建设备对象
Device device = Device(
  id: 1,
  name: '客厅空调',
  sn: 'AC001_250101_000001',
  status: 'online',
  modelId: 1,
  createdAt: DateTime.now(),
);

// 自动根据SN创建对应的设备卡片
Widget card = DeviceCardFactory.createCard(device);
// 结果: 返回 AirCoolerCard widget
```

### 3. 在列表中使用

```dart
ListView.builder(
  itemCount: devices.length,
  itemBuilder: (context, index) {
    final device = devices[index];
    return DeviceCardFactory.createCard(device);
  },
)
```

## 🎯 工作流程

1. **设备绑定**: 用户输入SN（如 `AC001_250101_000001`）
2. **SN解析**: 系统自动解析出型号代码 `AC001`
3. **类型映射**: 根据型号代码查找对应的卡片类型 `AirCoolerCard`
4. **卡片创建**: 动态创建对应的设备卡片组件
5. **UI展示**: 在设备列表中显示专属卡片

## 📝 添加新设备类型

如需添加新的设备类型，需要修改以下文件：

### 1. 更新设备映射 (`lib/core/utils/device_mapping.dart`)

```dart
static const Map<String, String> deviceTypeMapping = {
  // 添加新设备型号
  'NEW001': 'NewDeviceCard',
  'NEW002': 'NewDeviceCard',
};

static String getDeviceNameByModel(String modelCode) {
  const modelNames = {
    // 添加设备名称
    'NEW001': '新设备',
  };
  return modelNames[modelCode] ?? '未知设备';
}

static String getDeviceIconByModel(String modelCode) {
  // 添加设备图标
  if (modelCode.startsWith('NEW')) return '🆕';
  return '📱';
}
```

### 2. 创建设备卡片 (`lib/features/device_cards/new_device_card.dart`)

```dart
class NewDeviceCard extends StatelessWidget {
  final Device device;
  
  const NewDeviceCard({required this.device});
  
  @override
  Widget build(BuildContext context) {
    // 实现设备卡片UI
  }
}
```

### 3. 注册到工厂 (`lib/features/home/widgets/device_card_factory.dart`)

```dart
import '../../device_cards/new_device_card.dart';

switch (cardType) {
  case 'NewDeviceCard':
    return NewDeviceCard(device: device);
  // ...
}
```

## 🧪 测试SN

可以使用以下测试SN来验证不同设备类型：

```dart
// 测试各种设备类型
List<String> testSNs = [
  'AC001_250101_000001',      // 空调
  'LIGHT001_250101_000001',   // 智能灯
  'CAM001_250101_000001',     // 摄像头
  'TV001_250101_000001',      // 智能电视
  'FALL001_250101_000001',    // 跌倒检测器
  'WIFI001_250101_000001',    // 路由器
  'ROBOT001_250101_000001',   // 扫地机器人
  'WASH001_250101_000001',    // 洗衣机
  'FRIDGE001_250101_000001',  // 冰箱
  'SPEAKER001_250101_000001', // 音箱
  'AIR001_250101_000001',     // 空气净化器
  'M701001_250101_000001',    // 环境监测器
];

// 验证解析
for (var sn in testSNs) {
  print('SN: $sn');
  print('Model: ${DeviceMapping.getModelCodeBySN(sn)}');
  print('Type: ${DeviceCardFactory.getDeviceTypeName(sn)}');
  print('---');
}
```

## ⚠️ 注意事项

1. **SN唯一性**: 每台设备的SN必须唯一
2. **格式一致性**: 建议统一使用下划线格式
3. **时间格式**: 日期部分使用YYMMDD格式（6位数字）
4. **序列号**: 建议使用6位数字，不足补0
5. **大小写**: 型号代码建议使用大写字母

## 🔍 调试技巧

```dart
// 查看SN解析结果
void debugSN(String sn) {
  print('=== SN Debug Info ===');
  print('Original SN: $sn');
  print('Model Code: ${DeviceMapping.getModelCodeBySN(sn)}');
  print('Card Type: ${DeviceMapping.getCardTypeBySN(sn)}');
  print('Device Name: ${DeviceCardFactory.getDeviceTypeName(sn)}');
  print('Device Icon: ${DeviceCardFactory.getDeviceIcon(sn)}');
  print('Is Supported: ${DeviceCardFactory.isSupported(sn)}');
  print('====================');
}

// 使用
debugSN('AC001_250101_000001');
```

---

**最后更新**: 2025-01-01  
**版本**: v1.0.0

