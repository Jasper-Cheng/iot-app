import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 智能灯设备卡片
class SmartLightCard extends StatefulWidget {
  final Device device;

  const SmartLightCard({
    super.key,
    required this.device,
  });

  @override
  State<SmartLightCard> createState() => _SmartLightCardState();
}

class _SmartLightCardState extends State<SmartLightCard> {
  bool _isPowerOn = true;
  double _brightness = 80.0;
  Color _selectedColor = Colors.white;

  final List<Color> _presetColors = [
    Colors.white,
    Colors.amber,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
  ];

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
                    color: _isPowerOn
                        ? _selectedColor.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 24)),
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
                          // TODO: 发送MQTT控制命令
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isPowerOn && widget.device.isOnline) ...[
              // 亮度显示
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('亮度'),
                  Text(
                    '${_brightness.toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 亮度滑块
              Slider(
                value: _brightness,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${_brightness.toInt()}%',
                onChanged: (value) {
                  setState(() {
                    _brightness = value;
                  });
                  // TODO: 发送MQTT控制命令
                },
              ),
              const SizedBox(height: 16),

              // 颜色选择
              const Text('颜色'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                      // TODO: 发送MQTT控制命令
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.black54)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ] else if (!_isPowerOn) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.light_mode_outlined,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '灯光已关闭',
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
}

