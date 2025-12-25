import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    
    // 停止并释放扫描器
    // dispose 是同步方法，但 MobileScannerController 内部会处理异步清理
    try {
      controller.dispose();
    } catch (e) {
      // 忽略错误
    }
    
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

    // 短暂延迟确保 UI 更新
    await Future.delayed(const Duration(milliseconds: 100));

    // 直接返回，让 dispose 处理相机关闭
    // 不在这里停止相机，避免在导航动画期间操作纹理资源
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
        title: const Text("二维码扫描"),
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
        canPop: !_isProcessing, // 处理中时不允许返回
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // 处理返回按钮
          if (!_isDisposing) {
            _isDisposing = true;
            
            // 先隐藏预览，显示黑色背景
            if (mounted) {
              setState(() {
                _isProcessing = true;
              });
            }
            
            // 在异步操作前保存 Navigator 引用
            final navigator = Navigator.of(context);
            
            // 短暂延迟确保 UI 更新
            await Future.delayed(const Duration(milliseconds: 100));
            
            // 直接返回，让 dispose 处理相机关闭
            // 不在这里停止相机，避免在导航动画期间操作纹理资源
            if (mounted && navigator.canPop()) {
              navigator.pop();
            }
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




