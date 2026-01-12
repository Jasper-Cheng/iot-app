import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../home/screens/home_screen.dart';
import '../family/screens/family_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/message_provider.dart';
import '../../core/constants/api_constants.dart';

/// 主框架页面（包含底部导航）
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
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
    // 设置 MQTT 消息处理器并加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMqttHandlers();
      _loadInitialData();
    });
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

  /// 根据消息类型获取中文名称
  String _getMessageTypeName(String type) {
    switch (type) {
      case 'notification':
        return '通知';
      case 'announcement':
        return '公告';
      case 'alert':
        return '警告';
      case 'maintenance':
        return '维护';
      case 'update':
        return '更新';
      default:
        return '通知';
    }
  }

  /// 根据优先级获取 toast 背景颜色
  Color _getToastColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.yellow;
      case 'normal':
        return Colors.green;
      case 'low':
      default:
        return Colors.green;
    }
  }

  /// 处理个人消息通知
  void _handlePersonalNotice(String? type, String message, Map<String, dynamic> data) {
    Color backgroundColor;
    
    // 根据消息类型设置颜色
    if (type == 'feedback_replied') {
      // 反馈回复通知 - 蓝色
      backgroundColor = Colors.blue;
    } else if (type == 'check_in_success') {
      // 签到成功通知 - 绿色
      backgroundColor = Colors.green;
    } else if (type == 'feedback_created') {
      // 反馈创建通知 - 绿色
      backgroundColor = Colors.green;
    } else {
      // 积分调整或其他通知 - 根据积分正负判断颜色
      final points = data['points'];
      if (points != null) {
        final pointsValue = points is int ? points : (points is String ? int.tryParse(points) : null);
        if (pointsValue != null) {
          backgroundColor = pointsValue > 0 ? Colors.green : Colors.orange;
        } else {
          backgroundColor = Colors.blue;
        }
      } else {
        backgroundColor = Colors.blue;
      }
    }
    
    // 显示 Toast 通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      timeInSecForIosWeb: 5, // 显示 5 秒
    );
  }

  void _setupMqttHandlers() {
    final mqttNotifier = ref.read(mqttProvider.notifier);

    // 设置系统消息处理器
    mqttNotifier.setSystemMessageHandler((data) {
      print('[MQTT] 收到系统消息: $data');
      // 提取消息内容、类型和优先级
      final message = data['message']?.toString() ?? '';
      final type = data['type']?.toString() ?? 'notification';
      final priority = data['priority']?.toString() ?? 'normal';
      
      if (message.isNotEmpty) {
        // 根据优先级获取颜色
        final backgroundColor = _getToastColor(priority);
        // 获取类型中文名称
        final typeName = _getMessageTypeName(type);
        // 在消息前添加类型标签
        final displayMessage = '[$typeName] $message';
        
        // 在顶部显示 toast
        Fluttertoast.showToast(
          msg: displayMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: backgroundColor,
          textColor: Colors.white,
          timeInSecForIosWeb: 5, // 显示 5 秒
        );
      }
      
      // 刷新系统消息列表
      ref.read(messageProvider.notifier).loadSystemMessages().catchError((error) {
        print('[MainScreen] 加载系统消息失败: $error');
      });
    });

    // 设置家庭消息处理器
    mqttNotifier.setFamilyMessageHandler((homeId, data) {
      print('[MQTT] 收到家庭消息 (Home ID: $homeId): $data');
      // TODO: 具体处理逻辑待实现
      // 例如：显示通知、更新家庭消息列表等
    });

    // 设置设备消息通知处理器
    mqttNotifier.setDeviceNoticeHandler((deviceSn, data) {
      print('[MQTT] 收到设备消息通知 (Device SN: $deviceSn): $data');
      // 刷新消息列表
      ref.read(messageProvider.notifier).loadMessages();
    });

    // 设置个人消息通知处理器
    mqttNotifier.setClientNoticeHandler((accountId, data) {
      print('[MQTT] 收到个人消息通知 (Account ID: $accountId): $data');
      
      // 提取消息类型
      final type = data['type']?.toString();
      
      // 获取当前用户ID
      final authState = ref.read(authProvider);
      final currentUserId = authState.account?.id;
      
      // 提取操作者ID（可能是 int 或 String）
      final operatorAccountId = data['operator_account_id'];
      
      // feedback_replied 和 points_adjusted 类型除外，其他类型如果是当前用户操作的则不处理
      if (type != 'feedback_replied' && type != 'points_adjusted') {
        if (currentUserId != null && operatorAccountId != null) {
          // 处理 operatorAccountId 可能是 int 或 String 的情况
          final operatorId = operatorAccountId is int 
              ? operatorAccountId 
              : (operatorAccountId is String 
                  ? int.tryParse(operatorAccountId) 
                  : null);
          
          if (operatorId == currentUserId) {
            print('[MQTT] 忽略当前用户自己操作的消息通知 (type: $type, operator_account_id: $operatorAccountId)');
            return;
          }
        }
      }
      
      // 根据消息类型进行处理
      final message = data['message']?.toString() ?? '';
      if (message.isNotEmpty) {
        _handlePersonalNotice(type, message, data);
      }
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
          final mqttNotifier = ref.read(mqttProvider.notifier);

          // 如果有当前家庭 ID，自动订阅家庭消息
          final currentFamilyId = authState.account?.currentFamilyId;
          print('[MQTT] 检查家庭 ID - Account: ${authState.account != null ? "存在" : "null"}, CurrentFamilyId: $currentFamilyId');
          if (currentFamilyId != null) {
            mqttNotifier.subscribeHomeNotice(currentFamilyId);
          }

          // 订阅个人消息通知
          if (authState.account != null) {
            final accountId = authState.account!.id.toString();
            mqttNotifier.subscribeClientNotice(accountId);
          }

          // 订阅所有设备的设备消息通知
          final deviceState = ref.read(deviceListProvider);
          if (deviceState.devices.isNotEmpty) {
            print('[MQTT] 订阅设备消息通知，设备数量: ${deviceState.devices.length}');
            for (final device in deviceState.devices) {
              mqttNotifier.subscribeDeviceNotice(device.sn);
            }
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

    // 监听设备列表变化，自动订阅新设备的设备消息通知
    ref.listen<DeviceListState>(deviceListProvider, (previous, next) {
      if (!mounted) return;

      final mqttState = ref.read(mqttProvider);
      if (!mqttState.isConnected) return;

      final mqttNotifier = ref.read(mqttProvider.notifier);

      // 获取之前和现在的设备 SN 列表
      final previousSns = previous?.devices.map((d) => d.sn).toSet() ?? <String>{};
      final currentSns = next.devices.map((d) => d.sn).toSet();

      // 订阅新设备的设备消息通知
      for (final sn in currentSns) {
        if (!previousSns.contains(sn)) {
          mqttNotifier.subscribeDeviceNotice(sn);
        }
      }

      // 取消订阅已移除设备的设备消息通知
      for (final sn in previousSns) {
        if (!currentSns.contains(sn)) {
          mqttNotifier.unsubscribe(ApiConstants.mqttDeviceNotice(sn));
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

