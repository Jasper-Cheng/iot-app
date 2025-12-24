import 'package:dio/dio.dart';
import '../storage/storage_service.dart';

/// API 拦截器
class ApiInterceptor extends Interceptor {
  final _storage = StorageService();

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
        // 尝试从响应中获取错误信息
        try {
          if (err.response?.data != null && err.response?.data is Map) {
            final data = err.response?.data as Map<String, dynamic>;
            if (data.containsKey('message')) {
              errorMessage = data['message'] as String;
              // 如果是401错误，清除Token
              if (statusCode == 401) {
                _storage.remove(StorageService.keyToken);
                _storage.remove(StorageService.keyTokenType);
                _storage.remove(StorageService.keyUserInfo);
              }
              break;
            }
          }
        } catch (e) {
          // 解析失败，使用默认错误消息
        }
        
        // 默认错误消息
        switch (statusCode) {
          case 400:
            errorMessage = '请求参数错误';
            break;
          case 401:
            errorMessage = '未授权,请重新登录';
            // 清除 Token
            _storage.remove(StorageService.keyToken);
            _storage.remove(StorageService.keyTokenType);
            _storage.remove(StorageService.keyUserInfo);
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
}

