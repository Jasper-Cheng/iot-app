import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/routes/router.dart';

/// 扫一扫工具类
class QRScanner {
  /// 打开扫一扫页面
  /// 
  /// [context] 上下文
  /// [onResult] 扫码结果回调，参数为扫描到的字符串，如果为null表示取消或失败
  static Future<void> scan(BuildContext context, {Function(String)? onResult}) async {
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
        onResult?.call('');
        return;
      }
    }

    // 打开扫码页面
    if (context.mounted) {
      final result = await context.push<String>(AppRouter.scan);

      // 处理扫码结果
      if (result != null && result.isNotEmpty && context.mounted) {
        onResult?.call(result);
      } else {
        onResult?.call('');
      }
    }
  }
}

/// 二维码扫描页面
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
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
            
            // 等待足够长的时间，确保 UI 完全更新且稳定
            await Future.delayed(const Duration(milliseconds: 300));
            
            // 返回
            if (mounted && context.canPop()) {
              context.pop();
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
          
          // 等待足够长的时间，确保 UI 完全更新且稳定
          // 这样即使后续的 dispose 操作触发纹理错误，用户也看不到闪烁
          await Future.delayed(const Duration(milliseconds: 300));
          
          // 直接返回，让 dispose 处理相机关闭
          if (mounted && context.canPop()) {
            context.pop();
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

