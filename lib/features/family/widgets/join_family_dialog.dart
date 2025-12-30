import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/family_provider.dart';
import '../../../core/utils/error_handler.dart';

/// 加入家庭对话框
class JoinFamilyDialog extends ConsumerStatefulWidget {
  const JoinFamilyDialog({super.key});

  @override
  ConsumerState<JoinFamilyDialog> createState() => _JoinFamilyDialogState();
}

class _JoinFamilyDialogState extends ConsumerState<JoinFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  late final TextEditingController _nicknameController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 获取当前用户的昵称作为默认值
    final authState = ref.read(authProvider);
    final defaultNickname = authState.account?.nickname ?? '';
    _nicknameController = TextEditingController(text: defaultNickname);
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final notifier = ref.read(familyListProvider.notifier);
      await notifier.joinFamily(
        _inviteCodeController.text.toUpperCase(),
        nickname: _nicknameController.text.isEmpty
            ? null
            : _nicknameController.text,
      );

      // 成功时关闭弹窗
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('加入家庭成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 失败时保持弹窗打开，显示错误信息
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = ErrorHandler.extractErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加入家庭'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _inviteCodeController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: '邀请码',
                  hintText: '请输入8位邀请码',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邀请码';
                  }
                  if (value.length != 8) {
                    return '邀请码必须为8位';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: '昵称（可选）',
                  hintText: '在家庭中显示的昵称',
                  prefixIcon: Icon(Icons.person),
                ),
                maxLength: 20,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleJoin,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('加入'),
        ),
      ],
    );
  }
}

