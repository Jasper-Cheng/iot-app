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
  // 模拟传感器数据
  final Map<String, dynamic> _sensors = {
    'co2': 517,
    'hcho': 12,
    'tvoc': 19,
    'pm25': 20,
    'pm10': 24,
    'temp': 26.1,
    'humi': 40.1,
  };

  bool get _deviceOnline => widget.device.isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.darkBgCard : AppColors.lightBgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, isDark),
            const SizedBox(height: 16),
            _buildEnvironmentStatusSection(theme, isDark),
          ],
        ),
      ),
    );
  }

  /// 构建卡片头部
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 设备名称（带图标）
        Row(
          children: [
            Text(
              widget.device.deviceIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              widget.device.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 连接状态
        Row(
          children: [
            // 状态指示器
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _deviceOnline ? AppColors.statusOnline : AppColors.danger,
                boxShadow: [
                  BoxShadow(
                    color: (_deviceOnline ? AppColors.statusOnline : AppColors.danger)
                        .withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // 状态文本
            Text(
              _deviceOnline ? '在线' : '离线',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            // 设备SN
            if (widget.device.sn.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                widget.device.sn,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 构建环境状态区域
  Widget _buildEnvironmentStatusSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 环境摘要
        _buildEnvironmentSummary(theme, isDark),
        const SizedBox(height: 16),
        // 传感器网格
        _buildSensorsGrid(theme, isDark),
      ],
    );
  }

  /// 构建环境摘要
  Widget _buildEnvironmentSummary(ThemeData theme, bool isDark) {
    final pm25 = _sensors['pm25'] as int;
    final airQualityLevel = _getAirQualityLevel(pm25);
    final airQualityText = _getAirQualityText(pm25);
    final co2 = _sensors['co2'] as int;
    final tvoc = _sensors['tvoc'] as int;

    return Row(
      children: [
        // PM2.5 圆形显示
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getAirQualityColor(airQualityLevel, isDark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$pm25',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: _getAirQualityTextColor(airQualityLevel, isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PM2.5',
                style: TextStyle(
                  fontSize: 10,
                  color: _getAirQualityTextColor(airQualityLevel, isDark)
                      .withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 空气质量文本
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                airQualityText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'CO₂ $co2 ppm · TVOC $tvoc ppb',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建传感器网格
  Widget _buildSensorsGrid(ThemeData theme, bool isDark) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildSensorItem(
          icon: Icons.layers_outlined,
          label: 'CO₂',
          value: '${_sensors['co2']} ppm',
          theme: theme,
          isDark: isDark,
        ),
        _buildSensorItem(
          icon: Icons.water_drop_outlined,
          label: '甲醛',
          value: '${_sensors['hcho']} mg/m³',
          theme: theme,
          isDark: isDark,
        ),
        _buildSensorItem(
          icon: Icons.air_outlined,
          label: 'TVOC',
          value: '${_sensors['tvoc']} ppb',
          theme: theme,
          isDark: isDark,
        ),
        _buildSensorItem(
          icon: Icons.wb_sunny_outlined,
          label: 'PM2.5',
          value: '${_sensors['pm25']} μg/m³',
          theme: theme,
          isDark: isDark,
        ),
        _buildSensorItem(
          icon: Icons.cloud_outlined,
          label: 'PM10',
          value: '${_sensors['pm10']} μg/m³',
          theme: theme,
          isDark: isDark,
        ),
        _buildSensorItem(
          icon: Icons.thermostat_outlined,
          label: '温度',
          value: '${(_sensors['temp'] as double).toStringAsFixed(1)} °C',
          theme: theme,
          isDark: isDark,
        ),
        _buildSensorItem(
          icon: Icons.opacity_outlined,
          label: '湿度',
          value: '${(_sensors['humi'] as double).toStringAsFixed(1)} %',
          theme: theme,
          isDark: isDark,
        ),
      ],
    );
  }

  /// 构建传感器项
  Widget _buildSensorItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgPrimary : AppColors.lightBgSecondary,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标和标签一行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 数值单独一行
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 获取空气质量等级
  String _getAirQualityLevel(int pm25) {
    if (pm25 <= 35) return 'good';
    if (pm25 <= 75) return 'moderate';
    if (pm25 <= 115) return 'unhealthy';
    return 'very-bad';
  }

  /// 获取空气质量文本
  String _getAirQualityText(int pm25) {
    if (pm25 <= 35) return '空气优';
    if (pm25 <= 75) return '良 · 建议通风';
    if (pm25 <= 115) return '轻度污染 · 建议净化';
    return '重度污染 · 建议强力净化';
  }

  /// 获取空气质量颜色
  Color _getAirQualityColor(String level, bool isDark) {
    switch (level) {
      case 'good':
        return AppColors.success; // 绿色
      case 'moderate':
        return AppColors.warning; // 黄色
      case 'unhealthy':
        return const Color(0xFFFF9800); // 橙色
      case 'very-bad':
        return AppColors.danger; // 红色
      default:
        return isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary;
    }
  }

  /// 获取空气质量文本颜色
  Color _getAirQualityTextColor(String level, bool isDark) {
    // 对于 good, moderate, unhealthy, very-bad，使用白色文字
    if (level == 'good' || level == 'moderate' || level == 'unhealthy' || level == 'very-bad') {
      return Colors.white;
    }
    return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  }
}
