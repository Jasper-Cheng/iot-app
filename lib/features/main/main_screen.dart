import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../home/screens/home_screen.dart';
import '../family/screens/family_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/message_provider.dart';

/// 主框架页面（包含底部导航）
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    FamilyScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 设置 MQTT 消息处理器并加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMqttHandlers();
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final authState = ref.read(authProvider);
    
    // 如果已登录，加载设备相关信息和连接 MQTT
    if (authState.isAuthenticated && authState.account != null) {
      // 加载设备相关信息
      Future.wait([
        ref.read(deviceListProvider.notifier).loadDevices(),
        ref.read(messageProvider.notifier).loadMessages(),
      ]).catchError((error) {
        print('[MainScreen] 加载设备信息失败: $error');
      });
      
      // 连接 MQTT
      final mqttState = ref.read(mqttProvider);
      if (mqttState.connectionState != MqttConnectionState.connected) {
        ref.read(mqttProvider.notifier).connect(
          userId: authState.account!.id.toString(),
        ).catchError((error) {
          print('[MQTT] 连接失败: $error');
        });
      }
    }
  }

  void _setupMqttHandlers() {
    final mqttNotifier = ref.read(mqttProvider.notifier);
    
    // 设置系统消息处理器
    mqttNotifier.setSystemMessageHandler((data) {
      print('[MQTT] 收到系统消息: $data');
      // TODO: 具体处理逻辑待实现
      // 例如：显示通知、更新系统消息列表等
    });
    
    // 设置家庭消息处理器
    mqttNotifier.setFamilyMessageHandler((homeId, data) {
      print('[MQTT] 收到家庭消息 (Home ID: $homeId): $data');
      // TODO: 具体处理逻辑待实现
      // 例如：显示通知、更新家庭消息列表等
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // 监听 MQTT 连接状态变化（必须在 build 方法中使用 ref.listen）
    ref.listen<MqttState>(mqttProvider, (previous, next) {
      // 只在连接状态真正变化时输出日志
      if (previous?.connectionState != next.connectionState) {
        if (next.isConnected) {

          // 如果有当前家庭 ID，自动订阅家庭消息
          final currentFamilyId = authState.account?.currentFamilyId;
          print('[MQTT] 检查家庭 ID - Account: ${authState.account != null ? "存在" : "null"}, CurrentFamilyId: $currentFamilyId');
          if (currentFamilyId != null) {
            print('[MQTT] 当前家庭 ID: $currentFamilyId，订阅家庭消息');
            ref.read(mqttProvider.notifier).subscribeHomeNotice(currentFamilyId);
          } else {
            print('[MQTT] 当前无家庭 ID，跳过订阅家庭消息');
          }
        } else {
          print('[MQTT] 已断开连接');
        }
        
        // 输出错误信息（如果有）
        if (next.error != null) {
          print('[MQTT] 错误: ${next.error}');
        }
      }
    });
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: '家庭',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        ),
      ),
    );
  }
}

