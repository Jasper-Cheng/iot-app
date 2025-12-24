import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 摄像头设备卡片
class CameraCard extends StatefulWidget {
  final Device device;

  const CameraCard({
    super.key,
    required this.device,
  });

  @override
  State<CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends State<CameraCard> {
  bool _isRecording = false;
  String _quality = 'HD'; // SD, HD, FHD

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('📷', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.device.isOnline
                                  ? AppColors.statusOnline
                                  : AppColors.statusOffline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.device.isOnline ? '在线' : '离线',
                            style: TextStyle(
                              color: widget.device.isOnline
                                  ? AppColors.statusOnline
                                  : AppColors.statusOffline,
                              fontSize: 12,
                            ),
                          ),
                          if (_isRecording) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fiber_manual_record,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '录制中',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: widget.device.isOnline
                      ? () {
                          _showCameraOptions(context);
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 视频预览区域（占位）
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.device.isOnline
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击查看实时画面',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off_outlined,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '摄像头离线',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            if (widget.device.isOnline) ...[
              // 控制按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isRecording = !_isRecording;
                        });
                        // TODO: 发送MQTT控制命令
                      },
                      icon: Icon(
                        _isRecording
                            ? Icons.stop
                            : Icons.fiber_manual_record,
                      ),
                      label: Text(_isRecording ? '停止录制' : '开始录制'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? AppColors.danger
                            : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      // TODO: 拍照
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      // TODO: 相册
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 画质选择
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('画质'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'SD', label: Text('SD')),
                      ButtonSegment(value: 'HD', label: Text('HD')),
                      ButtonSegment(value: 'FHD', label: Text('FHD')),
                    ],
                    selected: {_quality},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _quality = newSelection.first;
                      });
                      // TODO: 发送MQTT控制命令
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCameraOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fullscreen_outlined),
              title: const Text('全屏查看'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 全屏查看
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_outlined),
              title: const Text('语音对讲'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 语音对讲
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('云存储'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 云存储
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('摄像头设置'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 设置
              },
            ),
          ],
        ),
      ),
    );
  }
}

