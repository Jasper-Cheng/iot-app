import 'package:dio/dio.dart';

/// 错误处理工具类
class ErrorHandler {
  ErrorHandler._();

  /// 提取错误消息
  /// 
  /// 从异常对象中提取用户友好的错误消息
  /// - 对于 DioException，返回拦截器已处理的 message
  /// - 对于其他异常，返回 toString()
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      // 如果错误已经在拦截器中处理过，直接返回message
      return error.message ?? '请求失败';
    }
    return error.toString();
  }
}

