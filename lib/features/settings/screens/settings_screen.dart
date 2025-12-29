import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../app/routes/router.dart';
import '../../../data/repositories/checkin_repository.dart';

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

    // 如果头像路径为空，显示首字母
    if (avatarPath == null || avatarPath.isEmpty) {
      return ClipOval(
        child: defaultChild,
      );
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
            // 网络图片加载失败，显示首字母
            return defaultChild;
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
            // assets 图片加载失败，显示首字母
            return defaultChild;
          },
        ),
      );
    }

    // 其他情况，显示首字母
    return ClipOval(
      child: defaultChild,
    );
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
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            // TODO: 编辑用户信息
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
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined, size: 16),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(newSelection.first);
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
                onTap: () => context.push(AppRouter.checkin),
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
              _buildItem(
                icon: Icons.logout_outlined,
                text: '退出登录',
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 版本信息
          Center(
            child: Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 32),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
                // 登出成功后，跳转到登录页
                context.go(AppRouter.login);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

