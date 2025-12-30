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

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _hasLoadedData = false; // 标记是否已经加载过数据

  final List<Widget> _pages = const [
    HomeScreen(),
    FamilyScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 注册生命周期监听
    WidgetsBinding.instance.addObserver(this);
    // 设置 MQTT 消息处理器并加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMqttHandlers();
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    // 移除生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final authState = ref.read(authProvider);
    final mqttNotifier = ref.read(mqttProvider.notifier);
    final mqttState = ref.read(mqttProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        // App 进入前台，连接 MQTT
        if (authState.isAuthenticated && 
            authState.account != null && 
            mqttState.connectionState != MqttConnectionState.connected) {
          print('[MQTT] App 进入前台，连接 MQTT');
          mqttNotifier.connect(
            userId: authState.account!.id.toString(),
          ).then((_) {
            // 连接成功后，如果有家庭 ID，订阅家庭消息
            final currentFamilyId = authState.account?.currentFamilyId;
            if (currentFamilyId != null) {
              print('[MQTT] App 恢复连接，订阅家庭消息 (Home ID: $currentFamilyId)');
              mqttNotifier.subscribeHomeNotice(currentFamilyId);
            }
          }).catchError((error) {
            print('[MQTT] 连接失败: $error');
          });
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App 进入后台，断开 MQTT
        if (mqttState.connectionState == MqttConnectionState.connected) {
          print('[MQTT] App 进入后台，断开 MQTT');
          mqttNotifier.disconnect();
        }
        break;
      case AppLifecycleState.detached:
        // App 被系统终止
        if (mqttState.connectionState == MqttConnectionState.connected) {
          print('[MQTT] App 被终止，断开 MQTT');
          mqttNotifier.disconnect();
        }
        break;
      case AppLifecycleState.hidden:
        // App 被隐藏（某些平台）
        if (mqttState.connectionState == MqttConnectionState.connected) {
          print('[MQTT] App 被隐藏，断开 MQTT');
          mqttNotifier.disconnect();
        }
        break;
    }
  }

  void _loadInitialData() {
    final authState = ref.read(authProvider);
    
    // 如果已登录，加载数据并连接 MQTT
    if (authState.isAuthenticated && authState.account != null && !_hasLoadedData) {
      print('[MainScreen] 初始化时检测到已登录，加载数据');
      _hasLoadedData = true;
      // 加载设备列表和消息
      Future.wait([
        ref.read(deviceListProvider.notifier).loadDevices(),
        ref.read(messageProvider.notifier).loadMessages(),
      ]).catchError((error) {
        print('[MainScreen] 加载数据失败: $error');
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
    
    // 监听认证状态变化，登录成功后加载数据
    ref.listen<AuthState>(authProvider, (previous, next) {
      // 如果退出登录，重置加载标志
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        _hasLoadedData = false;
        print('[MainScreen] 用户退出登录，重置加载标志');
        return;
      }
      
      // 从未登录变为已登录时，加载数据
      // 检查：当前已登录 && 不在加载中 && 之前未登录 && 有账户信息 && 尚未加载过数据
      if (next.isAuthenticated && 
          !next.isLoading && 
          (previous == null || !previous.isAuthenticated) &&
          next.account != null &&
          !_hasLoadedData) {
        print('[MainScreen] 检测到登录状态变化：从未登录变为已登录，加载数据');
        _hasLoadedData = true;
        // 加载设备列表和消息
        Future.wait([
          ref.read(deviceListProvider.notifier).loadDevices(),
          ref.read(messageProvider.notifier).loadMessages(),
        ]).catchError((error) {
          print('[MainScreen] 加载数据失败: $error');
        });
      }
    });
    
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

