import 'package:flutter/material.dart';
import '../../../data/models/family.dart';

/// 家庭成员列表项
class FamilyMemberItem extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const FamilyMemberItem({
    super.key,
    required this.member,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.account.avatar != null
              ? NetworkImage(member.account.avatar!)
              : null,
          child: member.account.avatar == null
              ? Text(
                  member.nickname.isNotEmpty 
                      ? member.nickname[0].toUpperCase() 
                      : 'U',
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              member.nickname,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (member.role == 'owner') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '所有者',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ] else if (member.role == 'admin') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '管理员',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('账号: ${member.account.phone}'),
            const SizedBox(height: 4),
            Text(
              '加入时间: ${member.joinedAt != null ? _formatDate(member.joinedAt!) : '未知'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: member.role != 'owner'
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) {
                    onEdit!();
                  } else if (value == 'remove' && onRemove != null) {
                    onRemove!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('编辑昵称'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          '移除成员',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

