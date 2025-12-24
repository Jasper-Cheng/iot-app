import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 跌倒检测器设备卡片
class FallDetectionCard extends StatefulWidget {
  final Device device;

  const FallDetectionCard({
    super.key,
    required this.device,
  });

  @override
  State<FallDetectionCard> createState() => _FallDetectionCardState();
}

class _FallDetectionCardState extends State<FallDetectionCard> {
  bool _isEnabled = true;
  int _sensitivity = 3; // 1-5
  bool _hasAlert = false;
  String _lastCheckTime = '10分钟前';

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
                    color: _hasAlert
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🚨', style: TextStyle(fontSize: 24)),
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
                            widget.device.isOnline ? '监测中' : '离线',
                            style: TextStyle(
                              color: widget.device.isOnline
                                  ? AppColors.statusOnline
                                  : AppColors.statusOffline,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: widget.device.isOnline
                      ? (value) {
                          setState(() {
                            _isEnabled = value;
                          });
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isEnabled && widget.device.isOnline) ...[
              // 状态显示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasAlert
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasAlert ? AppColors.danger : AppColors.success,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hasAlert ? Icons.warning : Icons.check_circle,
                      size: 48,
                      color: _hasAlert ? AppColors.danger : AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasAlert ? '检测到跌倒！' : '运行正常',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _hasAlert ? AppColors.danger : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '最后检查: $_lastCheckTime',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 灵敏度设置
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('检测灵敏度'),
                  Row(
                    children: [
                      Text('$_sensitivity'),
                      const SizedBox(width: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('低')),
                          ButtonSegment(value: 3, label: Text('中')),
                          ButtonSegment(value: 5, label: Text('高')),
                        ],
                        selected: {_sensitivity},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() {
                            _sensitivity = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 操作按钮
              if (_hasAlert)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasAlert = false;
                      });
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('确认已处理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasAlert = true;
                      });
                    },
                    icon: const Icon(Icons.history_outlined),
                    label: const Text('查看历史记录'),
                  ),
                ),
            ] else if (!_isEnabled) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sensors_off_outlined,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '检测已关闭',
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

