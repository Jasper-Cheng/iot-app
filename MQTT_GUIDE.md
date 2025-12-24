# MQTT 使用指南

## 📡 MQTT Topic 说明

### Topic 格式

```
app/{sn}/data           # 后台 -> app (设备数据)
app/{sn}/status         # 后台 -> app (设备状态)
app/{sn}/control        # app -> 后台 (设备控制)
system/notice           # 系统通知
home/{home_id}/notice   # 家庭通知
```

### 参数说明

- `{sn}`: 设备序列号 (例如: `AC001-250101-000001`)
- `{home_id}`: 家庭ID (例如: `1`)

## 🔌 使用方法

### 1. 连接MQTT

在登录成功后自动连接：

```dart
// 在 auth_provider.dart 的登录成功后
final mqttNotifier = ref.read(mqttProvider.notifier);
await mqttNotifier.connect(
  userId: user.id.toString(),
  username: 'your_username',  // 可选
  password: 'your_password',  // 可选
);
```

### 2. 订阅主题

#### 订阅系统通知

```dart
// 自动订阅，无需手动调用
// 在 connect() 成功后会自动订阅 system/notice
```

#### 订阅家庭通知

```dart
final mqttNotifier = ref.read(mqttProvider.notifier);
mqttNotifier.subscribeHomeNotice(homeId: 1);
```

#### 订阅设备数据

```dart
final mqttNotifier = ref.read(mqttProvider.notifier);

// 订阅设备数据推送
mqttNotifier.subscribeDeviceData(sn: 'AC001-250101-000001');

// 订阅设备状态
mqttNotifier.subscribeDeviceStatus(sn: 'AC001-250101-000001');
```

### 3. 发送控制指令

```dart
final mqttNotifier = ref.read(mqttProvider.notifier);

// 发送设备控制指令
mqttNotifier.controlDevice(
  sn: 'AC001-250101-000001',
  command: {
    'action': 'setPower',
    'value': true,
  },
);
```

## 📦 消息格式

### 设备数据消息 (app/{sn}/data)

后台推送给App的设备数据：

```json
{
  "sn": "AC001-250101-000001",
  "timestamp": 1704067200000,
  "data": {
    "temperature": 26,
    "humidity": 60,
    "power": true,
    "mode": "cool"
  }
}
```

### 设备状态消息 (app/{sn}/status)

后台推送给App的设备状态：

```json
{
  "sn": "AC001-250101-000001",
  "status": "online",
  "timestamp": 1704067200000
}
```

### 控制指令消息 (app/{sn}/control)

App发送给后台的控制指令：

```json
{
  "action": "setPower",
  "value": true,
  "timestamp": 1704067200000
}
```

### 系统通知消息 (system/notice)

```json
{
  "type": "maintenance",
  "title": "系统维护通知",
  "content": "系统将于今晚22:00-24:00进行维护",
  "timestamp": 1704067200000
}
```

### 家庭通知消息 (home/{home_id}/notice)

```json
{
  "home_id": 1,
  "type": "device_alert",
  "device_sn": "AC001-250101-000001",
  "message": "设备离线",
  "timestamp": 1704067200000
}
```

## 🎯 完整示例

### 在设备详情页使用MQTT

```dart
class DeviceDetailScreen extends ConsumerStatefulWidget {
  final Device device;
  
  const DeviceDetailScreen({required this.device});

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();
    
    // 订阅设备数据和状态
    Future.microtask(() {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.subscribeDeviceData(widget.device.sn);
      mqttNotifier.subscribeDeviceStatus(widget.device.sn);
    });
  }

  void _controlDevice(String action, dynamic value) {
    final mqttNotifier = ref.read(mqttProvider.notifier);
    mqttNotifier.controlDevice(
      widget.device.sn,
      {
        'action': action,
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 监听MQTT消息
    ref.listen(mqttProvider, (previous, next) {
      // 处理新消息
      if (next.recentMessages.isNotEmpty) {
        final latestMessage = next.recentMessages.last;
        if (latestMessage.topic.contains(widget.device.sn)) {
          // 更新UI或处理数据
          print('收到设备消息: ${latestMessage.payload}');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name)),
      body: Column(
        children: [
          // 开关控制
          Switch(
            value: true,
            onChanged: (value) => _controlDevice('setPower', value),
          ),
        ],
      ),
    );
  }
}
```

### 监听MQTT连接状态

```dart
// 在任意Widget中监听连接状态
final isConnected = ref.watch(mqttIsConnectedProvider);

if (isConnected) {
  // MQTT已连接
} else {
  // MQTT未连接
}
```

## 🔧 配置MQTT Broker

在 `lib/core/constants/api_constants.dart` 中配置：

```dart
// MQTT 配置
static const String mqttBroker = 'your-mqtt-broker.com';  // 修改为实际的broker地址
static const int mqttPort = 1883;
static const String mqttClientPrefix = 'flutter_iot_';
```

## 📝 注意事项

1. **自动重连**: MQTT服务会在断开后自动尝试重连
2. **Topic清理**: 离开页面时建议取消订阅不需要的topic
3. **消息处理**: 在 `mqtt_provider.dart` 的 `_handleMessage` 方法中处理接收到的消息
4. **连接时机**: 建议在登录成功后立即连接MQTT
5. **断开连接**: 退出登录时应该断开MQTT连接

## 🐛 调试

MQTT服务已内置日志输出，查看控制台可以看到：
- 连接状态
- 订阅主题
- 接收/发送的消息

```
MQTT: 连接成功
MQTT: 订阅主题 - system/notice
MQTT: 收到消息 - Topic: app/AC001/data, Payload: {...}
MQTT: 发布消息 - Topic: app/AC001/control, Message: {...}
```

## 🚀 性能优化建议

1. **按需订阅**: 只订阅当前需要的设备topic
2. **消息限制**: Provider中已限制最近消息数量为100条
3. **及时取消**: 离开页面时取消不需要的订阅
4. **批量订阅**: 可以一次性订阅多个设备的topic

## 📚 相关文件

- `lib/core/mqtt/mqtt_service.dart` - MQTT服务封装
- `lib/providers/mqtt_provider.dart` - MQTT状态管理
- `lib/core/constants/api_constants.dart` - MQTT配置

---

**提示**: MQTT功能需要可访问的MQTT Broker才能正常工作，开发时可以使用公共测试broker或搭建本地broker。

