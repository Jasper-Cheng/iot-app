import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../app/routes/router.dart';
import '../../../core/widgets/avatar_selector.dart';

/// 注册页面
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'other'; // 默认值为"其他"
  String? _selectedAvatar; // 选中的头像路径（assets路径）

  @override
  void initState() {
    super.initState();
    // 默认选择第一个头像
    _selectedAvatar = 'assets/avatars/avatar1.png';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // 将头像路径从 assets/avatars/avatar1.png 转换为 /avatars/avatar1.png
      String? avatarPath;
      if (_selectedAvatar != null) {
        // 从 assets/avatars/avatar1.png 提取 avatar1.png
        final fileName = _selectedAvatar!.replaceFirst('assets/avatars/', '');
        avatarPath = '/avatars/$fileName';
      }

      await ref.read(authProvider.notifier).register(
            nickname: _nicknameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            gender: _selectedGender,
            email: _emailController.text.trim().isEmpty 
                ? null 
                : _emailController.text.trim(),
            avatar: avatarPath,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    // 监听注册成功，自动跳转到首页
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.isLoading && previous?.isAuthenticated != true) {
        // 注册成功，直接跳转到首页
        if (context.mounted) {
          context.go(AppRouter.main);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('注册'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 头像选择
                AvatarSelector(
                  title: '选择头像',
                  avatarCount: 20,
                  avatarSize: 60,
                  listHeight: 60,
                  spacing: 8,
                  initialAvatar: _selectedAvatar,
                  onAvatarSelected: (avatarPath) {
                    setState(() {
                      _selectedAvatar = avatarPath;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // 昵称输入框
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    prefixIcon: Icon(Icons.person_outlined),
                    hintText: '请输入昵称',
                  ),
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入昵称';
                    }
                    if (value.length < 2) {
                      return '昵称长度不能少于2个字符';
                    }
                    if (value.length > 20) {
                      return '昵称长度不能超过20个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 手机号输入框
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '请输入手机号',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入手机号';
                    }
                    if (value.length != 11) {
                      return '请输入正确的手机号';
                    }
                    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                      return '请输入正确的手机号格式';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    hintText: '请输入密码',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (value.length < 6) {
                      return '密码长度不能少于6位';
                    }
                    if (value.length > 20) {
                      return '密码长度不能超过20位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 确认密码输入框
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: '确认密码',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    hintText: '请再次输入密码',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请再次输入密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 性别选择（必填）
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: '性别',
                    prefixIcon: Icon(Icons.people_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text('男'),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text('女'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('其他'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请选择性别';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGender = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 邮箱输入框（可选）
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '邮箱（可选）',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: '请输入邮箱',
                  ),
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return '请输入正确的邮箱格式';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 注册按钮
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('注册'),
                ),

                // 返回登录
                TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          context.pop();
                        },
                  child: const Text('已有账号？去登录'),
                ),

                // 错误提示
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authState.error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

