import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../app/routes/router.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        authState.account!.nickname[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.account!.nickname,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState.account!.phone,
                            style: theme.textTheme.bodyMedium,
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

