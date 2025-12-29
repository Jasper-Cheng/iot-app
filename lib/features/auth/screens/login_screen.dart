import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:fluwx/fluwx.dart'; // TODO: 配置微信AppID后启用
import '../../../providers/auth_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/message_provider.dart';
import '../../../app/routes/router.dart';
import '../../../core/storage/storage_service.dart';

/// 登录页面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = StorageService();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    // _initWechat(); // TODO: 配置微信AppID后启用
  }

  /// 初始化微信SDK
  /// 注意：需要在微信开放平台注册应用并获取AppID
  /// 1. 前往 https://open.weixin.qq.com/ 注册开发者账号
  /// 2. 创建应用并获取AppID
  /// 3. 在Android和iOS项目中配置AppID
  /// 4. 取消注释下面的代码并替换YOUR_WECHAT_APP_ID
  /*
  Future<void> _initWechat() async {
    const String wechatAppId = 'YOUR_WECHAT_APP_ID'; // 替换为真实的微信AppID
    
    await registerWxApi(
      appId: wechatAppId,
      doOnAndroid: true,
      doOnIOS: true,
    );
  }
  */

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 加载记住的账号密码
  Future<void> _loadRememberedCredentials() async {
    final rememberMe = _storage.getBool(StorageService.keyRememberMe) ?? false;
    final savedPhone = _storage.getString(StorageService.keyRememberPhone);
    final savedPassword = await _storage.getSecure(StorageService.keyRememberPassword);

    // 检查组件是否仍然挂载
    if (!mounted) return;

    setState(() {
      _rememberMe = rememberMe;
      // 只加载已保存的手机号
      if (savedPhone != null && savedPhone.isNotEmpty) {
        _phoneController.text = savedPhone;
      }
      // 只加载已保存的密码（如果勾选了"记住我"）
      if (rememberMe && savedPassword != null && savedPassword.isNotEmpty) {
        _passwordController.text = savedPassword;
      }
    });
  }

  /// 保存记住的账号密码
  Future<void> _saveRememberedCredentials() async {
    if (_rememberMe) {
      // 保存"记住我"状态
      await _storage.setBool(StorageService.keyRememberMe, true);
      // 保存手机号
      await _storage.setString(StorageService.keyRememberPhone, _phoneController.text);
      // 保存密码（使用安全存储）
      await _storage.setSecure(StorageService.keyRememberPassword, _passwordController.text);
    } else {
      // 清除保存的信息
      await _storage.setBool(StorageService.keyRememberMe, false);
      await _storage.remove(StorageService.keyRememberPhone);
      await _storage.deleteSecure(StorageService.keyRememberPassword);
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // 先保存"记住我"状态
      await _saveRememberedCredentials();
      
      // 执行登录
      await ref.read(authProvider.notifier).login(
            _phoneController.text,
            _passwordController.text,
          );
    }
  }

  /// 显示忘记密码提示
  void _showForgotPasswordHint() {
    Fluttertoast.showToast(
      msg: '你没忘',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }

  /// 处理微信登录
  /// 注意：需要先配置微信AppID并启用相关代码
  Future<void> _handleWechatLogin() async {
    // TODO: 配置微信AppID后启用以下代码
    /*
    try {
      // 检查是否安装了微信
      final isWeChatInstalled = await isWeChatAppInstalled();
      if (!isWeChatInstalled) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: '请先安装微信',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
        }
        return;
      }

      // 发起微信登录
      final result = await sendWeChatAuth(
        scope: 'snsapi_userinfo',
        state: 'wechat_login',
      );

      if (result.isSuccessful && result.code != null) {
        // 获取到授权码，调用后端登录接口
        await ref.read(authProvider.notifier).wechatLogin(result.code!);
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: result.errorMsg ?? '微信登录失败',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: '微信登录失败: ${e.toString()}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
      }
    }
    */
    
    // 临时提示：没有配置微信AppID
    Fluttertoast.showToast(
      msg: '微信shit',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    // 监听登录成功，自动跳转到首页（包括微信登录）
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.isLoading && previous?.isAuthenticated != true) {
        // 登录成功，加载设备相关信息
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.home_outlined,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // 标题
                  Text(
                    'IoT智能家居',
                    style: theme.textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '让生活更智能',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

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
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // 记住我
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                          // 如果取消勾选，立即清除保存的密码
                          if (!_rememberMe) {
                            _storage.setBool(StorageService.keyRememberMe, false);
                            _storage.remove(StorageService.keyRememberPhone);
                            _storage.deleteSecure(StorageService.keyRememberPassword);
                          }
                        },
                      ),
                      const Text('记住我'),
                      const Spacer(),
                      TextButton(
                        onPressed: _showForgotPasswordHint,
                        child: const Text('忘记密码?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 4),
                  // 注册文本（右下角）
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '还没有账号? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          GestureDetector(
                            onTap: authState.isLoading
                                ? null
                                : () {
                                    context.push(AppRouter.register);
                                  },
                            child: Text(
                              '立即注册',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 其他登录方式
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '其他登录方式',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(child: Divider(color: theme.dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 微信登录
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.wechat, size: 48),
                      color: Colors.green,
                      onPressed: authState.isLoading ? null : _handleWechatLogin,
                    ),
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
      ),
    );
  }
}

