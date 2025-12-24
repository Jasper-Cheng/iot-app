import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 洗衣机设备卡片
class WashingMachineCard extends StatefulWidget {
  final Device device;

  const WashingMachineCard({
    super.key,
    required this.device,
  });

  @override
  State<WashingMachineCard> createState() => _WashingMachineCardState();
}

class _WashingMachineCardState extends State<WashingMachineCard> {
  String _status = 'idle'; // idle, washing, rinsing, spinning, completed
  String _mode = 'standard'; // quick, standard, delicate, heavy
  int _remainingTime = 45; // 分钟
  int _progress = 0; // 0-100

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
                  child: const Text('🧺', style: TextStyle(fontSize: 24)),
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
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_status != 'idle' && _status != 'completed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '剩余 $_remainingTime 分钟',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.device.isOnline) ...[
              if (_status != 'idle' && _status != 'completed') ...[
                // 进度显示
                Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _progress / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_progress%',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getStepText(),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 控制按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _status = 'idle';
                            _progress = 0;
                          });
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text('停止'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.timer_outlined),
                        label: const Text('预约'),
                      ),
                    ),
                  ],
                ),
              ] else if (_status == 'completed') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '洗涤完成',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('请取出衣物'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _status = 'idle';
                      });
                    },
                    child: const Text('确认'),
                  ),
                ),
              ] else ...[
                // 模式选择
                const Text('洗涤模式'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildModeChip('快洗', 'quick', '15分钟'),
                    _buildModeChip('标准', 'standard', '45分钟'),
                    _buildModeChip('轻柔', 'delicate', '60分钟'),
                    _buildModeChip('强力', 'heavy', '90分钟'),
                  ],
                ),
                const SizedBox(height: 20),

                // 开始按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _status = 'washing';
                        _progress = 0;
                      });
                      // 模拟进度
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() => _progress = 30);
                          _status = 'rinsing';
                        }
                      });
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始洗涤'),
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
                        '洗衣机离线',
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

  Widget _buildModeChip(String label, String mode, String time) {
    final isSelected = _mode == mode;
    return FilterChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(time, style: const TextStyle(fontSize: 10)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _mode = mode;
            _remainingTime = int.parse(time.replaceAll('分钟', ''));
          });
        }
      },
    );
  }

  Color _getStatusColor() {
    if (!widget.device.isOnline) return AppColors.statusOffline;
    switch (_status) {
      case 'washing':
      case 'rinsing':
      case 'spinning':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    if (!widget.device.isOnline) return '离线';
    switch (_status) {
      case 'washing':
        return '洗涤中';
      case 'rinsing':
        return '漂洗中';
      case 'spinning':
        return '甩干中';
      case 'completed':
        return '已完成';
      default:
        return '待机';
    }
  }

  String _getStepText() {
    switch (_status) {
      case 'washing':
        return '洗涤';
      case 'rinsing':
        return '漂洗';
      case 'spinning':
        return '甩干';
      default:
        return '';
    }
  }
}

