import 'package:flutter/material.dart';
import '../../../data/models/device.dart';
import '../../../core/utils/device_mapping.dart';

/// 家庭设备卡片（按照图片布局）
class FamilyDeviceCard extends StatefulWidget {
  final Device device;
  final VoidCallback? onDelete;
  final Function(String)? onUpdateName;
  final String? Function(int? accountId)? getAccountName;
  final VoidCallback? onUnbind;
  final bool isCurrentUser;

  const FamilyDeviceCard({
    super.key,
    required this.device,
    this.onDelete,
    this.onUpdateName,
    this.getAccountName,
    this.onUnbind,
    this.isCurrentUser = false,
  });

  @override
  State<FamilyDeviceCard> createState() => _FamilyDeviceCardState();
}

class _FamilyDeviceCardState extends State<FamilyDeviceCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧：图标框
            Text(
              widget.device.deviceIcon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 10),
            // 右侧：设备信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：名称和编辑图标
                  _buildNameRow(context, widget.device.name),
                  const SizedBox(height: 4),
                  // 第二行：序列号
                  _buildDetailRow(context, '序列号', widget.device.sn),
                  const SizedBox(height: 4),
                  // 第三行：来自和状态
                  Row(
                    children: [
                      // 来自
                      Expanded(
                        child: _buildDetailRow(
                          context,
                          '来自',
                          _getAccountDisplayName(),
                        ),
                      ),
                      // 状态
                      Expanded(
                        child: _buildStatusRow(context, statusColor, statusText),
                      ),
                    ],
                  ),
                  // 第四行：解绑按钮和移除按钮
                  if (widget.onDelete != null || (widget.isCurrentUser && widget.onUnbind != null)) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 解绑按钮
                        if (widget.isCurrentUser && widget.onUnbind != null)
                          OutlinedButton.icon(
                            onPressed: widget.onUnbind,
                            icon: const Icon(Icons.link_off, size: 16,color: Colors.red),
                            label: const Text('解绑该设备', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        // 移除按钮
                        if (widget.onDelete != null) ...[
                          if (widget.isCurrentUser && widget.onUnbind != null) const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: widget.onDelete,
                            icon: const Icon(Icons.remove_circle_outline, size: 16,color: Colors.orange),
                            label: const Text('从家庭移除', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: Colors.orange),
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建名称行（带编辑图标）
  Widget _buildNameRow(BuildContext context, String name) {
    return Row(
      children: [
        Text(
          '名称:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
        ),
        if (widget.onUpdateName != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showEditNameDialog(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.edit_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建详情行（左右排列）
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建状态行（左右排列）
  Widget _buildStatusRow(BuildContext context, Color statusColor, String statusText) {
    return Row(
      children: [
        Text(
          '状态:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 11,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.device.status) {
      case 'online':
        return Colors.blue;
      case 'offline':
        return Colors.grey;
      case 'fatal':
        return Colors.red;
      case 'bound':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.device.status) {
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

  /// 获取账户显示名称
  String _getAccountDisplayName() {
    if (widget.device.accountId == null) {
      return '未知';
    }
    
    if (widget.getAccountName != null) {
      final accountName = widget.getAccountName!(widget.device.accountId);
      return accountName ?? '未知';
    }
    
    // 如果没有提供查找函数，回退到显示 accountId
    return '用户${widget.device.accountId}';
  }

  /// 显示编辑设备名称对话框
  void _showEditNameDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.device.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改设备名称'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '设备名称',
            hintText: '请输入设备名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != widget.device.name) {
                widget.onUpdateName?.call(newName);
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

