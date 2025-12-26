import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/message_provider.dart';
import '../widgets/device_card_factory.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/device_mapping.dart';

/// 首页（设备列表）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceListProvider);
    final messageState = ref.watch(messageProvider);
    final unreadCount = messageState.unreadDeviceCount;

    return Scaffold(
      drawer: _buildDrawer(context, ref),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('我的设备'),
        actions: [
          // 通知图标
          IconButton(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              _showMessageMenu(context, ref);
            },
          ),
          // 添加设备按钮（弹出菜单）
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, size: 28),
            tooltip: '添加设备',
            padding: EdgeInsets.zero, // 移除默认内边距
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ), // 增加点击范围
            offset: const Offset(0, 48), // 菜单在按钮下方弹出
            popUpAnimationStyle: AnimationStyle.noAnimation, // 移除动画效果
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            onSelected: (value) {
              if (value == 'scan') {
                _handleScanQRCode(context, ref);
              } else if (value == 'input') {
                _showBindDeviceDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20),
                    SizedBox(width: 8),
                    Text('扫一扫'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'input',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('输入SN'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(deviceListProvider.notifier).refresh();
        },
        child: deviceState.isLoading && deviceState.devices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : deviceState.devices.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: deviceState.devices.length,
                    itemBuilder: (context, index) {
                      final device = deviceState.devices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        // 使用工厂方法根据SN动态创建对应的设备卡片
                        child: DeviceCardFactory.createCard(device),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_outlined,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无设备',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加设备',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// 构建侧边栏
  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceListProvider);
    
    return Drawer(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            // 快捷操作区域
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '快捷操作',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _handleQuickAction(context, ref, 'leave');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2,vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 图标容器
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.power_settings_new,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 主标题
                              Text(
                                '离家断电',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              // 副标题
                              Text(
                                '关闭所有设备',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _handleQuickAction(context, ref, 'home');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 图标容器
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.power,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 主标题
                              Text(
                                '回家通电',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              // 副标题
                              Text(
                                '开启常用设备',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _handleQuickAction(context, ref, 'all_on');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 图标容器
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.flash_on,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 主标题
                              Text(
                                '全部打开',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              // 副标题
                              Text(
                                '开启所有设备',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 设备列表标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  '设备列表',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${deviceState.devices.length} 个设备',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
          // 设备列表
          Expanded(
            child: deviceState.devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_outlined,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无设备',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: deviceState.devices.length,
                    itemBuilder: (context, index) {
                      final device = deviceState.devices[index];
                      return _buildDrawerDeviceItem(context, ref, device);
                    },
                  ),
          ),
        ],
        ),
      ),
    );
  }

  /// 构建侧边栏设备项
  Widget _buildDrawerDeviceItem(BuildContext context, WidgetRef ref, device) {
    final isOnline = device.isOnline;
    final modelCode = DeviceMapping.getModelCodeBySN(device.sn);
    final deviceIcon = DeviceMapping.getDeviceIconByModel(modelCode);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        dense: true,
        leading: Text(
          deviceIcon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          device.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'SN: ${device.sn}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? '在线' : '离线',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () {
            _handleDeviceConfigure(context, ref, device);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '配网',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  /// 处理快捷操作
  void _handleQuickAction(BuildContext context, WidgetRef ref, String action) {
    Navigator.pop(context); // 关闭侧边栏
    
    final deviceState = ref.read(deviceListProvider);
    final devices = deviceState.devices;
    
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无设备')),
      );
      return;
    }

    String message = '';
    switch (action) {
      case 'leave':
        message = '已执行离家断电操作';
        break;
      case 'home':
        message = '已执行回家通电操作';
        break;
      case 'all_on':
        message = '已执行全部打开操作';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 处理设备开关
  void _handleDeviceToggle(BuildContext context, WidgetRef ref, device, bool value) {
    // TODO: 实现设备开关控制
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name} ${value ? "已打开" : "已关闭"}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 处理设备配网
  void _handleDeviceConfigure(BuildContext context, WidgetRef ref, device) {
    Navigator.pop(context); // 关闭侧边栏
    
    // TODO: 实现设备配网功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name} 配网功能开发中'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 处理扫一扫
  static Future<void> _handleScanQRCode(BuildContext context, WidgetRef ref) async {
    // 检查相机权限
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要相机权限才能扫描二维码')),
          );
        }
        return;
      }
    }

    // 打开扫码页面
    if (context.mounted) {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const ScanPage(),
        ),
      );

      // 处理扫码结果
      if (result != null && result.isNotEmpty && context.mounted) {
        // 打开输入SN弹窗，并将扫描结果填充到SN输入框
        _showBindDeviceDialog(context, ref, initialSn: result);
      }
    }
  }

  static void _showBindDeviceDialog(BuildContext context, WidgetRef ref, {String? initialSn}) {
    final snController = TextEditingController(text: initialSn ?? '');
    final nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // 点击外部不关闭弹窗
      builder: (context) => AlertDialog(
        title: const Text('绑定设备'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: snController,
              decoration: InputDecoration(
                labelText: '设备序列号(SN)',
                labelStyle: TextStyle(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                ),
                hintText: '例如: AC001-250101-000001',
                hintStyle: TextStyle(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '设备名称(可选)',
                labelStyle: TextStyle(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                ),
                hintText: '例如: 客厅空调',
                hintStyle: TextStyle(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (snController.text.isNotEmpty) {
                try {
                  await ref.read(deviceListProvider.notifier).bindDevice(
                        snController.text,
                        name: nameController.text.isEmpty
                            ? null
                            : nameController.text,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('设备绑定成功'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('设备绑定失败: ${ErrorHandler.extractErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('绑定'),
          ),
        ],
      ),
    );
  }

  /// 显示消息菜单
  static void _showMessageMenu(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 48, right: 8,left: 48),
        child: const MessageMenuWidget(),
      ),
    );
  }
}

/// 消息菜单组件
class MessageMenuWidget extends StatefulWidget {
  const MessageMenuWidget({super.key});

  @override
  State<MessageMenuWidget> createState() => _MessageMenuWidgetState();
}

class _MessageMenuWidgetState extends State<MessageMenuWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Tab栏
          Consumer(
            builder: (context, ref, child) {
              final messageState = ref.watch(messageProvider);
              // 设备消息显示未读数量（deviceMessages已经是未读消息）
              final unreadDeviceCount = messageState.deviceMessages.length;
              
              return TabBar(
                controller: _tabController,
                dividerColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                tabs: [
                  Tab(text: '设备消息 ($unreadDeviceCount)'),
                  const Tab(text: '系统消息'),
                ],
              );
            },
          ),
          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _DeviceMessagesTab(),
                _SystemMessagesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备消息Tab
class _DeviceMessagesTab extends ConsumerWidget {
  const _DeviceMessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageState = ref.watch(messageProvider);
    final deviceMessages = messageState.deviceMessages;

    if (messageState.isLoading && deviceMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 消息列表或空状态
        Expanded(
          child: deviceMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无未读消息',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: deviceMessages.length,
                  itemBuilder: (context, index) {
                    final message = deviceMessages[index];
                    return _buildDeviceMessageItem(context, ref, message, Key('message_${message.id}'));
                  },
                ),
        ),
        // 底部操作按钮栏
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: deviceMessages.isEmpty ? 0.5 : 1.0,
                  child: InkWell(
                    onTap: deviceMessages.isEmpty ? null : () async {
                      await ref.read(messageProvider.notifier).markAllDeviceMessagesAsRead();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已全部标记为已读'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '一键已读',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ),
              Container(
                width: 1,
                height: 24,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    _showMessageLogDialog(context, ref);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '消息日志',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceMessageItem(
    BuildContext context,
    WidgetRef ref,
    message,
    Key key,
  ) {
    return _AnimatedDeviceMessageItem(
      key: key,
      message: message,
      onMarkAsRead: () {
        ref.read(messageProvider.notifier).markDeviceMessageAsRead(message.id);
      },
    );
  }

  /// 显示消息日志弹窗（已读消息）
  static void _showMessageLogDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        alignment: Alignment.center,
        child: _MessageLogDialog(ref: ref),
      ),
    );
  }
}

/// 带动画的设备消息项
class _AnimatedDeviceMessageItem extends StatefulWidget {
  final dynamic message;
  final VoidCallback onMarkAsRead;

  const _AnimatedDeviceMessageItem({
    super.key,
    required this.message,
    required this.onMarkAsRead,
  });

  @override
  State<_AnimatedDeviceMessageItem> createState() => _AnimatedDeviceMessageItemState();
}

class _AnimatedDeviceMessageItemState extends State<_AnimatedDeviceMessageItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _sizeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getLevelColor() {
    switch (widget.message.level) {
      case 'fatal':
      case 'error':
        return Colors.red;
      case 'normal':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  String _getLevelText() {
    switch (widget.message.level) {
      case 'fatal':
        return '致命';
      case 'error':
        return '错误';
      case 'normal':
        return '警告';
      case 'low':
      default:
        return '低';
    }
  }

  void _handleTap() async {
    if (widget.message.status == 'new') {
      // 开始播放动画
      await _controller.forward();
      // 动画完成后调用回调
      if (mounted) {
        widget.onMarkAsRead();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: InkWell(
              onTap: _handleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 中间内容
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message.message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.devices,
                                size: 14,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '设备${widget.message.deviceId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 右侧状态和时间
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _getLevelText(),
                          style: TextStyle(
                            color: _getLevelColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatDateTime(widget.message.createdAt, format: 'yyyy-MM-dd HH:mm:ss'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息日志弹窗（显示已读消息）
class _MessageLogDialog extends StatefulWidget {
  final WidgetRef ref;
  
  const _MessageLogDialog({required this.ref});

  @override
  State<_MessageLogDialog> createState() => _MessageLogDialogState();
}

class _MessageLogDialogState extends State<_MessageLogDialog> {
  List<dynamic> _readMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadMessages();
  }

  Future<void> _loadReadMessages() async {
    setState(() => _isLoading = true);
    final messages = await widget.ref.read(messageProvider.notifier).loadReadDeviceMessages();
    setState(() {
      _readMessages = messages;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text(
                  '消息日志 (${_readMessages.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // 消息列表
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _readMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无已读消息',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).disabledColor,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: _readMessages.length,
                          itemBuilder: (context, index) {
                            final message = _readMessages[index];
                            return _buildReadMessageItem(context, message);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadMessageItem(BuildContext context, message) {
    Color getLevelColor() {
      switch (message.level) {
        case 'fatal':
        case 'error':
          return Colors.red;
        case 'normal':
          return Colors.orange;
        case 'low':
        default:
          return Colors.green;
      }
    }

    String getLevelText() {
      switch (message.level) {
        case 'fatal':
          return '致命';
        case 'error':
          return '错误';
        case 'normal':
          return '警告';
        case 'low':
        default:
          return '低';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          // 可以在这里添加查看详情的功能
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 中间内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.devices,
                          size: 14,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '设备${message.deviceId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 右侧状态和时间
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    getLevelText(),
                    style: TextStyle(
                      color: getLevelColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.formatDateTime(message.createdAt, format: 'yyyy-MM-dd HH:mm:ss'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 系统消息Tab
class _SystemMessagesTab extends ConsumerWidget {
  const _SystemMessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageState = ref.watch(messageProvider);
    final systemMessages = messageState.systemMessages;

    if (messageState.isLoading && systemMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (systemMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无系统消息',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 8,top: 8),
        itemCount: systemMessages.length,
        itemBuilder: (context, index) {
          final message = systemMessages[index];
          return _buildSystemMessageItem(context, message);
        },
      ),
    );
  }

  Widget _buildSystemMessageItem(BuildContext context, message) {
    Color getPriorityColor() {
      switch (message.priority) {
        case 'urgent':
          return Colors.red;
        case 'high':
          return Colors.orange;
        case 'normal':
          return Colors.blue;
        case 'low':
        default:
          return Colors.grey;
      }
    }

    IconData getTypeIcon() {
      switch (message.type) {
        case 'announcement':
          return Icons.campaign;
        case 'maintenance':
          return Icons.build;
        case 'update':
          return Icons.system_update;
        case 'alert':
          return Icons.warning;
        case 'notification':
        default:
          return Icons.notifications;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // TODO: 显示消息详情
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    getTypeIcon(),
                    size: 16,
                    color: getPriorityColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    AppDateUtils.formatDateTime(message.createdAt, format: 'yyyy-MM-dd HH:mm:ss'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 二维码扫描页面
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _isDisposing = false; // 标记是否正在销毁
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await controller.start();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = '相机初始化失败: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    
    // 延迟释放扫描器，确保导航动画完全结束
    // 这样可以避免在动画期间访问无效纹理
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        controller.dispose();
      } catch (e) {
        // 忽略错误
      }
    });
    
    super.dispose();
  }

  void _handleScanResult(String result) async {
    if (_isProcessing || _isDisposing) return;

    _isProcessing = true;
    
    // 先隐藏预览，显示黑色背景
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    // 等待足够长的时间，确保 UI 完全更新且稳定
    // 这样即使后续的 dispose 操作触发纹理错误，用户也看不到闪烁
    await Future.delayed(const Duration(milliseconds: 300));

    // 直接返回，让 dispose 处理相机关闭
    if (mounted && !_isDisposing) {
      context.pop(result);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && !_isProcessing) {
        _handleScanResult(barcode.rawValue!);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double frameSize = 250;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text("二维码扫描"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // 自定义返回按钮行为
            if (_isDisposing || _isProcessing) return;
            
            _isDisposing = true;
            
            // 先隐藏预览，显示黑色背景
            if (mounted) {
              setState(() {
                _isProcessing = true;
              });
            }
            
            // 在异步操作前保存 Navigator 引用
            final navigator = Navigator.of(context);
            
            // 等待足够长的时间，确保 UI 完全更新且稳定
            await Future.delayed(const Duration(milliseconds: 300));
            
            // 返回
            if (mounted && navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: PopScope(
        canPop: false, // 阻止默认返回行为，手动处理
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          
          // 处理返回按钮
          if (_isDisposing || _isProcessing) return;
          
          _isDisposing = true;
          
          // 先隐藏预览，显示黑色背景
          if (mounted) {
            setState(() {
              _isProcessing = true;
            });
          }
          
          // 在异步操作前保存 Navigator 引用
          final navigator = Navigator.of(context);
          
          // 等待足够长的时间，确保 UI 完全更新且稳定
          // 这样即使后续的 dispose 操作触发纹理错误，用户也看不到闪烁
          await Future.delayed(const Duration(milliseconds: 300));
          
          // 直接返回，让 dispose 处理相机关闭
          if (navigator.canPop()) {
            navigator.pop();
          }
        },
        child: Stack(
          children: [
            // 黑色背景（避免花屏）
            Container(color: Colors.black),
            
            // 相机预览（处理中时隐藏，避免花屏）
            if (!_isInitializing && _errorMessage == null && !_isProcessing)
              MobileScanner(
                controller: controller,
                onDetect: _onDetect,
                fit: BoxFit.cover,
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Text(
                      "相机无法使用：$error",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            
            // 处理中状态（返回前隐藏预览，避免花屏）
            if (_isProcessing)
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),

          // 初始化状态
          if (_isInitializing)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("正在初始化相机..."),
                ],
              ),
            ),

          // 错误状态
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isInitializing = true;
                          _errorMessage = null;
                        });
                        _initializeCamera();
                      },
                      child: const Text("重试"),
                    ),
                  ],
                ),
              ),
            ),

          // 扫描框（仅在扫描器正常工作时显示）
          if (!_isInitializing && _errorMessage == null && !_isProcessing)
            Center(
              child: SizedBox(
                width: frameSize,
                height: frameSize,
                child: CustomPaint(
                  painter: _ScannerFramePainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 扫描框画笔
class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




