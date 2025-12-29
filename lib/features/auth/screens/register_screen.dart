import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/message_provider.dart';
import '../../../app/routes/router.dart';

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
  String? _selectedAvatar; // 选中的头像路径
  final ScrollController _avatarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 初始化时，如果有默认选中的头像，滚动到中间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedAvatar != null) {
        final avatars = List.generate(
          20,
          (index) => 'assets/avatars/avatar${index + 1}.png',
        );
        final index = avatars.indexOf(_selectedAvatar!);
        if (index >= 0) {
          _scrollToSelectedAvatar(index);
        }
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _avatarScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // 将头像路径从 assets/avatars/avatar1.png 转换为 /avatars/avatar1.png
      String? avatarPath;
      if (_selectedAvatar != null) {
        // 从 assets/avatars/avatar1.png 提取 avatar1.png
        final fileName = _selectedAvatar!.split('/').last;
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

  /// 滚动到选中的头像（中间位置）
  void _scrollToSelectedAvatar(int index) {
    if (!_avatarScrollController.hasClients) {
      // 如果 ScrollController 还没有附加，等待下一帧
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedAvatar(index);
      });
      return;
    }

    // 每个头像宽度为 60 + 8 (margin) = 68
    const double itemWidth = 68.0;
    // 获取 ListView 的宽度
    final double viewportWidth = _avatarScrollController.position.viewportDimension;
    // 计算目标位置：让选中的头像在中间
    final double targetPosition = (index * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);
    
    // 确保滚动位置在有效范围内
    final double maxScroll = _avatarScrollController.position.maxScrollExtent;
    final double clampedPosition = targetPosition.clamp(0.0, maxScroll);

    _avatarScrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 构建头像选择器
  Widget _buildAvatarSelector() {
    final theme = Theme.of(context);
    
    // 生成头像列表（avatar1.png 到 avatar20.png）
    final List<String> avatars = List.generate(
      20,
      (index) => 'assets/avatars/avatar${index + 1}.png',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择头像',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            controller: _avatarScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatarPath = avatars[index];
              final isSelected = _selectedAvatar == avatarPath;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatarPath;
                  });
                  // 滚动到选中的头像
                  _scrollToSelectedAvatar(index);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: isSelected ? 3 : 0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      avatarPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    // 监听注册成功，自动跳转到首页
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.isLoading && previous?.isAuthenticated != true) {
        // 注册成功，加载设备相关信息
        Future.wait([
          ref.read(deviceListProvider.notifier).loadDevices(),
          ref.read(messageProvider.notifier).loadMessages(),
        ]).then((_) {
          // 数据加载完成后跳转到首页
          if (context.mounted) {
            context.go(AppRouter.main);
          }
        }).catchError((error) {
          // 即使数据加载失败，也跳转到首页
          if (context.mounted) {
            context.go(AppRouter.main);
          }
        });
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
                _buildAvatarSelector(),

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

