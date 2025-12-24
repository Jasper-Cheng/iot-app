import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/device_card.dart';

/// 首页（设备列表）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的设备'),
        actions: [
          // 通知图标
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              // TODO: 打开通知页面
            },
          ),
          // 主题切换
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
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
                        child: DeviceCard(device: device),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showBindDeviceDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('添加设备'),
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

  void _showBindDeviceDialog(BuildContext context, WidgetRef ref) {
    final snController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('绑定设备'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: snController,
              decoration: const InputDecoration(
                labelText: '设备序列号(SN)',
                hintText: '例如: AC001-250101-000001',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '设备名称(可选)',
                hintText: '例如: 客厅空调',
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
                await ref.read(deviceListProvider.notifier).bindDevice(
                      snController.text,
                      name: nameController.text.isEmpty
                          ? null
                          : nameController.text,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('设备绑定成功')),
                  );
                }
              }
            },
            child: const Text('绑定'),
          ),
        ],
      ),
    );
  }
}

