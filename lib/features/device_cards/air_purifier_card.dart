import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 空气净化器设备卡片
class AirPurifierCard extends StatefulWidget {
  final Device device;

  const AirPurifierCard({
    super.key,
    required this.device,
  });

  @override
  State<AirPurifierCard> createState() => _AirPurifierCardState();
}

class _AirPurifierCardState extends State<AirPurifierCard> {
  bool _isPowerOn = true;
  int _pm25 = 25;
  int _fanSpeed = 2; // 1-4
  String _mode = 'auto'; // auto, sleep, manual

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
                    color: _getAirQualityColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('💨', style: TextStyle(fontSize: 24)),
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
                        widget.device.isOnline ? '运行中' : '离线',
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
              // PM2.5 显示
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getAirQualityColor().withValues(alpha: 0.1),
                    border: Border.all(
                      color: _getAirQualityColor(),
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_pm25',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getAirQualityColor(),
                        ),
                      ),
                      const Text(
                        'PM2.5',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getAirQualityColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getAirQualityText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 模式选择
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('运行模式'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'auto', label: Text('自动')),
                      ButtonSegment(value: 'sleep', label: Text('睡眠')),
                      ButtonSegment(value: 'manual', label: Text('手动')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _mode = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_mode == 'manual') ...[
                // 风速控制
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('风速'),
                    Row(
                      children: List.generate(4, (index) {
                        final speed = index + 1;
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: IconButton(
                            icon: Icon(
                              Icons.radio_button_checked,
                              color: speed <= _fanSpeed
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _fanSpeed = speed;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pm25 = (_pm25 - 10).clamp(0, 500);
                        });
                      },
                      icon: const Icon(Icons.refresh_outlined, size: 18),
                      label: const Text('刷新'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('滤芯'),
                    ),
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
                        Icons.power_settings_new_outlined,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '净化器已关闭',
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

  Color _getAirQualityColor() {
    if (_pm25 <= 35) return AppColors.success;
    if (_pm25 <= 75) return AppColors.warning;
    return AppColors.danger;
  }

  String _getAirQualityText() {
    if (_pm25 <= 35) return '优';
    if (_pm25 <= 75) return '良';
    if (_pm25 <= 115) return '轻度污染';
    if (_pm25 <= 150) return '中度污染';
    if (_pm25 <= 250) return '重度污染';
    return '严重污染';
  }
}

