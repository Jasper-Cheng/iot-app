import 'package:flutter/material.dart';
import '../../data/models/device.dart';
import '../../app/theme/colors.dart';

/// 环境监测器设备卡片
class EnvironmentMonitorCard extends StatefulWidget {
  final Device device;

  const EnvironmentMonitorCard({
    super.key,
    required this.device,
  });

  @override
  State<EnvironmentMonitorCard> createState() => _EnvironmentMonitorCardState();
}

class _EnvironmentMonitorCardState extends State<EnvironmentMonitorCard> {
  double _temperature = 24.5;
  int _humidity = 60;
  int _pm25 = 28;
  int _co2 = 450;

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
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🌡️', style: TextStyle(fontSize: 24)),
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
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: widget.device.isOnline
                      ? () {
                          setState(() {
                            _temperature = 20 + (30 * (0.5 + 0.5));
                            _humidity = 40 + (60 * 0.5).toInt();
                            _pm25 = (50 * 0.5).toInt();
                            _co2 = 400 + (200 * 0.5).toInt();
                          });
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.device.isOnline) ...[
              // 主要数据显示
              Row(
                children: [
                  Expanded(
                    child: _buildMainDataCard(
                      context,
                      Icons.thermostat_outlined,
                      '温度',
                      '${_temperature.toStringAsFixed(1)}°C',
                      _getTemperatureColor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMainDataCard(
                      context,
                      Icons.water_drop_outlined,
                      '湿度',
                      '$_humidity%',
                      _getHumidityColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 次要数据显示
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryDataCard(
                      context,
                      Icons.air_outlined,
                      'PM2.5',
                      '$_pm25',
                      _getPm25Color(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryDataCard(
                      context,
                      Icons.cloud_outlined,
                      'CO₂',
                      '$_co2 ppm',
                      _getCo2Color(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 综合评价
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getOverallColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getOverallColor(),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: _getOverallColor(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '环境质量: ${_getOverallText()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getOverallColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getOverallSuggestion(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.history_outlined, size: 18),
                      label: const Text('历史数据'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.timeline_outlined, size: 18),
                      label: const Text('趋势图'),
                    ),
                  ),
                ],
              ),
            ] else ...[
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
                        '监测器离线',
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

  Widget _buildMainDataCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSecondaryDataCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor() {
    if (_temperature >= 18 && _temperature <= 26) return AppColors.success;
    if (_temperature >= 15 && _temperature <= 30) return AppColors.warning;
    return AppColors.danger;
  }

  Color _getHumidityColor() {
    if (_humidity >= 40 && _humidity <= 70) return AppColors.success;
    if (_humidity >= 30 && _humidity <= 80) return AppColors.warning;
    return AppColors.danger;
  }

  Color _getPm25Color() {
    if (_pm25 <= 35) return AppColors.success;
    if (_pm25 <= 75) return AppColors.warning;
    return AppColors.danger;
  }

  Color _getCo2Color() {
    if (_co2 <= 600) return AppColors.success;
    if (_co2 <= 1000) return AppColors.warning;
    return AppColors.danger;
  }

  Color _getOverallColor() {
    final scores = [
      _getTemperatureColor(),
      _getHumidityColor(),
      _getPm25Color(),
      _getCo2Color(),
    ];
    if (scores.every((c) => c == AppColors.success)) return AppColors.success;
    if (scores.any((c) => c == AppColors.danger)) return AppColors.warning;
    return AppColors.warning;
  }

  String _getOverallText() {
    final color = _getOverallColor();
    if (color == AppColors.success) return '优秀';
    if (color == AppColors.warning) return '良好';
    return '较差';
  }

  String _getOverallSuggestion() {
    final color = _getOverallColor();
    if (color == AppColors.success) return '环境舒适，适合居住';
    if (color == AppColors.warning) return '建议开窗通风或调节温湿度';
    return '环境质量较差，请及时改善';
  }
}

