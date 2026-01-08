import 'package:flutter/material.dart';

/// 头像选择器组件
/// 
/// 用于在注册、编辑个人信息、创建家庭等场景中选择头像
class AvatarSelector extends StatefulWidget {
  /// 标题文本（可选）
  final String? title;
  
  /// 头像数量（默认20个）
  final int avatarCount;
  
  /// 头像尺寸（默认48）
  final double avatarSize;
  
  /// 初始选中的头像路径（assets路径，如 'assets/avatars/avatar1.png'）
  /// 或者服务器路径（如 '/avatars/avatar1.png'），会自动转换
  final String? initialAvatar;
  
  /// 选中头像时的回调，返回assets路径（如 'assets/avatars/avatar1.png'）
  final ValueChanged<String>? onAvatarSelected;
  
  /// 列表高度（默认60）
  final double listHeight;
  
  /// 头像间距（默认12）
  final double spacing;

  /// 资源目录（默认 'avatars'）
  final String assetDirectory;

  /// 文件名前缀（默认 'avatar'，生成 avatar1.png, avatar2.png...）
  /// 对于家庭头像，使用 'avatar'，生成 avatar1.png, avatar2.png...
  final String fileNamePrefix;

  const AvatarSelector({
    super.key,
    this.title,
    this.avatarCount = 20,
    this.avatarSize = 48,
    this.initialAvatar,
    this.onAvatarSelected,
    this.listHeight = 60,
    this.spacing = 12,
    this.assetDirectory = 'avatars',
    this.fileNamePrefix = 'avatar',
  });

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  late final ScrollController _scrollController;
  String? _selectedAvatar;

  // 生成头像列表（assets路径）
  late final List<String> _avatars;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // 生成头像列表
    _avatars = List.generate(
      widget.avatarCount,
      (index) => 'assets/${widget.assetDirectory}/${widget.fileNamePrefix}${index + 1}.png',
    );

    // 处理初始选中的头像
    if (widget.initialAvatar != null) {
      // 如果是服务器路径（/avatars/avatar1.png 或 /families/avatar1.png），转换为assets路径
      final serverPathPrefix = '/${widget.assetDirectory}/';
      if (widget.initialAvatar!.startsWith(serverPathPrefix)) {
        final fileName = widget.initialAvatar!.replaceFirst(serverPathPrefix, '');
        _selectedAvatar = 'assets/${widget.assetDirectory}/$fileName';
      } else if (widget.initialAvatar!.startsWith('assets/${widget.assetDirectory}/')) {
        _selectedAvatar = widget.initialAvatar;
      } else {
        _selectedAvatar = widget.initialAvatar;
      }
    }
    // 如果没有初始头像，不默认选择（保持为 null）

    // 延迟滚动到选中的头像
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToSelectedAvatar();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动到选中的头像（居中显示）
  void _scrollToSelectedAvatar() {
    if (_selectedAvatar == null) return;
    
    final index = _avatars.indexOf(_selectedAvatar!);
    if (index == -1) return;

    if (!_scrollController.hasClients) {
      // 如果 ScrollController 还没有附加，等待下一帧
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedAvatar();
      });
      return;
    }

    // 头像宽度 + 间距
    final itemWidth = widget.avatarSize + widget.spacing;
    // 列表容器的宽度
    final viewportWidth = _scrollController.position.viewportDimension;
    // 计算目标位置：让选中的头像居中
    final targetOffset = (index * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 获取当前选中的头像路径（assets路径）
  String? get selectedAvatar => _selectedAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: widget.listHeight,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatarPath = _avatars[index];
              final isSelected = _selectedAvatar == avatarPath;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatarPath;
                  });
                  // 滚动到选中的头像
                  _scrollToSelectedAvatar();
                  // 触发回调
                  widget.onAvatarSelected?.call(avatarPath);
                },
                child: Container(
                  width: widget.avatarSize,
                  height: widget.avatarSize,
                  margin: EdgeInsets.only(right: widget.spacing),
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
                      avatarPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            size: widget.avatarSize * 0.5,
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

