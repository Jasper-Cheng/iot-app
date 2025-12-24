import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 智能电视设备卡片
class SmartTvCard extends StatefulWidget {
  final Device device;

  const SmartTvCard({
    super.key,
    required this.device,
  });

  @override
  State<SmartTvCard> createState() => _SmartTvCardState();
}

class _SmartTvCardState extends State<SmartTvCard> {
  bool _isPowerOn = true;
  int _volume = 50;
  int _channel = 1;
  String _source = 'HDMI1'; // HDMI1, HDMI2, AV, TV

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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('📺', style: TextStyle(fontSize: 24)),
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
                      Text(
                        widget.device.isOnline ? '在线' : '离线',
                        style: TextStyle(
                          color: widget.device.isOnline
                              ? AppColors.statusOnline
                              : AppColors.statusOffline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPowerOn,
                  onChanged: widget.device.isOnline
                      ? (value) {
                          setState(() {
                            _isPowerOn = value;
                          });
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isPowerOn && widget.device.isOnline) ...[
              // 频道和信号源
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CH $_channel',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('当前频道', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _source,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('信号源', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 音量控制
              Row(
                children: [
                  const Icon(Icons.volume_down),
                  Expanded(
                    child: Slider(
                      value: _volume.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$_volume',
                      onChanged: (value) {
                        setState(() {
                          _volume = value.toInt();
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up),
                  const SizedBox(width: 8),
                  Text(
                    '$_volume%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    Icons.remove,
                    'CH-',
                    () {
                      if (_channel > 1) {
                        setState(() => _channel--);
                      }
                    },
                  ),
                  _buildControlButton(
                    Icons.add,
                    'CH+',
                    () {
                      setState(() => _channel++);
                    },
                  ),
                  _buildControlButton(
                    Icons.input_outlined,
                    '信号源',
                    () => _showSourceSelector(context),
                  ),
                  _buildControlButton(
                    Icons.apps_outlined,
                    '应用',
                    () {},
                  ),
                ],
              ),
            ] else if (!_isPowerOn) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.tv_off_outlined,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '电视已关闭',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showSourceSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择信号源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['HDMI1', 'HDMI2', 'AV', 'TV'].map((source) {
            return RadioListTile<String>(
              title: Text(source),
              value: source,
              groupValue: _source,
              onChanged: (value) {
                setState(() {
                  _source = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

