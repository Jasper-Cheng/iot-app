import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../storage/storage_service.dart';
import '../../app/routes/router.dart';

/// API 拦截器
class ApiInterceptor extends Interceptor {
  final _storage = StorageService();
  
  // 静态路由实例引用
  static GoRouter? _router;
  
  // 是否已经跳转到登录页（防止重复跳转）
  static bool _isRedirectingToLogin = false;
  
  // 更新认证状态的回调函数
  static VoidCallback? _onLogoutCallback;
  
  /// 设置路由实例（在应用启动时调用）
  static void setRouter(GoRouter router) {
    _router = router;
  }
  
  /// 设置登出回调（在应用启动时调用）
  static void setLogoutCallback(VoidCallback callback) {
    _onLogoutCallback = callback;
  }
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
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
        // 再次尝试从响应中获取错误信息
        final fallbackErrorMessage = _extractErrorMessageFromResponse(err);
        errorMessage = fallbackErrorMessage ?? errorMessage;
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
  
  /// 从响应中提取错误信息
  /// 返回自定义错误消息，如果没有找到则返回 null
  String? _extractErrorMessageFromResponse(DioException err) {
    try {
      if (err.response?.data != null && err.response?.data is Map) {
        final data = err.response?.data as Map<String, dynamic>;
        
        // 优先使用 detail 字段
        if (data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is String && detail.isNotEmpty) {
            return detail;
          } else if (detail is List && detail.isNotEmpty) {
            // 如果 detail 是数组，取第一个错误信息
            return detail[0].toString();
          }
        }
        
        // 如果没有 detail，使用 message 字段
        if (data.containsKey('message')) {
          final message = data['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }
      }
    } catch (e) {
      // 解析失败，返回 null
    }
    
    return null;
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
    
    // 更新认证状态（通过回调函数）
    _onLogoutCallback?.call();
    
    // 使用 WidgetsBinding 确保在正确的时机跳转
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_router != null) {
          try {
            _router!.go(AppRouter.login);
            _isRedirectingToLogin = false;
          } catch (e) {
            // 跳转失败，重置标志以便重试
            _isRedirectingToLogin = false;
          }
        }
      });

      // 显示 Toast 提示
      Fluttertoast.showToast(
        msg: '登录已过期，请重新登录',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFFFF9800), // 橙色
        textColor: Colors.white,
      );
    });
  }
}

