import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/message_provider.dart';
import '../../../data/models/family.dart' as family_models;
import '../../../data/models/device.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../widgets/create_family_dialog.dart';
import '../widgets/join_family_dialog.dart';
import '../widgets/family_member_item.dart';
import '../widgets/family_device_card.dart';
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
        leading: InkWell(
          onTap: () => _showSelectFamilyDialog(context, state, notifier),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '选择家庭',
                  style: TextStyle(
                      fontSize: 15
                  ),
                ),
              ],
            ),
          ),
        ),
        leadingWidth: 120,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('家庭管理'),
            const SizedBox(width: 8),
            Text(
              '(${state.families.length}/6)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
      return RefreshIndicator(
        onRefresh: () async {
          await notifier.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
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
                    onPressed: () => _showSelectFamilyDialog(context, state, notifier),
                    icon: const Icon(Icons.home),
                    label: const Text('选择家庭'),
                  ),
                ],
              ),
            ),
          ),
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
        physics: const AlwaysScrollableScrollPhysics(),
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
          margin: EdgeInsets.zero,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8),
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
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _copyInviteCode(family.inviteCode),
                                    child: Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _showQRCodeDialog(context, family.inviteCode),
                                    child: Icon(
                                      Icons.qr_code,
                                      size: 16,
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
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                          // 删除家庭（仅创建者）
                          if (isCreator) ...[
                            Expanded(
                              child: IconTheme(
                                data: const IconThemeData(color: Colors.red),
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleDeleteFamily(context, family, notifier),
                                  icon: const Icon(Icons.delete, size: 16,color: Colors.red,),
                                  label: const Text(
                                    '删除家庭',
                                    style: TextStyle(fontSize: 13, color: Colors.red),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // 退出家庭（所有成员）
                          Expanded(
                            child: IconTheme(
                              data: const IconThemeData(color: Colors.orange),
                              child: OutlinedButton.icon(
                                onPressed: () => _handleLeaveFamily(context, family, notifier),
                                icon: const Icon(Icons.exit_to_app, size: 16,color: Colors.orange,),
                                label: const Text(
                                  '退出家庭',
                                  style: TextStyle(fontSize: 13, color: Colors.orange),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // 切回个人设备管理
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleSwitchToPersonal(context, notifier),
                        icon: const Icon(Icons.person, size: 16),
                        label: const Text(
                          '切回个人设备管理',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          minimumSize: Size.zero,
                        ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '家庭成员',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Row(
              children: [
                Text(
                  '${members.length}人',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () => _copyInviteLink(family.inviteCode),
                  icon: const Icon(Icons.link, size: 12),
                  label: const Text(
                    '邀请成员',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
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
          ...members.map((member) {
            // 判断是否是当前用户
            final authState = ref.read(authProvider);
            final currentUserId = authState.account?.id;
            final isCurrentUser = currentUserId != null && member.account.id == currentUserId;
            
            return FamilyMemberItem(
              member: member,
              isCurrentUser: isCurrentUser,
              // 只允许当前用户编辑自己的昵称
              onEdit: isCurrentUser ? () => _showEditMemberDialog(context, member, notifier) : null,
              // 只有创建者可以移除其他成员（不能移除自己）
              onRemove: isCreator && !isCurrentUser
                  ? () => _showRemoveMemberDialog(context, member, notifier)
                  : null,
            );
          }).toList(),
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

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(deviceListProvider.notifier).refresh();
      },
      child: Column(
        children: [
          // 添加设备按钮（靠右）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${deviceState.devices.length}台',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showAddDeviceToFamilyDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    '添加设备到家庭',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // 设备列表
          Expanded(
            child: deviceState.devices.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: deviceState.devices.length,
                    itemBuilder: (context, index) {
                      final device = deviceState.devices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: FamilyDeviceCard(
                          device: device,
                          onDelete: () => _showRemoveDeviceFromFamilyDialog(context, device),
                          onUpdateName: (newName) => _updateDeviceName(context, device, newName),
                        ),
                      );
                    },
                  ),
          ),
        ],
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

    // 如果返回 true，说明加入成功
    // 注意：joinFamily 方法内部已经调用了 loadFamilies()，这里不需要再次调用
    // 避免重复请求
  }

  /// 显示选择家庭对话框
  Future<void> _showSelectFamilyDialog(
      BuildContext context,
      FamilyListState state,
      FamilyListNotifier notifier,
      ) async {
    // 重新获取最新的state，确保显示的是最新的家庭列表
    final currentState = ref.read(familyListProvider);
    
    if (currentState.families.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('您还没有加入任何家庭'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('切换家庭'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        titlePadding: EdgeInsets.symmetric(vertical: 4,horizontal: 12),
        contentPadding: EdgeInsets.symmetric(vertical: 4,horizontal: 16),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...currentState.families.map((family) {
                final isCurrentFamily = currentState.currentFamily?.id == family.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isCurrentFamily ? Colors.green : Colors.grey[300]!,
                      width: isCurrentFamily ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      // 重新获取notifier，避免使用已销毁的notifier
                      final updatedNotifier = ref.read(familyListProvider.notifier);
                      _handleSwitchFamily(context, family, updatedNotifier);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        children: [
                          _buildFamilyAvatar(context, family.avatar, 24),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        family.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentFamily)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          '当前',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (family.description != null && family.description!.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    family.description!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 1),
                                Text(
                                  '邀请码: ${family.inviteCode}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // 重新获取notifier，避免使用已销毁的notifier
                  final updatedNotifier = ref.read(familyListProvider.notifier);
                  _handleSwitchToPersonal(context, updatedNotifier);
                },
                icon: const Icon(Icons.home, size: 18),
                label: const Text(
                  '切回个人设备管理',
                  style: TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: const Text('编辑我在家庭中的昵称'),
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
      try {
        await notifier.updateMemberNickname(member.id, result);
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('昵称更新成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('昵称更新失败: ${ErrorHandler.extractErrorMessage(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          const SnackBar(
            content: Text('成员已移除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 更新设备名称
  Future<void> _updateDeviceName(
    BuildContext context,
    Device device,
    String newName,
  ) async {
    try {
      await ref.read(deviceListProvider.notifier).updateDeviceName(device.id, newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设备名称已更新'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: ${ErrorHandler.extractErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示从家庭移除设备对话框
  Future<void> _showRemoveDeviceFromFamilyDialog(
    BuildContext context,
    Device device,
  ) async {
    final familyState = ref.read(familyListProvider);
    final currentFamily = familyState.currentFamily;
    
    if (currentFamily == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先选择一个家庭'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从家庭移除设备'),
        content: Text('确定要从家庭「${currentFamily.name}」中移除设备「${device.name}」吗？'),
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
      try {
        final notifier = ref.read(familyListProvider.notifier);
        await notifier.removeDeviceFromFamily(currentFamily.id, device.id);
        
        // 刷新设备列表和设备消息
        await Future.wait([
          ref.read(deviceListProvider.notifier).refresh(),
          ref.read(messageProvider.notifier).loadDeviceMessages(status: 'new'),
        ]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('设备已从家庭中移除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('移除失败: ${ErrorHandler.extractErrorMessage(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 显示添加设备到家庭对话框
  Future<void> _showAddDeviceToFamilyDialog(BuildContext context) async {
    final familyState = ref.read(familyListProvider);
    final currentFamily = familyState.currentFamily;
    
    if (currentFamily == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先选择一个家庭'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 获取当前用户的所有个人设备（不传 familyId 获取个人设备）
    final deviceRepository = DeviceRepository();
    List<Device> personalDevices;
    try {
      personalDevices = await deviceRepository.getDevices(familyId: null);
      personalDevices = personalDevices.where((d) => d.isBound).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取设备列表失败: ${ErrorHandler.extractErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 获取家庭中的设备ID列表
    final familyDevicesState = ref.read(deviceListProvider);
    final familyDeviceIds = familyDevicesState.devices.map((d) => d.id).toSet();

    // 排序：未添加的设备优先显示
    final sortedDevices = List<Device>.from(personalDevices);
    sortedDevices.sort((a, b) {
      final aInFamily = familyDeviceIds.contains(a.id);
      final bInFamily = familyDeviceIds.contains(b.id);
      // 未添加的设备（false）排在前面，已添加的设备（true）排在后面
      if (aInFamily == bInFamily) return 0;
      return aInFamily ? 1 : -1;
    });

    // 使用StatefulBuilder来管理多选状态
    final selectedDeviceIds = <int>{};
    
    final result = await showDialog<List<Device>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('添加设备到家庭'),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            titlePadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
            insetPadding: EdgeInsets.symmetric(horizontal: 24,vertical: 24),
            contentPadding: const EdgeInsets.only(left: 12,right: 12,bottom: 12),
            actionsPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450),
              child: SizedBox(
                width: double.maxFinite,
                child: sortedDevices.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            '没有可添加的设备',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedDevices.length,
                        itemBuilder: (context, index) {
                        final device = sortedDevices[index];
                        final isInFamily = familyDeviceIds.contains(device.id);
                        final isSelected = selectedDeviceIds.contains(device.id);
                        
                        return Opacity(
                          opacity: isInFamily ? 0.5 : 1.0,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: isInFamily ? null : () {
                                setState(() {
                                  if (isSelected) {
                                    selectedDeviceIds.remove(device.id);
                                  } else {
                                    selectedDeviceIds.add(device.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                  // 左侧：图标
                                  Text(
                                    device.deviceIcon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  // 中间：设备信息
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 名称（不显示label）
                                        Text(
                                          device.name,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        // 序列号（不显示label）
                                        Text(
                                          device.sn,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                    // 右侧：复选框
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: isInFamily ? null : (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedDeviceIds.add(device.id);
                                          } else {
                                            selectedDeviceIds.remove(device.id);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: selectedDeviceIds.isEmpty
                    ? null
                    : () {
                        final selectedDevices = sortedDevices
                            .where((d) => selectedDeviceIds.contains(d.id))
                            .toList();
                        Navigator.pop(context, selectedDevices);
                      },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final notifier = ref.read(familyListProvider.notifier);
        
        // 批量添加设备
        for (final device in result) {
          await notifier.addDeviceToFamily(currentFamily.id, device.id);
        }
        
        // 刷新设备列表和设备消息
        await Future.wait([
          ref.read(deviceListProvider.notifier).refresh(),
          ref.read(messageProvider.notifier).loadDeviceMessages(status: 'new'),
        ]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已添加 ${result.length} 个设备到家庭'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('添加失败: ${ErrorHandler.extractErrorMessage(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 构建对话框详情行
  Widget _buildDialogDetailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 获取设备状态颜色
  Color _getDeviceStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.blue;
      case 'offline':
        return Colors.grey;
      case 'fatal':
        return Colors.red;
      case 'bound':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// 获取设备状态文本
  String _getDeviceStatusText(String status) {
    switch (status) {
      case 'online':
        return '在线';
      case 'offline':
        return '离线';
      case 'fatal':
        return '故障';
      case 'bound':
        return '已绑定';
      case 'unbound':
        return '未绑定';
      default:
        return '未知';
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

  /// 复制邀请链接
  void _copyInviteLink(String inviteCode) {
    // 构建邀请链接，使用深度链接格式
    final inviteLink = 'iotapp://join?invite_code=$inviteCode';
    Clipboard.setData(ClipboardData(text: inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('邀请链接已复制到剪贴板'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 显示二维码对话框
  void _showQRCodeDialog(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀请码二维码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: inviteCode,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '邀请码: $inviteCode',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '扫描二维码即可获取邀请码',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('邀请码已复制到剪贴板'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('复制邀请码'),
          ),
        ],
      ),
    );
  }

  /// 显示邀请成员对话框
  Future<void> _showInviteMemberDialog(
      BuildContext context,
      family_models.Family family,
      ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀请成员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('邀请码：'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      family.inviteCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _copyInviteCode(family.inviteCode);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: '复制',
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showQRCodeDialog(context, family.inviteCode);
                  },
                  icon: const Icon(Icons.qr_code),
                  tooltip: '二维码',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '将邀请码分享给其他用户，他们可以通过邀请码加入家庭。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
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
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _showQRCodeDialog(context, family.inviteCode),
                                child: Icon(
                                  Icons.qr_code,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '家庭成员',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${members.length}人',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _copyInviteLink(family.inviteCode),
                                      icon: const Icon(Icons.link, size: 12),
                                      label: const Text(
                                        '邀请成员',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                            icon: const Icon(Icons.delete, size: 18,color: Colors.red,),
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
    try {
      // 1. 调用接口更新当前家庭
      final authRepository = AuthRepository();
      await authRepository.updateCurrentFamily(family.id);
      if (!mounted) return;
      
      // 2. 刷新用户信息（更新 authProvider 中的 currentFamilyId）
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      
      // 3. 重新获取 notifier（因为 familyListProvider 会重新创建，使用最新的 currentFamilyId）
      final newNotifier = ref.read(familyListProvider.notifier);
      
      // 4. 重新加载家庭列表（会使用最新的 currentFamilyId）
      await newNotifier.loadFamilies();
      if (!mounted) return;
      
      // 5. 重新获取设备列表 notifier 并刷新设备列表（确保使用最新的 currentFamilyId）
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      await deviceNotifier.refresh();
      if (!mounted) return;
      
      // 6. 重新获取消息列表 notifier 并刷新消息列表（确保使用最新的 currentFamilyId）
      final messageNotifier = ref.read(messageProvider.notifier);
      await messageNotifier.refresh();
      if (!mounted) return;
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到家庭「${family.name}」'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换失败: ${ErrorHandler.extractErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 切回个人设备管理
  Future<void> _handleSwitchToPersonal(
      BuildContext context,
      FamilyListNotifier notifier,
      ) async {
    try {
      // 1. 调用接口切换到个人模式
      final authRepository = AuthRepository();
      await authRepository.updateCurrentFamily(null);
      if (!mounted) return;
      
      // 2. 刷新用户信息（更新 authProvider 中的 currentFamilyId 为 null）
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      
      // 3. 重新获取 notifier（因为 familyListProvider 会重新创建，使用最新的 currentFamilyId）
      final newNotifier = ref.read(familyListProvider.notifier);
      
      // 4. 重新加载家庭列表（会使用最新的 currentFamilyId，应该是 null）
      await newNotifier.loadFamilies();
      if (!mounted) return;
      
      // 5. 重新获取设备列表 notifier 并刷新设备列表（确保使用最新的 currentFamilyId）
      final deviceNotifier = ref.read(deviceListProvider.notifier);
      await deviceNotifier.refresh();
      if (!mounted) return;
      
      // 6. 重新获取消息列表 notifier 并刷新消息列表（确保使用最新的 currentFamilyId）
      final messageNotifier = ref.read(messageProvider.notifier);
      await messageNotifier.refresh();
      if (!mounted) return;
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已切回个人设备管理'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换失败: ${ErrorHandler.extractErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 退出家庭
  Future<void> _handleLeaveFamily(
      BuildContext context,
      family_models.Family family,
      FamilyListNotifier notifier,
      ) async {
    // 先加载家庭成员以检查当前用户是否是创建者
    final currentNotifier = ref.read(familyListProvider.notifier);
    await currentNotifier.loadMembers(family.id);
    if (!mounted) return;
    
    final members = currentNotifier.state.members;
    final authState = ref.read(authProvider);
    final currentUserId = authState.account?.id;

    if (currentUserId == null) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法获取当前用户信息'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 查找当前用户的成员信息
    final currentMember = members.firstWhere(
          (m) => m.account.id == currentUserId,
    );
    
    // 检查是否是创建者
    final isCreator = currentMember.role == 'creator' || currentMember.role == 'owner';

    // 根据是否是创建者显示不同的提示
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCreator ? '退出家庭（将删除家庭）' : '退出家庭'),
        content: Text(
          isCreator 
            ? '您是家庭「${family.name}」的创建者，退出家庭将删除该家庭，此操作无法撤销。确定要退出吗？'
            : '确定要退出家庭「${family.name}」吗？'
        ),
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

        // 移除自己（退出家庭）
        await currentNotifier.removeMember(currentMember.id);
        if (!mounted) return;

        // 退出家庭后，无论是否是当前家庭，都切回个人设备管理
        // 1. 调用接口更新当前家庭为null（切换到个人模式）
        final authRepository = AuthRepository();
        await authRepository.updateCurrentFamily(null);
        if (!mounted) return;
        
        // 2. 刷新用户信息（更新 authProvider 中的 currentFamilyId）
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        
        // 3. 重新获取notifier并重新加载家庭列表
        final updatedNotifier = ref.read(familyListProvider.notifier);
        await updatedNotifier.loadFamilies();
        if (!mounted) return;
        
        // 4. 刷新设备和消息数据
        await Future.wait([
          ref.read(deviceListProvider.notifier).refresh(),
          ref.read(messageProvider.notifier).refresh(),
        ]);

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isCreator ? '已删除家庭' : '已退出家庭'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
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
        // 重新获取notifier，避免使用已销毁的notifier
        final currentNotifier = ref.read(familyListProvider.notifier);

        // 删除家庭
        await currentNotifier.deleteFamily(family.id);
        if (!mounted) return;

        // 删除家庭后，无论是否是当前家庭，都切回个人设备管理
        // 1. 调用接口更新当前家庭为null（切换到个人模式）
        final authRepository = AuthRepository();
        await authRepository.updateCurrentFamily(null);
        if (!mounted) return;
        
        // 2. 刷新用户信息（更新 authProvider 中的 currentFamilyId）
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        
        // 3. 重新获取notifier并重新加载家庭列表
        final updatedNotifier = ref.read(familyListProvider.notifier);
        await updatedNotifier.loadFamilies();
        if (!mounted) return;
        
        // 4. 刷新设备和消息数据
        await Future.wait([
          ref.read(deviceListProvider.notifier).refresh(),
          ref.read(messageProvider.notifier).refresh(),
        ]);

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已删除家庭'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
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
