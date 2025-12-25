import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/device_provider.dart';
import '../widgets/device_card_factory.dart';

/// 首页（设备列表）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceListProvider);

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );

      // 处理扫码结果
      if (result != null && result.isNotEmpty) {
        // 使用扫码结果绑定设备
        await ref.read(deviceListProvider.notifier).bindDevice(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设备绑定成功')),
          );
        }
      }
    }
  }

  static void _showBindDeviceDialog(BuildContext context, WidgetRef ref) {
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

/// 二维码扫描页面
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // 返回扫描结果
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          // 扫描框指示器
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

