import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../features/checkin/screens/points_history_screen.dart';
import '../../features/settings/screens/feedback_list_screen.dart';
import '../../features/settings/screens/feedback_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/customer_service_screen.dart';
import '../../features/home/screens/device_detail_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../data/models/device.dart';
import '../../providers/auth_provider.dart';

/// 路由配置
class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/';
  static const String checkin = '/checkin';
  static const String pointsHistory = '/points-history';
  static const String feedbackList = '/feedback-list';
  static const String feedback = '/feedback';
  static const String about = '/about';
  static const String customerService = '/customer-service';
  static const String deviceDetail = '/device-detail';
  static const String scan = '/scan';

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

        // 积分记录页
        GoRoute(
          path: pointsHistory,
          builder: (context, state) => const PointsHistoryScreen(),
        ),

        // 反馈列表页
        GoRoute(
          path: feedbackList,
          builder: (context, state) => const FeedbackListScreen(),
        ),

        // 意见反馈页
        GoRoute(
          path: feedback,
          builder: (context, state) => const FeedbackScreen(),
        ),

        // 关于我们页
        GoRoute(
          path: about,
          builder: (context, state) => const AboutScreen(),
        ),

        // 联系客服页
        GoRoute(
          path: customerService,
          builder: (context, state) => const CustomerServiceScreen(),
        ),

        // 设备详情页
        GoRoute(
          path: deviceDetail,
          builder: (context, state) {
            final device = state.extra as Device?;
            if (device == null) {
              // 如果设备为空，返回主页
              return const MainScreen();
            }
            return DeviceDetailScreen(device: device);
          },
        ),

        // 二维码扫描页
        GoRoute(
          path: scan,
          builder: (context, state) => const ScanPage(),
        ),
      ],
    );
  }
}

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

