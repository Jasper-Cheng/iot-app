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
        // 登录页（无动画）
        GoRoute(
          path: login,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
          ),
        ),

        // 注册页（无动画）
        GoRoute(
          path: register,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const RegisterScreen(),
          ),
        ),

        // 主框架页（包含底部导航）（无动画）
        GoRoute(
          path: main,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const MainScreen(),
          ),
        ),

        // 签到与积分页（无动画）
        GoRoute(
          path: checkin,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const CheckinScreen(),
          ),
        ),

        // 积分记录页（无动画）
        GoRoute(
          path: pointsHistory,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const PointsHistoryScreen(),
          ),
        ),

        // 反馈列表页（无动画）
        GoRoute(
          path: feedbackList,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const FeedbackListScreen(),
          ),
        ),

        // 意见反馈页（无动画）
        GoRoute(
          path: feedback,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const FeedbackScreen(),
          ),
        ),

        // 关于我们页（无动画）
        GoRoute(
          path: about,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const AboutScreen(),
          ),
        ),

        // 联系客服页（无动画）
        GoRoute(
          path: customerService,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const CustomerServiceScreen(),
          ),
        ),

        // 设备详情页（无动画）
        GoRoute(
          path: deviceDetail,
          pageBuilder: (context, state) {
            final device = state.extra as Device?;
            if (device == null) {
              // 如果设备为空，返回主页
              return NoTransitionPage(
                key: state.pageKey,
                child: const MainScreen(),
              );
            }
            return NoTransitionPage(
              key: state.pageKey,
              child: DeviceDetailScreen(device: device),
            );
          },
        ),

        // 二维码扫描页（无动画）
        GoRoute(
          path: scan,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ScanPage(),
          ),
        ),
      ],
    );
  }
}

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

