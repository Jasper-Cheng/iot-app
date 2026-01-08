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
  
  /// 初始选中的头像路径（assets路径，如 'assets/avatars/person/avatar1.png'）
  /// 或者服务器路径（如 '/avatars/person/avatar1.png' 或 '/avatars/family/avatar1.png'），会自动转换
  final String? initialAvatar;
  
  /// 选中头像时的回调，返回assets路径（如 'assets/avatars/person/avatar1.png'）
  final ValueChanged<String>? onAvatarSelected;
  
  /// 列表高度（默认60）
  final double listHeight;
  
  /// 头像间距（默认12）
  final double spacing;

  /// 单个头像容器的内边距（默认0）
  /// 对应外层 `Container` 的 `padding: EdgeInsets.all(avatarPadding)`
  final double avatarPadding;

  /// 资源子目录（默认 'person'，可选 'person' 或 'family'）
  /// 实际路径为 assets/avatars/{subDirectory}/avatar1.png
  final String subDirectory;

  /// 文件名前缀（默认 'avatar'，生成 avatar1.png, avatar2.png...）
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
    this.subDirectory = 'person',
    this.fileNamePrefix = 'avatar',
    this.avatarPadding = 0,
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
    
    // 生成头像列表（路径格式：assets/avatars/{subDirectory}/avatar1.png）
    _avatars = List.generate(
      widget.avatarCount,
      (index) => 'assets/avatars/${widget.subDirectory}/${widget.fileNamePrefix}${index + 1}.png',
    );
    
    print('[AvatarSelector] 生成头像列表: $_avatars');

    // 处理初始选中的头像
    if (widget.initialAvatar != null) {
      _selectedAvatar = _convertToAssetPath(widget.initialAvatar!);
    }
    print('[AvatarSelector] 初始选中头像: $_selectedAvatar');
    // 如果没有初始头像，不默认选择（保持为 null）

    // 延迟滚动到选中的头像
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToSelectedAvatar();
      });
    });
  }

  /// 将路径格式转换为 assets 路径
  /// 支持的输入格式：
  /// - 服务器路径：/avatars/person/avatar1.png, /avatars/family/avatar1.png
  /// - assets 路径：assets/avatars/person/avatar1.png, assets/avatars/family/avatar1.png
  String? _convertToAssetPath(String path) {
    final expectedPrefix = 'assets/avatars/${widget.subDirectory}/';
    
    // 如果已经是正确的 assets 路径格式（assets/avatars/{subDirectory}/avatarX.png）
    if (path.startsWith(expectedPrefix)) {
      return path;
    }
    
    // 处理服务器路径：/avatars/person/avatar1.png 或 /avatars/family/avatar1.png
    if (path.startsWith('/avatars/person/')) {
      final fileName = path.replaceFirst('/avatars/person/', '');
      return 'assets/avatars/person/$fileName';
    } else if (path.startsWith('/avatars/family/')) {
      final fileName = path.replaceFirst('/avatars/family/', '');
      return 'assets/avatars/family/$fileName';
    }
    
    // 如果路径已经是 assets/avatars/ 开头但子目录不匹配，提取文件名并根据当前 subDirectory 转换
    if (path.startsWith('assets/avatars/')) {
      // 提取文件名（去掉 assets/avatars/ 和子目录部分）
      // 格式：assets/avatars/{subDir}/filename.png
      final parts = path.split('/');
      if (parts.length >= 4) {
        // 从第 4 个元素开始是文件名（可能包含子路径，但头像文件通常只有一层）
        final fileName = parts.last;
        return 'assets/avatars/${widget.subDirectory}/$fileName';
      }
    }
    
    // 其他格式不支持，返回 null
    return null;
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
                  padding: EdgeInsets.all(widget.avatarPadding),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: isSelected ? 3 : 0,
                    ),
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

