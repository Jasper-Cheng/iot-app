import 'package:flutter/material.dart';
import '../../../data/models/family.dart';
import '../../../data/models/user.dart';
import '../../../core/utils/date_utils.dart';

/// 家庭成员列表项
class FamilyMemberItem extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final bool isCurrentUser;

  const FamilyMemberItem({
    super.key,
    required this.member,
    this.onEdit,
    this.onRemove,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final account = member.account;
    final isCreator = member.role == 'creator' || member.role == 'owner';
    final displayName = member.nickname ?? account.nickname;
    
    // 性别显示文本
    String getGenderText() {
      switch (account.gender) {
        case 'male':
          return '男';
        case 'female':
          return '女';
        case 'other':
          return '其他';
        default:
          return '未设置';
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧头像（垂直居中）
            _buildMemberAvatar(context, account.avatar, displayName),
            const SizedBox(width: 12),
            // 右侧信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 用户名和创建者标签、编辑按钮
                  Row(
                    children: [
                      Expanded(
                        child: Row(
          children: [
            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 14,
                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
                            if (onEdit != null) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: onEdit,
                                child: Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                              ),
                            ],
                            if (isCreator) ...[
                              const SizedBox(width: 6),
                              Text(
                                '（创建者）',
                  style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                              ),
                            ],
                          ],
                ),
              ),
                      // "我"标识显示在中间
                      if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                            '我',
                  style: TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                      // 移除按钮显示在最右边（创建者可以移除其他成员）
                      if (onRemove != null && !isCurrentUser) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onRemove,
                          child: Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
            ],
          ],
        ),
                  const SizedBox(height: 8),
                  // 账户昵称
                  _buildInfoRow(context, '账户昵称', account.nickname),
                  const SizedBox(height: 4),
                  // 性别和手机号一行显示
                  Row(
          children: [
                      _buildInfoRow(context, '性别', getGenderText()),
                      const SizedBox(width: 12),
                      _buildInfoRow(context, '手机', account.phone),
                    ],
                  ),
                  // 邮箱（如果有）
                  if (account.email != null && account.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
                    _buildInfoRow(context, '邮箱', account.email!),
                  ],
                  // 加入时间
                  if (member.joinedAt != null) ...[
            const SizedBox(height: 4),
                    _buildInfoRow(
                      context,
                      '加入时间',
                      AppDateUtils.formatDateTime(member.joinedAt!, format: 'yyyy-MM-dd HH:mm'),
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

  /// 构建信息行
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
      ),
    );
  }

  /// 构建成员头像
  Widget _buildMemberAvatar(BuildContext context, String? avatarPath, String nickname) {
    final defaultChild = Text(
      nickname.isNotEmpty 
          ? nickname[0].toUpperCase() 
          : 'U',
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[700]
        : Colors.grey[300];

    // 如果没有头像路径，直接显示背景和首字母
    if (avatarPath == null || avatarPath.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: backgroundColor,
        child: defaultChild,
      );
    }

    // 如果有头像路径，尝试加载图片，失败时显示背景和首字母
    Widget avatarWidget;

    // 如果是完整的 URL（http/https），使用 NetworkImage
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      avatarWidget = ClipOval(
        child: Image.network(
          avatarPath,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 网络图片加载失败时显示背景和首字母
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: defaultChild),
            );
          },
        ),
      );
    }
    // 如果是相对路径 /avatars/avatarX.png，转换为 assets/avatars/avatarX.png
    else if (avatarPath.startsWith('/avatars/')) {
      final fileName = avatarPath.replaceFirst('/avatars/', '');
      final assetPath = 'assets/avatars/$fileName';
      
      avatarWidget = ClipOval(
        child: Image.asset(
          assetPath,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // assets 图片加载失败时显示背景和首字母
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: defaultChild),
            );
          },
        ),
      );
    }
    // 其他情况，显示背景和首字母
    else {
      avatarWidget = CircleAvatar(
        radius: 24,
        backgroundColor: backgroundColor,
        child: defaultChild,
      );
    }

    return avatarWidget;
  }
}

