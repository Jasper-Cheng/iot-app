import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 空调设备卡片
class AirCoolerCard extends StatefulWidget {
  final Device device;

  const AirCoolerCard({
    super.key,
    required this.device,
  });

  @override
  State<AirCoolerCard> createState() => _AirCoolerCardState();
}

class _AirCoolerCardState extends State<AirCoolerCard> {
  bool _isPowerOn = false;
  double _temperature = 26.0;
  String _mode = 'cool'; // cool, heat, fan, dry

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
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('❄️', style: TextStyle(fontSize: 24)),
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
              // 温度控制
              Center(
                child: Column(
                  children: [
                    Text(
                      '${_temperature.toInt()}°C',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '目标温度',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 温度调节滑块
              Slider(
                value: _temperature,
                min: 16.0,
                max: 32.0,
                divisions: 16,
                label: '${_temperature.toInt()}°C',
                onChanged: (value) {
                  setState(() {
                    _temperature = value;
                  });
                  // TODO: 发送MQTT控制命令
                },
              ),
              const SizedBox(height: 16),

              // 模式选择
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton('制冷', Icons.ac_unit, 'cool'),
                  _buildModeButton('制热', Icons.whatshot, 'heat'),
                  _buildModeButton('送风', Icons.wind_power, 'fan'),
                  _buildModeButton('除湿', Icons.water_drop_outlined, 'dry'),
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
                        '空调已关闭',
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

  Widget _buildModeButton(String label, IconData icon, String mode) {
    final isSelected = _mode == mode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _mode = mode;
        });
        // TODO: 发送MQTT控制命令
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

