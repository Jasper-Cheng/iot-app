import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/message_provider.dart';
import '../widgets/device_message_item.dart';
import '../widgets/system_message_item.dart';

/// 消息通知页面
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
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
    final state = ref.watch(messageProvider);
    final notifier = ref.read(messageProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          if (state.unreadDeviceCount > 0 && _tabController.index == 0)
            TextButton.icon(
              onPressed: () => notifier.markAllDeviceMessagesAsRead(),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('全部已读'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('设备消息'),
                  if (state.unreadDeviceCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.unreadDeviceCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('系统消息'),
                  if (state.unreadSystemCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.unreadSystemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDeviceMessagesTab(state, notifier),
            _buildSystemMessagesTab(state),
          ],
        ),
      ),
    );
  }

  /// 设备消息标签页
  Widget _buildDeviceMessagesTab(
    MessageState state,
    MessageNotifier notifier,
  ) {
    if (state.isLoading && state.deviceMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.deviceMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无设备消息',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.deviceMessages.length,
      itemBuilder: (context, index) {
        final message = state.deviceMessages[index];
        return DeviceMessageItem(
          message: message,
          onTap: () {
            if (message.status == 'new') {
              notifier.markDeviceMessageAsRead(message.id);
            }
          },
        );
      },
    );
  }

  /// 系统消息标签页
  Widget _buildSystemMessagesTab(MessageState state) {
    if (state.isLoading && state.systemMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.systemMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无系统消息',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.systemMessages.length,
      itemBuilder: (context, index) {
        final message = state.systemMessages[index];
        return SystemMessageItem(message: message);
      },
    );
  }
}

