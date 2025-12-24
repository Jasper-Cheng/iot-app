import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 扫地机器人设备卡片
class VacuumCard extends StatefulWidget {
  final Device device;

  const VacuumCard({
    super.key,
    required this.device,
  });

  @override
  State<VacuumCard> createState() => _VacuumCardState();
}

class _VacuumCardState extends State<VacuumCard> {
  String _status = 'charging'; // idle, cleaning, charging, paused
  int _battery = 85;
  int _cleanedArea = 45; // 平方米
  String _cleanTime = '00:32';
  int _fanSpeed = 2; // 1-3

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
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 24)),
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
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 电池电量
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBatteryColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.battery_charging_full,
                        size: 16,
                        color: _getBatteryColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_battery%',
                        style: TextStyle(
                          color: _getBatteryColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.device.isOnline) ...[
              // 清扫数据
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      Icons.square_foot,
                      '清扫面积',
                      '$_cleanedArea m²',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      Icons.access_time,
                      '清扫时间',
                      _cleanTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 风速控制
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('吸力'),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('静音')),
                      ButtonSegment(value: 2, label: Text('标准')),
                      ButtonSegment(value: 3, label: Text('强力')),
                    ],
                    selected: {_fanSpeed},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _fanSpeed = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 控制按钮
              if (_status == 'cleaning') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _status = 'paused';
                          });
                        },
                        icon: const Icon(Icons.pause),
                        label: const Text('暂停'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _status = 'charging';
                          });
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('回充'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_status == 'paused') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _status = 'cleaning';
                          });
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('继续'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _status = 'charging';
                          });
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('回充'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _status = 'cleaning';
                      });
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始清扫'),
                  ),
                ),
              ],
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.power_off,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '机器人离线',
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

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'cleaning':
        return AppColors.info;
      case 'charging':
        return AppColors.success;
      case 'paused':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case 'cleaning':
        return '清扫中';
      case 'charging':
        return '充电中';
      case 'paused':
        return '已暂停';
      default:
        return '待机';
    }
  }

  Color _getBatteryColor() {
    if (_battery > 50) return AppColors.success;
    if (_battery > 20) return AppColors.warning;
    return AppColors.danger;
  }
}

