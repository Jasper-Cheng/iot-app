import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/screens/home_screen.dart';
import '../family/screens/family_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../../providers/mqtt_provider.dart';

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
    // 设置 MQTT 消息处理器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMqttHandlers();
    });
  }

  void _setupMqttHandlers() {
    final mqttNotifier = ref.read(mqttProvider.notifier);
    
    // 设置系统消息处理器
    mqttNotifier.setSystemMessageHandler((data) {
      print('[MainScreen] 收到系统消息:');
      print('  Payload: $data');
      
      // TODO: 具体处理逻辑待实现
      // 例如：显示通知、更新系统消息列表等
    });
    
    // 设置家庭消息处理器
    mqttNotifier.setFamilyMessageHandler((homeId, data) {
      print('[MainScreen] 收到家庭消息:');
      print('  Home ID: $homeId');
      print('  Payload: $data');
      
      // TODO: 具体处理逻辑待实现
      // 例如：显示通知、更新家庭消息列表等
    });
  }

  @override
  Widget build(BuildContext context) {
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

