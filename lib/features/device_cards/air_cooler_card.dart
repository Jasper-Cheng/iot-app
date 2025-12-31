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
  int _acTemp = 16;
  int _roomTemp = 20;
  String _activeMode = 'cool';
  final List<Map<String, String>> _acModes = [
    {'id': 'heat', 'name': 'Heat'},
    {'id': 'dry', 'name': 'Dry'},
    {'id': 'cool', 'name': 'Cool'},
    {'id': 'auto', 'name': 'Auto'},
  ];

  bool get _deviceOnline => widget.device.isOnline;

  Color _getTempEndColor(int temp) {
    if (temp <= 10) return const Color(0xFF1E3A8A); // 深蓝
    if (temp <= 16) return const Color(0xFF3B82F6); // 蓝
    if (temp <= 22) return const Color(0xFF10B981); // 绿
    if (temp <= 26) return const Color(0xFFF59E0B); // 橙
    if (temp <= 30) return const Color(0xFFEF4444); // 红
    return const Color(0xFFDC2626); // 深红
  }

  Color _getRoomTint() {
    if (!_isPowerOn) return Colors.transparent;
    switch (_activeMode) {
      case 'heat':
        return const Color(0x40FF6B35); // 橙色覆盖
      case 'dry':
        return const Color(0x4000A8CC); // 蓝色覆盖
      case 'cool':
        return const Color(0x4000D4FF); // 青色覆盖
      case 'auto':
        return Colors.transparent;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
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
            // 卡片头部
            _buildCardHeader(theme, isDark),
            const SizedBox(height: 18),
            // 温度区域
            _buildTemperatureSection(theme, isDark),
            const SizedBox(height: 18),
            // 模式控制
            _buildModeControls(theme, isDark),
          ],
        ),
      ),
    );
  }

  /// 构建卡片头部
  Widget _buildCardHeader(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：设备信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 设备名称
              Text(
                widget.device.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
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
                              .withValues(alpha: 0.5),
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
          ),
        ),
        // 右侧：电源开关
        _buildPowerSwitch(theme, isDark),
      ],
    );
  }

  /// 构建电源开关
  Widget _buildPowerSwitch(ThemeData theme, bool isDark) {
    final isDisabled = !_deviceOnline;
    
    return Row(
      children: [
        Text(
          _isPowerOn ? 'On' : 'Off',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              _isPowerOn = !_isPowerOn;
              if (!_isPowerOn) {
                _activeMode = 'cool';
              }
            });
          },
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              width: 32,
              height: 20,
              decoration: BoxDecoration(
                color: _isPowerOn
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _isPowerOn ? 16 : 2,
                    top: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建温度区域
  Widget _buildTemperatureSection(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // 标题行
        Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'AC Temperature',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Room Temperature',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        // 内容行
        Row(
          children: [
            // AC 温度
            Expanded(
              child: Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E3A8A),
                      _getTempEndColor(_acTemp),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_acTemp°',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            // 房间温度
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: 240,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=200&h=150&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // 颜色覆盖层
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getRoomTint(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // 温度覆盖层
                  Positioned(
                    top: 40,
                    left: 80,
                    child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_roomTemp°',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建模式控制
  Widget _buildModeControls(ThemeData theme, bool isDark) {
    return Row(
      children: _acModes.map((mode) {
        final isActive = _activeMode == mode['id'] && _isPowerOn;
        return Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isPowerOn ? () {
                  setState(() {
                    _activeMode = mode['id']!;
                  });
                } : null,
                child: Opacity(
                  opacity: _isPowerOn ? 1.0 : 0.5,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBgCard : AppColors.lightBgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isActive ? 1 : 0,
                      ),
                    ),
                    child: _buildModeIcon(mode['id']!, isActive),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                mode['name']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建模式图标
  Widget _buildModeIcon(String modeId, bool isActive) {
    final color = isActive ? AppColors.primary : AppColors.lightTextSecondary;
    
    switch (modeId) {
      case 'heat':
        return Icon(Icons.whatshot, size: 24, color: color);
      case 'dry':
        return Icon(Icons.water_drop_outlined, size: 24, color: color);
      case 'cool':
        return Icon(Icons.ac_unit, size: 24, color: color);
      case 'auto':
        return Icon(Icons.auto_mode, size: 24, color: color);
      default:
        return const SizedBox.shrink();
    }
  }
}
