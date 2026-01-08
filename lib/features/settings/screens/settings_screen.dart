import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../app/routes/router.dart';
import '../../../data/repositories/checkin_repository.dart';
import '../../../data/models/user.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/widgets/avatar_selector.dart';

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _pointsBalance;
  bool _isLoadingPoints = false;

  @override
  void initState() {
    super.initState();
    _loadPointsBalance();
  }

  Future<void> _loadPointsBalance() async {
    setState(() {
      _isLoadingPoints = true;
    });
    try {
      final repository = CheckinRepository();
      final balance = await repository.getPointsBalance();
      if (mounted) {
        setState(() {
          _pointsBalance = balance;
          _isLoadingPoints = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
        });
      }
    }
  }

  String _getGenderText(String? gender) {
    switch (gender) {
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

  /// 构建头像 Widget
  Widget _buildAvatar(String? avatarPath, String nickname, ThemeData theme) {
    // 默认头像图片
    final defaultAvatar = ClipOval(
      child: Image.asset(
        'assets/no-avatar.png',
        fit: BoxFit.cover,
        width: 64,
        height: 64,
        errorBuilder: (context, error, stackTrace) {
          // 如果 no-avatar.png 也加载失败，显示首字母
          final defaultChild = Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            child: Text(
              nickname.isNotEmpty ? nickname[0] : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          return defaultChild;
        },
      ),
    );

    // 如果头像路径为空，显示默认头像
    if (avatarPath == null || avatarPath.isEmpty) {
      return defaultAvatar;
    }

    // 如果是完整的 URL（http/https），使用 NetworkImage
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          avatarPath,
          fit: BoxFit.cover,
          width: 64,
          height: 64,
          errorBuilder: (context, error, stackTrace) {
            // 网络图片加载失败，显示默认头像
            return ClipOval(
              child: Image.asset(
                'assets/no-avatar.png',
                fit: BoxFit.cover,
                width: 64,
                height: 64,
              ),
            );
          },
        ),
      );
    }

    // 如果是相对路径 /avatars/avatarX.png，转换为 assets/avatars/avatarX.png
    if (avatarPath.startsWith('/avatars/')) {
      final fileName = avatarPath.replaceFirst('/avatars/', '');
      final assetPath = 'assets/avatars/$fileName';
      
      return ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: 64,
          height: 64,
          errorBuilder: (context, error, stackTrace) {
            // assets 图片加载失败，显示默认头像
            return ClipOval(
              child: Image.asset(
                'assets/no-avatar.png',
                fit: BoxFit.cover,
                width: 64,
                height: 64,
              ),
            );
          },
        ),
      );
    }

    // 其他情况，显示默认头像
    return defaultAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('设置'),
      ),
      body: ListView(
        key: const PageStorageKey<String>('settings_list'),
        children: [
          // 用户信息卡片
          if (authState.account != null)
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 头像
                        _buildAvatar(
                          authState.account!.avatar,
                          authState.account!.nickname,
                          theme,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 用户名和积分
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      authState.account!.nickname,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 积分
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_outlined,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      _isLoadingPoints
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  theme.colorScheme.primary,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              _pointsBalance != null
                                                  ? '${_pointsBalance} 积分'
                                                  : '加载中...',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 邮箱
                              if (authState.account!.email != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: theme.hintColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        authState.account!.email!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.hintColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (authState.account!.email != null)
                                const SizedBox(height: 4),
                              // 手机号
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: theme.hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    authState.account!.phone,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // 性别
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outlined,
                                    size: 16,
                                    color: theme.hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getGenderText(authState.account!.gender),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            _showEditProfileDialog(context, ref);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 主题设置
          _buildSection(
            context,
            '外观设置',
            [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('主题模式'),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                trailing: Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final iconColor = isDark ? Colors.white : Colors.black;
                    
                    return SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        side: BorderSide(
                          width: 0.5,
                          color: Theme.of(context).dividerColor,
                        ),
                        visualDensity: VisualDensity.comfortable,
                      ),
                      segments: [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          icon: SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: Icon(Icons.light_mode_outlined, size: 14, color: iconColor),
                            ),
                          ),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          icon: SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: Icon(Icons.dark_mode_outlined, size: 14, color: iconColor),
                            ),
                          ),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          icon: SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: Icon(Icons.brightness_auto_outlined, size: 14, color: iconColor),
                            ),
                          ),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(newSelection.first);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // 签到与积分
          _buildSection(
            context,
            '签到与积分',
            [
              _buildItem(
                icon: Icons.calendar_today_outlined,
                text: '每日签到',
                onTap: () async {
                  // 跳转到签到页面，等待返回后刷新积分
                  await context.push(AppRouter.checkin);
                  // 从签到页面返回后刷新积分
                  _loadPointsBalance();
                },
              ),
              _buildItem(
                icon: Icons.history_outlined,
                text: '积分记录',
                onTap: () => context.push(AppRouter.pointsHistory),
              ),
            ],
          ),

          // 帮助与反馈
          _buildSection(
            context,
            '帮助与反馈',
            [
              _buildItem(
                icon: Icons.feedback_outlined,
                text: '意见反馈',
                onTap: () => context.push(AppRouter.feedback),
              ),
              _buildItem(
                icon: Icons.list_outlined,
                text: '反馈列表',
                onTap: () => context.push(AppRouter.feedbackList),
              ),
              _buildItem(
                icon: Icons.support_agent_outlined,
                text: '联系客服',
                onTap: () => context.push(AppRouter.customerService),
              ),
              _buildItem(
                icon: Icons.info_outlined,
                text: '关于我们',
                onTap: () => context.push(AppRouter.about),
              ),
            ],
          ),

          // 账户管理
          _buildSection(
            context,
            '账户管理',
            [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteAccountDialog(context, ref),
                        icon: const Icon(Icons.delete_outline, size: 18,color: Colors.red),
                        label: const Text('注销账号', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context, ref),
                        icon: const Icon(Icons.logout_outlined, size: 18),
                        label: const Text('退出登录'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final account = ref.read(authProvider).account;
    if (account == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditProfileDialog(
        account: account,
        onUpdate: () {
          // 更新后刷新积分
          _loadPointsBalance();
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final logoutResult = await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
                // 显示登出结果提示
                Fluttertoast.showToast(
                  msg: logoutResult.message,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: logoutResult.success ? Colors.green : Colors.red,
                  textColor: Colors.white,
                );
                // 登出成功后，跳转到登录页
                if (logoutResult.success) {
                  context.go(AppRouter.login);
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注销账号'),
        content: const Text('注销账号后，所有数据将被永久删除且无法恢复。确定要注销账号吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // 关闭第一个对话框
              Navigator.pop(context);
              // 显示二次确认对话框
              _showDeleteAccountConfirmDialog(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定注销'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('再次确认'),
        content: const Text('请再次确认，注销账号后所有数据将永久删除且无法恢复。此操作不可撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final deleteResult = await ref.read(authProvider.notifier).deleteAccount();
              if (context.mounted) {
                Navigator.pop(context);
                // 显示注销结果提示
                Fluttertoast.showToast(
                  msg: deleteResult.message,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: deleteResult.success ? Colors.green : Colors.red,
                  textColor: Colors.white,
                );
                // 注销成功后，跳转到登录页
                if (deleteResult.success) {
                  context.go(AppRouter.login);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
  }
}

/// 编辑用户信息弹窗
class _EditProfileDialog extends ConsumerStatefulWidget {
  final Account account;
  final VoidCallback onUpdate;

  const _EditProfileDialog({
    required this.account,
    required this.onUpdate,
  });

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String? _selectedGender;
  String? _selectedAvatar;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.account.nickname);
    _emailController = TextEditingController(text: widget.account.email ?? '');
    _phoneController = TextEditingController(text: widget.account.phone);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _selectedGender = widget.account.gender;
    
    // 将头像路径转换为 assets 路径（用于AvatarSelector）
    if (widget.account.avatar != null && widget.account.avatar!.startsWith('/avatars/')) {
      final fileName = widget.account.avatar!.replaceFirst('/avatars/', '');
      _selectedAvatar = 'assets/avatars/$fileName';
    } else if (widget.account.avatar != null && widget.account.avatar!.startsWith('assets/')) {
      _selectedAvatar = widget.account.avatar;
    }
    // 如果用户没有头像，不设置默认值，让用户自己选择
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getGenderText(String? gender) {
    switch (gender) {
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

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 验证密码
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text.length < 6) {
        Fluttertoast.showToast(
          msg: '密码至少6位',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        Fluttertoast.showToast(
          msg: '两次密码输入不一致',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    // 转换头像路径
    String? avatarPath;
    if (_selectedAvatar != null) {
      final fileName = _selectedAvatar!.replaceFirst('assets/avatars/', '');
      avatarPath = '/avatars/$fileName';
    }

    final updateResult = await ref.read(authProvider.notifier).updateUserProfile(
          nickname: _nicknameController.text.trim(),
          phone: _phoneController.text.trim(),
          gender: _selectedGender ?? 'other', // 如果为 null，默认设置为 'other'
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          avatar: avatarPath,
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
        );

    if (mounted) {
      if (updateResult.success) {
        widget.onUpdate();
        Navigator.pop(context);
      }
      Fluttertoast.showToast(
        msg: updateResult.message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: updateResult.success ? Colors.green : Colors.red,
        textColor: Colors.white,
      );
    }
    
    if (mounted) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像选择器
              AvatarSelector(
                title: '选择头像',
                avatarCount: 20,
                avatarSize: 50,
                listHeight: 50,
                spacing: 6,
                initialAvatar: widget.account.avatar,
                onAvatarSelected: (avatarPath) {
                  setState(() {
                    _selectedAvatar = avatarPath;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 表单字段（两列布局）
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左列
                  Expanded(
                    child: Column(
                      children: [
                        // 昵称
                        TextFormField(
                          controller: _nicknameController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: '昵称 *',
                            labelStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入昵称';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // 邮件
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: '邮件',
                            labelStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 右列
                  Expanded(
                    child: Column(
                      children: [
                        // 性别
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                          decoration: InputDecoration(
                            labelText: '性别 *',
                            labelStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('男', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('女', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('其他', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedGender = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请选择性别';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // 电话
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: '电话 *',
                            labelStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入电话';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 密码单独一行
              TextFormField(
                controller: _passwordController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: '密码（至少6位，不填写则不修改）',
                  hintText: '不填写则默认不修改',
                  labelStyle: const TextStyle(fontSize: 13),
                  hintStyle: const TextStyle(fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              // 确认密码单独一行
              TextFormField(
                controller: _confirmPasswordController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: '确认密码',
                  hintText: '请再次输入密码',
                  labelStyle: const TextStyle(fontSize: 13),
                  hintStyle: const TextStyle(fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),

              // 底部按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('更新', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}

