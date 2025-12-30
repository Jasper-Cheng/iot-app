import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/family_provider.dart';
import '../../../data/models/family.dart';
import '../../../core/utils/error_handler.dart';
import '../widgets/create_family_dialog.dart';
import '../widgets/join_family_dialog.dart';
import '../widgets/family_member_item.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyListProvider);
    final notifier = ref.read(familyListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('家庭管理'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              if (value == 'create') {
                _showCreateFamilyDialog(context);
              } else if (value == 'join') {
                _showJoinFamilyDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.group_add),
                    SizedBox(width: 8),
                    Text('创建家庭'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'join',
                child: Row(
                  children: [
                    Icon(Icons.input),
                    SizedBox(width: 8),
                    Text('加入家庭'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          tabs: const [
            Tab(text: '我的家庭'),
            Tab(text: '家庭成员'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFamiliesTab(state, notifier),
            _buildMembersTab(state, notifier),
          ],
        ),
      ),
    );
  }

  /// 家庭列表标签页
  Widget _buildFamiliesTab(FamilyListState state, FamilyListNotifier notifier) {
    if (state.isLoading && state.families.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.families.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '还没有加入任何家庭',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateFamilyDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('创建家庭'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showJoinFamilyDialog(context),
              icon: const Icon(Icons.input),
              label: const Text('加入家庭'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.families.length,
      itemBuilder: (context, index) {
        final family = state.families[index];
        final isSelected = state.currentFamily?.id == family.id;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => notifier.selectFamily(family),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildFamilyAvatar(context, family.avatar, 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              family.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '当前',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (family.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            family.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.vpn_key,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '邀请码: ${family.inviteCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _copyInviteCode(family.inviteCode),
                              child: Icon(
                                Icons.copy,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await _showDeleteConfirmDialog(
                          context,
                          family.name,
                        );
                        if (confirm == true && mounted) {
                          notifier.deleteFamily(family.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已删除家庭')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除家庭', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 家庭成员标签页
  Widget _buildMembersTab(FamilyListState state, FamilyListNotifier notifier) {
    if (state.currentFamily == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '请先选择一个家庭',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.members.isEmpty) {
      return const Center(
        child: Text('暂无成员'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.members.length,
      itemBuilder: (context, index) {
        final member = state.members[index];
        return FamilyMemberItem(
          member: member,
          onEdit: () => _showEditMemberDialog(context, member, notifier),
          onRemove: () => _showRemoveMemberDialog(context, member, notifier),
        );
      },
    );
  }

  /// 显示创建家庭对话框
  Future<void> _showCreateFamilyDialog(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateFamilyDialog(),
    );

    if (result != null && mounted) {
      final notifier = ref.read(familyListProvider.notifier);
      await notifier.createFamily(
        name: result['name']!,
        avatar: result['avatar'],
        description: result['description'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('家庭创建成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 显示加入家庭对话框
  Future<void> _showJoinFamilyDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const JoinFamilyDialog(),
    );

    // 如果返回 true，说明加入成功，刷新家庭列表
    if (result == true && mounted) {
      final notifier = ref.read(familyListProvider.notifier);
      await notifier.loadFamilies();
    }
  }

  /// 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    String familyName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除家庭'),
        content: Text('确定要删除家庭「$familyName」吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑成员对话框
  Future<void> _showEditMemberDialog(
    BuildContext context,
    FamilyMember member,
    FamilyListNotifier notifier,
  ) async {
    final controller = TextEditingController(text: member.nickname);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '昵称',
            hintText: '请输入昵称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await notifier.updateMemberNickname(member.id, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称更新成功')),
        );
      }
    }
  }

  /// 显示移除成员对话框
  Future<void> _showRemoveMemberDialog(
    BuildContext context,
    FamilyMember member,
    FamilyListNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除成员'),
        content: Text('确定要移除成员「${member.nickname}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await notifier.removeMember(member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('成员已移除')),
        );
      }
    }
  }

  /// 复制邀请码
  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('邀请码已复制到剪贴板')),
    );
  }

  /// 构建家庭头像
  Widget _buildFamilyAvatar(BuildContext context, String? avatarPath, double radius) {
    final defaultIcon = Icon(
      Icons.family_restroom,
      size: radius * 1.2,
      color: Theme.of(context).iconTheme.color,
    );

    if (avatarPath == null || avatarPath.isEmpty) {
      return ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: Colors.transparent,
          child: defaultIcon,
        ),
      );
    }

    // 如果是完整的 URL（http/https），使用 NetworkImage
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          avatarPath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 网络图片加载失败时显示默认图标
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: Colors.transparent,
              child: defaultIcon,
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
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // assets 图片加载失败时显示默认图标
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: Colors.transparent,
              child: defaultIcon,
            );
          },
        ),
      );
    }

    // 其他情况，显示默认图标
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: Colors.transparent,
        child: defaultIcon,
      ),
    );
  }
}
