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
import '../../providers/family_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/auth_repository.dart';

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
          username: '',
          password: authState.token,
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

  /// 处理家庭消息
  Future<void> _handleFamilyMessage(int homeId, Map<String, dynamic> data) async {
    try {
      // 提取消息类型和内容
      final type = data['type']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';
      
      // 检查是否是当前家庭
      final authState = ref.read(authProvider);
      final currentFamilyId = authState.account?.currentFamilyId;
      
      // 如果消息不是来自当前家庭，不处理（理论上不应该发生，因为只会订阅当前家庭）
      if (currentFamilyId != homeId) {
        print('[MQTT] 收到非当前家庭的消息，忽略 (homeId: $homeId, currentFamilyId: $currentFamilyId)');
        return;
      }

      // 根据消息类型进行处理
      switch (type) {
        case 'family_member_added':
          await _handleFamilyMemberAdded(message, data);
          break;
        case 'family_member_updated':
          await _handleFamilyMemberUpdated(message, data);
          break;
        case 'family_member_removed':
          await _handleFamilyMemberRemoved(message, data);
          break;
        case 'family_deleted':
          await _handleFamilyDeleted(message, data, homeId);
          break;
        case 'device_added_to_family':
          await _handleDeviceAddedToFamily(message, data);
          break;
        case 'device_removed_from_family':
          await _handleDeviceRemovedFromFamily(message, data);
          break;
        case 'member_info_updated':
          await _handleMemberInfoUpdated(message, data);
          break;
        case 'account_deleted':
          await _handleAccountDeleted(message, data);
          break;
        default:
          print('[MQTT] 未知的家庭消息类型: $type');
          // 显示默认通知
          if (message.isNotEmpty) {
            Fluttertoast.showToast(
              msg: message,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              timeInSecForIosWeb: 5,
            );
          }
      }
    } catch (e) {
      print('[MQTT] 处理家庭消息失败: $e');
    }
  }

  /// 处理成员加入家庭
  Future<void> _handleFamilyMemberAdded(String message, Map<String, dynamic> data) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 刷新家庭成员列表
    final authState = ref.read(authProvider);
    final currentFamilyId = authState.account?.currentFamilyId;
    if (currentFamilyId != null) {
      try {
        final familyNotifier = ref.read(familyListProvider.notifier);
        await familyNotifier.loadMembers(currentFamilyId);
      } catch (e) {
        print('[MQTT] 刷新家庭成员列表失败: $e');
      }
    }
  }

  /// 处理成员昵称更新
  Future<void> _handleFamilyMemberUpdated(String message, Map<String, dynamic> data) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 刷新家庭成员列表
    final authState = ref.read(authProvider);
    final currentFamilyId = authState.account?.currentFamilyId;
    if (currentFamilyId != null) {
      try {
        final familyNotifier = ref.read(familyListProvider.notifier);
        await familyNotifier.loadMembers(currentFamilyId);
      } catch (e) {
        print('[MQTT] 刷新家庭成员列表失败: $e');
      }
    }
  }

  /// 处理成员被移除
  Future<void> _handleFamilyMemberRemoved(String message, Map<String, dynamic> data) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 提取被移除的账户ID
    final removedAccountId = data['removed_account_id'];
    final authState = ref.read(authProvider);
    final currentUserId = authState.account?.id;
    final currentFamilyId = authState.account?.currentFamilyId;

    // 如果被移除的是当前用户，需要切换到个人模式
    if (removedAccountId != null && currentUserId != null) {
      // 处理 removedAccountId 可能是 int 或 String 的情况
      final removedId = removedAccountId is int 
          ? removedAccountId 
          : (removedAccountId is String 
              ? int.tryParse(removedAccountId) 
              : null);
      
      if (removedId == currentUserId && currentFamilyId != null) {
        // 当前用户被移除，需要切换回个人模式
        try {
          final mqttNotifier = ref.read(mqttProvider.notifier);
          final mqttState = ref.read(mqttProvider);
          
          // 1. 取消订阅家庭通知
          if (mqttState.isConnected) {
            final topic = ApiConstants.mqttHomeNotice(currentFamilyId);
            mqttNotifier.unsubscribe(topic);
          }

          // 2. 调用接口切换到个人模式
          final authRepository = AuthRepository();
          await authRepository.updateCurrentFamily(null);

          // 3. 刷新用户信息
          await ref.read(authProvider.notifier).refreshProfile();

          // 4. 刷新家庭列表
          final familyNotifier = ref.read(familyListProvider.notifier);
          await familyNotifier.loadFamilies();

          // 5. 刷新设备列表
          final deviceNotifier = ref.read(deviceListProvider.notifier);
          await deviceNotifier.refresh();

          // 6. 刷新消息列表
          final messageNotifier = ref.read(messageProvider.notifier);
          await messageNotifier.refresh();

          print('[MQTT] 当前用户被移除，已切换回个人模式');
          return; // 已切换模式，不需要刷新成员列表
        } catch (e) {
          print('[MQTT] 处理用户被移除失败: $e');
        }
      }
    }

    // 如果不是当前用户被移除，只需要刷新家庭成员列表
    if (currentFamilyId != null) {
      try {
        final familyNotifier = ref.read(familyListProvider.notifier);
        await familyNotifier.loadMembers(currentFamilyId);
      } catch (e) {
        print('[MQTT] 刷新家庭成员列表失败: $e');
      }
    }
  }

  /// 处理家庭被删除
  Future<void> _handleFamilyDeleted(String message, Map<String, dynamic> data, int homeId) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 检查是否是当前家庭
    final authState = ref.read(authProvider);
    final currentFamilyId = authState.account?.currentFamilyId;
    final currentUserId = authState.account?.id;
    
    // 提取被移除的账户ID（如果是移除创建者导致家庭删除的情况）
    final removedAccountId = data['removed_account_id'];
    
    if (currentFamilyId == homeId) {
      // 当前家庭被删除，需要切换回个人模式
      try {
        final mqttNotifier = ref.read(mqttProvider.notifier);
        final mqttState = ref.read(mqttProvider);
        
        // 1. 取消订阅家庭通知
        if (mqttState.isConnected) {
          final topic = ApiConstants.mqttHomeNotice(homeId);
          mqttNotifier.unsubscribe(topic);
        }

        // 2. 调用接口切换到个人模式
        final authRepository = AuthRepository();
        await authRepository.updateCurrentFamily(null);

        // 3. 刷新用户信息
        await ref.read(authProvider.notifier).refreshProfile();

        // 4. 刷新家庭列表
        final familyNotifier = ref.read(familyListProvider.notifier);
        await familyNotifier.loadFamilies();

        // 5. 刷新设备列表
        final deviceNotifier = ref.read(deviceListProvider.notifier);
        await deviceNotifier.refresh();

        // 6. 刷新消息列表
        final messageNotifier = ref.read(messageProvider.notifier);
        await messageNotifier.refresh();

        // 记录删除原因（如果是移除创建者导致）
        if (removedAccountId != null && currentUserId != null) {
          final removedId = removedAccountId is int 
              ? removedAccountId 
              : (removedAccountId is String 
                  ? int.tryParse(removedAccountId) 
                  : null);
          if (removedId == currentUserId) {
            print('[MQTT] 家庭因创建者被移除而删除');
          }
        }
      } catch (e) {
        print('[MQTT] 处理家庭删除失败: $e');
      }
    } else {
      // 非当前家庭被删除，只需要刷新家庭列表
      try {
        final familyNotifier = ref.read(familyListProvider.notifier);
        await familyNotifier.loadFamilies();
      } catch (e) {
        print('[MQTT] 刷新家庭列表失败: $e');
      }
    }
  }

  /// 处理设备添加到家庭
  Future<void> _handleDeviceAddedToFamily(String message, Map<String, dynamic> data) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 刷新设备列表
    try {
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      await deviceNotifier.refresh();
    } catch (e) {
      print('[MQTT] 刷新设备列表失败: $e');
    }
  }

  /// 处理设备从家庭移除
  Future<void> _handleDeviceRemovedFromFamily(String message, Map<String, dynamic> data) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 刷新设备列表
    try {
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      await deviceNotifier.refresh();
    } catch (e) {
      print('[MQTT] 刷新设备列表失败: $e');
    }
  }

  /// 处理成员信息更新
  Future<void> _handleMemberInfoUpdated(String message, Map<String, dynamic> data) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 提取更新的字段信息（用于日志）
    final updatedFields = data['updated_fields'];
    if (updatedFields != null && updatedFields is List) {
      print('[MQTT] 成员信息更新，更新的字段: ${updatedFields.join(", ")}');
    }

    // 刷新家庭成员列表（因为成员信息可能更新了）
    final authState = ref.read(authProvider);
    final currentFamilyId = authState.account?.currentFamilyId;
    if (currentFamilyId != null) {
      try {
        final familyNotifier = ref.read(familyListProvider.notifier);
        await familyNotifier.loadMembers(currentFamilyId);
      } catch (e) {
        print('[MQTT] 刷新家庭成员列表失败: $e');
      }
    }
  }

  /// 处理账号注销
  Future<void> _handleAccountDeleted(String message, Map<String, dynamic> data) async {
    // 显示通知
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );

    // 提取注销的账户ID
    final accountId = data['account_id'];
    final authState = ref.read(authProvider);
    final currentUserId = authState.account?.id;
    final currentFamilyId = authState.account?.currentFamilyId;

    // 处理 accountId 可能是 int 或 String 的情况
    final deletedAccountId = accountId is int 
        ? accountId 
        : (accountId is String 
            ? int.tryParse(accountId) 
            : null);

    // 如果注销的是当前用户（理论上不应该发生，因为账号已注销，但为了安全起见还是处理）
    if (deletedAccountId != null && currentUserId != null && deletedAccountId == currentUserId) {
      print('[MQTT] 当前用户账号已注销');
      // 账号已注销，理论上不会收到消息，但为了安全起见，可以做一些清理工作
      // 这里不需要特殊处理，因为账号注销后用户应该已经退出登录
    }

    // 刷新家庭成员列表（因为成员账号已注销，应该从列表中移除）
    // 如果无法访问家庭（可能是因为用户被移除或账号注销），自动切回个人设备管理
    if (currentFamilyId != null) {
      try {
        final familyNotifier = ref.read(familyListProvider.notifier);
        await familyNotifier.loadMembers(currentFamilyId);
      } catch (e) {
        print('[MQTT] 刷新家庭成员列表失败: $e');
        final errorMessage = ErrorHandler.extractErrorMessage(e);
        // 如果是"无权访问此家庭"的错误，说明用户已经不在该家庭中，需要切回个人设备管理
        if (errorMessage.contains('无权访问') || errorMessage.contains('无权访问此家庭')) {
          print('[MQTT] 检测到无权访问家庭，自动切回个人设备管理');
          await _switchToPersonalMode(currentFamilyId);
        }
      }
    }
  }

  /// 切换到个人设备管理（从MQTT消息处理中调用）
  Future<void> _switchToPersonalMode(int? previousFamilyId) async {
    try {
      // 1. 取消订阅之前的家庭通知（如果存在）
      if (previousFamilyId != null) {
        final mqttNotifier = ref.read(mqttProvider.notifier);
        final mqttState = ref.read(mqttProvider);
        if (mqttState.isConnected) {
          final topic = ApiConstants.mqttHomeNotice(previousFamilyId);
          mqttNotifier.unsubscribe(topic);
        }
      }

      // 2. 调用接口切换到个人模式
      final authRepository = AuthRepository();
      await authRepository.updateCurrentFamily(null);

      // 3. 刷新用户信息（更新 authProvider 中的 currentFamilyId 为 null）
      await ref.read(authProvider.notifier).refreshProfile();

      // 4. 重新获取 notifier（因为 familyListProvider 会重新创建，使用最新的 currentFamilyId）
      final newNotifier = ref.read(familyListProvider.notifier);

      // 5. 重新加载家庭列表（会使用最新的 currentFamilyId，应该是 null）
      await newNotifier.loadFamilies();

      // 6. 重新获取设备列表 notifier 并刷新设备列表（确保使用最新的 currentFamilyId）
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      await deviceNotifier.refresh();

      // 7. 重新获取消息列表 notifier 并刷新消息列表（确保使用最新的 currentFamilyId）
      final messageNotifier = ref.read(messageProvider.notifier);
      await messageNotifier.refresh();

      print('[MQTT] 已自动切回个人设备管理');
    } catch (e) {
      print('[MQTT] 切换到个人模式失败: $e');
    }
  }

  /// 处理设备消息通知
  Future<void> _handleDeviceNotice(String deviceSn, Map<String, dynamic> data) async {
    try {
      // 提取消息类型和内容
      final type = data['type']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';

      // 获取当前用户ID，用于判断是否是自己的操作
      final authState = ref.read(authProvider);
      final currentUserId = authState.account?.id;

      // 提取操作者ID（可能是 int 或 String）
      final operatorAccountId = data['operator_account_id'];

      // 如果 operator_account_id 和当前用户ID相同，则不处理（避免重复处理自己的操作）
      // if (currentUserId != null && operatorAccountId != null) {
      //   final operatorId = operatorAccountId is int
      //       ? operatorAccountId
      //       : (operatorAccountId is String
      //           ? int.tryParse(operatorAccountId)
      //           : null);
      //
      //   if (operatorId == currentUserId) {
      //     print('[MQTT] 忽略当前用户自己操作的设备消息通知 (type: $type, deviceSn: $deviceSn)');
      //     return;
      //   }
      // }

      // 根据消息类型进行处理
      switch (type) {
        case 'message_read':
          await _handleMessageRead(deviceSn, message, data);
          break;
        case 'all_messages_read':
          await _handleAllMessagesRead(deviceSn, message, data);
          break;
        case 'device_name_updated':
          await _handleDeviceNameUpdated(deviceSn, message, data);
          break;
        case 'device_bind':
          // await _handleDeviceBind(deviceSn, message, data);
          break;
        case 'device_unbind':
          await _handleDeviceUnbind(deviceSn, message, data);
          break;
        default:
          print('[MQTT] 未知的设备消息类型: $type');
          // 对于未知类型，刷新消息列表
          ref.read(messageProvider.notifier).loadMessages().catchError((error) {
            print('[MQTT] 刷新消息列表失败: $error');
          });
      }
    } catch (e) {
      print('[MQTT] 处理设备消息通知失败: $e');
    }
  }

  /// 处理单条消息标记为已读
  Future<void> _handleMessageRead(String deviceSn, String message, Map<String, dynamic> data) async {
    try {
      // 提取消息ID
      final messageId = data['message_id'];
      if (messageId == null) {
        print('[MQTT] message_read 消息缺少 message_id 字段');
        return;
      }

      // 处理 messageId 可能是 int 或 String 的情况
      final id = messageId is int
          ? messageId
          : (messageId is String
              ? int.tryParse(messageId)
              : null);

      if (id == null) {
        print('[MQTT] message_read 消息的 message_id 格式错误: $messageId');
        return;
      }

      // 从消息列表中移除该消息
      final messageNotifier = ref.read(messageProvider.notifier);
      final currentState = ref.read(messageProvider);
      
      // 检查消息是否在未读列表中
      final messageExists = currentState.deviceMessages.any((msg) => msg.id == id);
      if (messageExists) {
        messageNotifier.removeMessage(id);
        print('[MQTT] 已从消息列表中移除已读消息 (message_id: $id)');
      }
    } catch (e) {
      print('[MQTT] 处理 message_read 失败: $e');
    }
  }

  /// 处理所有消息标记为已读
  Future<void> _handleAllMessagesRead(String deviceSn, String message, Map<String, dynamic> data) async {
    try {
      // 提取设备ID
      final deviceId = data['device_id'];
      
      // 处理 deviceId 可能是 int 或 String 的情况
      final id = deviceId is int
          ? deviceId
          : (deviceId is String
              ? int.tryParse(deviceId)
              : null);

      // 如果指定了设备ID，只移除该设备的未读消息；否则移除所有未读消息
      final messageNotifier = ref.read(messageProvider.notifier);
      
      if (id != null) {
        // 只移除指定设备的未读消息
        messageNotifier.removeMessagesByDeviceId(id);
        print('[MQTT] 已移除设备 $deviceSn (device_id: $id) 的所有未读消息');
      } else {
        // 移除所有未读消息
        messageNotifier.clearAllMessages();
        print('[MQTT] 已移除所有未读消息');
      }
    } catch (e) {
      print('[MQTT] 处理 all_messages_read 失败: $e');
    }
  }

  /// 处理设备名称更新
  Future<void> _handleDeviceNameUpdated(String deviceSn, String message, Map<String, dynamic> data) async {
    try {
      // 提取设备ID和新名称
      final deviceId = data['device_id'];
      final newName = data['device_name']?.toString();

      if (deviceId == null || newName == null || newName.isEmpty) {
        print('[MQTT] device_name_updated 消息缺少必要字段');
        return;
      }

      // 处理 deviceId 可能是 int 或 String 的情况
      final id = deviceId is int
          ? deviceId
          : (deviceId is String
              ? int.tryParse(deviceId)
              : null);

      if (id == null) {
        print('[MQTT] device_name_updated 消息的 device_id 格式错误: $deviceId');
        return;
      }

      // 显示通知
      if (message.isNotEmpty) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          timeInSecForIosWeb: 5,
        );
      }

      // 更新设备列表中的设备名称
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      final currentState = ref.read(deviceListProvider);
      
      // 检查设备是否在列表中
      final deviceExists = currentState.devices.any((d) => d.id == id);
      if (deviceExists) {
        deviceNotifier.updateDeviceNameById(id, newName);
        print('[MQTT] 已更新设备名称 (device_id: $id, device_sn: $deviceSn, new_name: $newName)');
      } else {
        print('[MQTT] 设备不在列表中，无法更新名称 (device_id: $id, device_sn: $deviceSn)');
        // 如果设备不在列表中，刷新设备列表
        await deviceNotifier.refresh();
      }
    } catch (e) {
      print('[MQTT] 处理 device_name_updated 失败: $e');
    }
  }

  /// 处理设备绑定
  Future<void> _handleDeviceBind(String deviceSn, String message, Map<String, dynamic> data) async {
    try {
      // 提取设备ID
      final deviceId = data['device_id'];

      if (deviceId == null) {
        print('[MQTT] device_bind 消息缺少 device_id 字段');
        return;
      }

      // 处理 deviceId 可能是 int 或 String 的情况
      final id = deviceId is int
          ? deviceId
          : (deviceId is String
              ? int.tryParse(deviceId)
              : null);

      if (id == null) {
        print('[MQTT] device_bind 消息的 device_id 格式错误: $deviceId');
        return;
      }

      // 显示通知
      if (message.isNotEmpty) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          timeInSecForIosWeb: 5,
        );
      }

      // 刷新设备列表（因为新设备被绑定了）
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      await deviceNotifier.refresh();
      
      // 刷新消息列表以确保数据一致性
      final messageNotifier = ref.read(messageProvider.notifier);
      await messageNotifier.refresh();
      
      print('[MQTT] 设备绑定成功，已刷新设备列表 (device_id: $id, device_sn: $deviceSn)');
    } catch (e) {
      print('[MQTT] 处理 device_bind 失败: $e');
    }
  }

  /// 处理设备解绑
  Future<void> _handleDeviceUnbind(String deviceSn, String message, Map<String, dynamic> data) async {
    try {
      // 提取设备ID
      final deviceId = data['device_id'];

      if (deviceId == null) {
        print('[MQTT] device_unbind 消息缺少 device_id 字段');
        return;
      }

      // 处理 deviceId 可能是 int 或 String 的情况
      final id = deviceId is int
          ? deviceId
          : (deviceId is String
              ? int.tryParse(deviceId)
              : null);

      if (id == null) {
        print('[MQTT] device_unbind 消息的 device_id 格式错误: $deviceId');
        return;
      }

      // 显示通知
      if (message.isNotEmpty) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          timeInSecForIosWeb: 5,
        );
      }

      // 从设备列表中移除该设备
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      final currentState = ref.read(deviceListProvider);
      
      // 检查设备是否在列表中
      final deviceExists = currentState.devices.any((d) => d.id == id || d.sn == deviceSn);
      if (deviceExists) {
        deviceNotifier.removeDeviceByIdOrSn(id, deviceSn);
        
        // 取消订阅该设备的 MQTT 主题
        final mqttNotifier = ref.read(mqttProvider.notifier);
        mqttNotifier.unsubscribe(ApiConstants.mqttDeviceNotice(deviceSn));
        mqttNotifier.unsubscribe(ApiConstants.mqttDeviceData(deviceSn));
        mqttNotifier.unsubscribe(ApiConstants.mqttDeviceStatus(deviceSn));
        
        // 刷新消息列表（移除该设备的未读消息）
        final messageNotifier = ref.read(messageProvider.notifier);
        messageNotifier.removeMessagesByDeviceId(id);
        
        print('[MQTT] 已从设备列表中移除设备 (device_id: $id, device_sn: $deviceSn)');
      } else {
        print('[MQTT] 设备不在列表中，无法移除 (device_id: $id, device_sn: $deviceSn)');
        // 即使设备不在列表中，也刷新消息列表以确保数据一致性
        final messageNotifier = ref.read(messageProvider.notifier);
        await messageNotifier.refresh();
      }
    } catch (e) {
      print('[MQTT] 处理 device_unbind 失败: $e');
    }
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
      _handleFamilyMessage(homeId, data);
    });

    // 设置设备消息通知处理器
    mqttNotifier.setDeviceNoticeHandler((deviceSn, data) {
      print('[MQTT] 收到设备消息通知 (Device SN: $deviceSn): $data');
      _handleDeviceNotice(deviceSn, data);
    });

    // 设置个人消息通知处理器（暂时屏蔽）
    mqttNotifier.setClientNoticeHandler((accountId, data) {
      print('[MQTT] 收到个人消息通知 (Account ID: $accountId): $data');
      // 暂时屏蔽个人消息处理
      return;
      
      // 提取消息类型
      // final type = data['type']?.toString();
      
      // 获取当前用户ID
      // final authState = ref.read(authProvider);
      // final currentUserId = authState.account?.id;
      
      // 提取操作者ID（可能是 int 或 String）
      // final operatorAccountId = data['operator_account_id'];
      
      // 如果 operator_account_id 和当前用户ID相同，则不处理
      // if (currentUserId != null && operatorAccountId != null) {
      //   // 处理 operatorAccountId 可能是 int 或 String 的情况
      //   final operatorId = operatorAccountId is int 
      //       ? operatorAccountId 
      //       : (operatorAccountId is String 
      //           ? int.tryParse(operatorAccountId) 
      //           : null);
      
      //   if (operatorId == currentUserId) {
      //     print('[MQTT] 忽略当前用户自己操作的消息通知 (type: $type, operator_account_id: $operatorAccountId)');
      //     return;
      //   }
      // }
      
      // 根据消息类型进行处理
      // final message = data['message']?.toString() ?? '';
      // if (message.isNotEmpty) {
      //   _handlePersonalNotice(type, message, data);
      // }
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

          // 订阅个人消息通知（暂时屏蔽）
          // if (authState.account != null) {
          //   final accountId = authState.account!.id.toString();
          //   mqttNotifier.subscribeClientNotice(accountId);
          // }

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

