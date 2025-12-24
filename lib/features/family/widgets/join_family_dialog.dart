import 'package:flutter/material.dart';

/// 加入家庭对话框
class JoinFamilyDialog extends StatefulWidget {
  const JoinFamilyDialog({super.key});

  @override
  State<JoinFamilyDialog> createState() => _JoinFamilyDialogState();
}

class _JoinFamilyDialogState extends State<JoinFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _nicknameController.dispose();
    super.dispose();
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
                decoration: const InputDecoration(
                  labelText: '昵称（可选）',
                  hintText: '在家庭中显示的昵称',
                  prefixIcon: Icon(Icons.person),
                ),
                maxLength: 20,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'inviteCode': _inviteCodeController.text.toUpperCase(),
                'nickname': _nicknameController.text.isEmpty
                    ? null
                    : _nicknameController.text,
              });
            }
          },
          child: const Text('加入'),
        ),
      ],
    );
  }
}

