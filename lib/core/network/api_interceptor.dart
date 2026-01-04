import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../storage/storage_service.dart';
import '../../app/routes/router.dart';

/// API 拦截器
class ApiInterceptor extends Interceptor {
  final _storage = StorageService();
  
  // 静态路由实例引用
  static GoRouter? _router;
  
  // 静态 Dio 实例引用（用于取消请求）
  static Dio? _dio;
  
  // 是否已经跳转到登录页（防止重复跳转）
  static bool _isRedirectingToLogin = false;
  
  /// 设置路由实例（在应用启动时调用）
  static void setRouter(GoRouter router) {
    _router = router;
  }
  
  /// 设置 Dio 实例（用于取消请求）
  static void setDio(Dio dio) {
    _dio = dio;
  }
  
  /// 重置跳转标志（在登录成功后调用）
  static void resetRedirectFlag() {
    _isRedirectingToLogin = false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 如果正在跳转到登录页，取消所有后续请求
    if (_isRedirectingToLogin) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: '认证失败，已跳转到登录页',
        ),
      );
      return;
    }
    
    // 添加 Token
    final token = _storage.getString(StorageService.keyToken);
    final tokenType = _storage.getString(StorageService.keyTokenType) ?? 'Bearer';
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = '$tokenType $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 处理响应
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 统一错误处理
    String errorMessage = '网络请求失败';

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = '连接超时';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = '发送超时';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = '接收超时';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        bool hasCustomMessage = false;
        
        // 尝试从响应中获取错误信息
        try {
          if (err.response?.data != null && err.response?.data is Map) {
            final data = err.response?.data as Map<String, dynamic>;
            
            // 优先使用 detail 字段
            if (data.containsKey('detail')) {
              final detail = data['detail'];
              if (detail is String && detail.isNotEmpty) {
                errorMessage = detail;
                hasCustomMessage = true;
              } else if (detail is List && detail.isNotEmpty) {
                // 如果 detail 是数组，取第一个错误信息
                errorMessage = detail[0].toString();
                hasCustomMessage = true;
              }
            }
            
            // 如果没有 detail，使用 message 字段
            if (!hasCustomMessage && data.containsKey('message')) {
              final message = data['message'];
              if (message is String && message.isNotEmpty) {
                errorMessage = message;
                hasCustomMessage = true;
              }
            }
            
            // 如果找到了自定义错误消息，直接跳出
            if (hasCustomMessage) {
              break;
            }
          }
        } catch (e) {
          // 解析失败，使用默认错误消息
        }
        
        // 默认HTTP状态码错误消息
        switch (statusCode) {
          case 400:
            errorMessage = '请求参数错误';
            break;
          case 401:
            errorMessage = '未授权,请重新登录';
            // 处理401错误：清除Token、取消请求、跳转登录
            _handle401Error();
            break;
          case 403:
            errorMessage = '禁止访问';
            break;
          case 404:
            errorMessage = '请求的资源不存在';
            break;
          case 409:
            errorMessage = '资源冲突';
            break;
          case 422:
            errorMessage = '请求参数验证失败';
            break;
          case 500:
            errorMessage = '服务器内部错误';
            break;
          case 502:
            errorMessage = '网关错误';
            break;
          case 503:
            errorMessage = '服务不可用';
            break;
          default:
            errorMessage = '请求失败 ($statusCode)';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = '请求已取消';
        break;
      case DioExceptionType.unknown:
        errorMessage = '网络连接失败,请检查网络';
        break;
      default:
        errorMessage = '未知错误';
    }

    // 将错误信息添加到 DioException
    err = err.copyWith(
      message: errorMessage,
    );

    super.onError(err, handler);
  }
  
  /// 处理401认证失败错误
  void _handle401Error() {
    // 防止重复处理
    if (_isRedirectingToLogin) {
      return;
    }
    
    _isRedirectingToLogin = true;
    
    // 清除本地存储的认证信息
    _storage.remove(StorageService.keyToken);
    _storage.remove(StorageService.keyTokenType);
    _storage.remove(StorageService.keyUserInfo);
    _storage.remove(StorageService.keyCurrentFamilyId);
    
    // 取消所有待处理的请求
    // 注意：不关闭 Dio 实例，只取消当前请求队列
    // 关闭 Dio 会导致后续无法使用，所以这里只标记状态
    
    // 延迟跳转，确保状态已清除
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_router != null) {
        _router!.go(AppRouter.login);
      }
    });
  }
}

