import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/device.dart';
import '../../../app/theme/colors.dart';

/// 设备详情页面
class DeviceDetailScreen extends ConsumerWidget {
  final Device device;

  const DeviceDetailScreen({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 设备状态卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 设备图标
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        device.deviceIcon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 设备名称
                  Text(
                    device.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 设备类型
                  Text(
                    device.deviceName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 状态指示器
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 设备信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '设备信息',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    '序列号',
                    device.sn,
                    Icons.qr_code,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    '设备型号',
                    device.modelCode,
                    Icons.category_outlined,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    '设备类型',
                    device.deviceName,
                    Icons.devices_outlined,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    '绑定时间',
                    _formatDateTime(device.createdAt),
                    Icons.access_time,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 控制面板（占位）
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '设备控制',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.settings_remote_outlined,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '控制面板即将推出',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 打开设置
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('设置'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 查看日志
                  },
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('日志'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (device.status) {
      case 'online':
        return AppColors.statusOnline;
      case 'offline':
        return AppColors.statusOffline;
      case 'fatal':
        return AppColors.statusFatal;
      case 'bound':
        return AppColors.statusBound;
      default:
        return AppColors.statusUnbound;
    }
  }

  String _getStatusText() {
    switch (device.status) {
      case 'online':
        return '在线';
      case 'offline':
        return '离线';
      case 'fatal':
        return '故障';
      case 'bound':
        return '已绑定';
      case 'unbound':
        return '未绑定';
      default:
        return '未知';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享设备'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 分享设备
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              title: const Text('刷新状态'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 刷新设备状态
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outlined),
              title: const Text('关于设备'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 显示设备详细信息
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link_off_outlined, color: AppColors.danger),
              title: const Text('解绑设备', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 解绑设备
              },
            ),
          ],
        ),
      ),
    );
  }
}

