import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_selector.dart';

/// 创建家庭对话框
class CreateFamilyDialog extends StatefulWidget {
  const CreateFamilyDialog({super.key});

  @override
  State<CreateFamilyDialog> createState() => _CreateFamilyDialogState();
}

class _CreateFamilyDialogState extends State<CreateFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    // 默认选择第一个头像（转换为服务器路径）
    _selectedAvatar = '/avatars/avatar1.png';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '创建家庭',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 家庭头像选择
                AvatarSelector(
                  title: '家庭头像',
                  avatarCount: 20,
                  avatarSize: 48,
                  listHeight: 48,
                  spacing: 6,
                  onAvatarSelected: (avatarPath) {
                    // 将assets路径转换为服务器路径
                    final fileName = avatarPath.replaceFirst('assets/avatars/', '');
                    _selectedAvatar = '/avatars/$fileName';
                  },
                ),
                const SizedBox(height: 24),

                // 家庭名称输入
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '家庭名称 *',
                    hintText: '请输入家庭名称',
                    labelStyle: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    hintStyle: TextStyle(
                      color: theme.hintColor.withValues(alpha: 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入家庭名称';
                    }
                    if (value.length < 2) {
                      return '家庭名称至少2个字符';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 20),

                // 家庭描述输入
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '家庭描述',
                    hintText: '请输入家庭描述 (可选)',
                    labelStyle: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    hintStyle: TextStyle(
                      color: theme.hintColor.withValues(alpha: 0.5),
                    ),
                  ),
                  maxLines: 3,
                  maxLength: 100,
                ),
                const SizedBox(height: 24),

                // 按钮栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'name': _nameController.text,
                            'avatar': _selectedAvatar,
                            'description': _descriptionController.text.isEmpty
                                ? null
                                : _descriptionController.text,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('创建'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

