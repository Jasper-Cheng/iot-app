import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../providers/auth_provider.dart';

/// 路由配置
class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/';
  static const String checkin = '/checkin';

  /// 创建路由
  static GoRouter createRouter(Ref ref) {
    return GoRouter(
      initialLocation: login,
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isAuthenticated = authState.isAuthenticated;
        final currentLocation = state.matchedLocation;
        final isLoginRoute = currentLocation == login;
        final isRegisterRoute = currentLocation == register;

        // 未登录且不在登录页和注册页，跳转到登录页
        if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
          return login;
        }

        // 已登录且在登录页或注册页，跳转到主页
        if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
          return main;
        }

        return null;
      },
      routes: [
        // 登录页
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),

        // 注册页
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),

        // 主框架页（包含底部导航）
        GoRoute(
          path: main,
          builder: (context, state) => const MainScreen(),
        ),

        // 签到与积分页
        GoRoute(
          path: checkin,
          builder: (context, state) => const CheckinScreen(),
        ),
      ],
    );
  }
}

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

