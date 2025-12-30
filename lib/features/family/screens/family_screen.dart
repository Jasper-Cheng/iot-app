import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../data/models/family.dart' as family_models;
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../widgets/create_family_dialog.dart';
import '../widgets/join_family_dialog.dart';
import '../widgets/family_member_item.dart';
import '../../home/widgets/device_card_factory.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, List<family_models.FamilyMember>> _familyMembersCache = {}; // 缓存家庭成员

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 初始化时加载家庭数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(familyListProvider.notifier);
        notifier.loadFamilies();
      }
    });
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
            Tab(text: '家庭设备'),
          ],
        ),
      ),
      body: TabBarView(
          controller: _tabController,
          children: [
            _buildFamiliesTab(state, notifier),
          _buildDevicesTab(),
          ],
      ),
    );
  }

  /// 家庭列表标签页（显示当前家庭）
  Widget _buildFamiliesTab(FamilyListState state, FamilyListNotifier notifier) {
    // 如果正在加载家庭列表，显示加载指示器
    if (state.isLoading && state.families.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 如果没有当前家庭，显示空状态
    if (state.currentFamily == null) {
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
              '还没有设置当前家庭',
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

    // 获取当前用户在家庭中的角色
    final currentUserRole = state.familyUserRoles[state.currentFamily!.id];

    return RefreshIndicator(
      onRefresh: () async {
        await notifier.refresh();
      },
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
        child: _buildCurrentFamilyView(
          context,
          state.currentFamily!,
          currentUserRole,
          state.members,
          notifier,
        ),
      ),
    );
  }

  /// 构建当前家庭视图
  Widget _buildCurrentFamilyView(
    BuildContext context,
    family_models.Family family,
    String? currentUserRole,
    List<family_models.FamilyMember> members,
    FamilyListNotifier notifier,
  ) {
    final isCreator = currentUserRole == 'creator' || currentUserRole == 'owner';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 家庭信息卡片
        Card(
          elevation: 4,
            child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildFamilyAvatar(context, family.avatar, 36),
                    const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          // 家庭名称
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '家庭名称: ',
                                style: TextStyle(
                                  fontSize: 14,
                                fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  family.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                          // 描述
                        if (family.description != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          Text(
                                  '描述: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                            family.description!,
                            style: TextStyle(
                              fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                            ),
                              ],
                          ),
                        ],
                        const SizedBox(height: 8),
                          // 邀请码和创建时间（紧凑布局）
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // 邀请码
                              Row(
                                mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.vpn_key,
                                    size: 14,
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
                                  const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _copyInviteCode(family.inviteCode),
                              child: Icon(
                                Icons.copy,
                                      size: 14,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              // 创建时间
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '创建: ${AppDateUtils.formatDateTime(family.createdAt, format: 'yyyy-MM-dd HH:mm')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 删除家庭（仅创建者）
                    if (isCreator)
                      TextButton.icon(
                        onPressed: () => _handleDeleteFamily(context, family, notifier),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('删除家庭'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // 家庭成员列表
        Text(
          '家庭成员 (${members.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('暂无成员', style: TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else
          ...members.map((member) => FamilyMemberItem(
            member: member,
            onEdit: () => _showEditMemberDialog(context, member, notifier),
            onRemove: () => _showRemoveMemberDialog(context, member, notifier),
          )).toList(),
      ],
    );
  }

  /// 家庭设备标签页
  Widget _buildDevicesTab() {
    final deviceState = ref.watch(deviceListProvider);
    final familyState = ref.watch(familyListProvider);

    // 如果没有当前家庭，显示空状态
    if (familyState.currentFamily == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_outlined,
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

    // 如果正在加载，显示加载指示器
    if (deviceState.isLoading && deviceState.devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 如果没有设备，显示空状态
    if (deviceState.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无设备',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(deviceListProvider.notifier).refresh();
      },
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
        itemCount: deviceState.devices.length,
      itemBuilder: (context, index) {
          final device = deviceState.devices[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DeviceCardFactory.createCard(device),
          );
        },
      ),
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
    family_models.FamilyMember member,
    FamilyListNotifier notifier,
  ) async {
    final controller = TextEditingController(text: member.nickname ?? '');

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
    family_models.FamilyMember member,
    FamilyListNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除成员'),
        content: Text('确定要移除成员「${member.nickname ?? '未设置昵称'}」吗？'),
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
      const SnackBar(
        content: Text('邀请码已复制到剪贴板'),
        backgroundColor: Colors.green,
      ),
    );
  }


  /// 构建家庭项
  Widget _buildFamilyItem(
    BuildContext context,
    family_models.Family family,
    bool isSelected,
    String? currentUserRole,
    FamilyListNotifier notifier,
  ) {
    final isCreator = currentUserRole == 'creator' || currentUserRole == 'owner';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 家庭基本信息
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                _buildFamilyAvatar(context, family.avatar, 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // 家庭名称
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '家庭名称: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      family.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : null,
                                      ),
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
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '当前',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        // 描述
                        if (family.description != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '描述: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  family.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        // 邀请码和创建时间（紧凑布局）
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // 邀请码
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.vpn_key,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '邀请码: ${family.inviteCode}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _copyInviteCode(family.inviteCode),
                                  child: Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            // 创建时间
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '创建: ${AppDateUtils.formatDateTime(family.createdAt, format: 'yyyy-MM-dd HH:mm')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // 家庭成员和操作按钮
          // 加载成员（如果还没有加载）
          FutureBuilder<List<family_models.FamilyMember>>(
            future: _familyMembersCache[family.id] != null
                ? Future.value(_familyMembersCache[family.id])
                : notifier.getFamilyMembers(family.id).then((members) {
                    if (mounted) {
                      setState(() {
                        _familyMembersCache[family.id] = members;
                      });
                    }
                    return members;
                  }),
            builder: (context, snapshot) {
              final members = snapshot.data ?? _familyMembersCache[family.id] ?? [];
              
              if (snapshot.connectionState == ConnectionState.waiting && members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '加载成员失败: ${ErrorHandler.extractErrorMessage(snapshot.error!)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  // 家庭成员列表
                  if (members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('暂无成员', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              '家庭成员 (${members.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          ...members.map((member) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    (member.nickname ?? '').isNotEmpty
                                        ? (member.nickname ?? '')[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            member.nickname ?? '未设置昵称',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (member.role == 'owner' || member.role == 'creator')
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
                                                '创建者',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            )
                                          else if (member.role == 'admin')
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
                                      ),
                                      Text(
                                        '手机号: ${member.account.phone}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  // 操作按钮
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 切换为此家庭
                        if (!isSelected)
                          TextButton.icon(
                            onPressed: () => _handleSwitchFamily(context, family, notifier),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('切换为此家庭'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        // 删除家庭（仅创建者）
                        if (isCreator)
                          TextButton.icon(
                            onPressed: () => _handleDeleteFamily(context, family, notifier),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('删除家庭'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 切换家庭
  Future<void> _handleSwitchFamily(
    BuildContext context,
    family_models.Family family,
    FamilyListNotifier notifier,
  ) async {
    await notifier.selectFamily(family);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到家庭「${family.name}」'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 退出家庭
  Future<void> _handleLeaveFamily(
    BuildContext context,
    family_models.Family family,
    FamilyListNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出家庭'),
        content: Text('确定要退出家庭「${family.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // 先加载家庭成员以获取当前用户的 memberId
        await notifier.loadMembers(family.id);
        final members = notifier.state.members;
        final authState = ref.read(authProvider);
        final currentUserId = authState.account?.id;
        
        if (currentUserId == null) {
          throw Exception('无法获取当前用户信息');
        }

        // 查找当前用户的成员信息
        final currentMember = members.firstWhere(
          (m) => m.account.id == currentUserId,
        );

        // 移除自己（退出家庭）
        await notifier.removeMember(currentMember.id);
        
        // 如果退出的是当前家庭，清除当前家庭选择
        if (notifier.state.currentFamily?.id == family.id) {
          await notifier.selectFamily(null);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已退出家庭'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('退出家庭失败: ${ErrorHandler.extractErrorMessage(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 删除家庭
  Future<void> _handleDeleteFamily(
    BuildContext context,
    family_models.Family family,
    FamilyListNotifier notifier,
  ) async {
    final confirm = await _showDeleteConfirmDialog(context, family.name);
    if (confirm == true && mounted) {
      try {
        await notifier.deleteFamily(family.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已删除家庭'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除家庭失败: ${ErrorHandler.extractErrorMessage(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
