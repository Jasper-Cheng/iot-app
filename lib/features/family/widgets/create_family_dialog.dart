import 'package:flutter/material.dart';

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
  final _avatarScrollController = ScrollController();
  String? _selectedAvatar;

  // 生成15个头像路径（avatar1.png 到 avatar15.png）
  final List<String> _avatars = List.generate(
    15,
    (index) => '/avatars/avatar${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    // 默认选择第一个头像
    _selectedAvatar = _avatars[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _avatarScrollController.dispose();
    super.dispose();
  }

  /// 滚动到选中的头像（居中显示）
  void _scrollToSelectedAvatar(int index) {
    if (!_avatarScrollController.hasClients) return;

    // 头像宽度 + 右边距
    const itemWidth = 48.0 + 12.0;
    // 列表容器的宽度（假设为可用宽度）
    final viewportWidth = _avatarScrollController.position.viewportDimension;
    // 计算目标位置：让选中的头像居中
    final targetOffset = (index * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);

    _avatarScrollController.animateTo(
      targetOffset.clamp(0.0, _avatarScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
                _buildAvatarSelector(theme, isDark),
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

  /// 构建头像选择器
  Widget _buildAvatarSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '家庭头像',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            controller: _avatarScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatarPath = _avatars[index];
              final isSelected = _selectedAvatar == avatarPath;
              final assetPath = 'assets${avatarPath}';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatarPath;
                  });
                  // 滚动到选中的头像
                  _scrollToSelectedAvatar(index);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: isSelected ? 3 : 0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

