import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// 权限助手类
class PermissionHelper {
  /// 请求相机权限
  static Future<bool> requestCamera(BuildContext context) async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      return await _showPermissionDialog(
        context,
        '相机权限',
        '需要相机权限来扫描设备二维码，请在设置中开启',
      );
    }
    
    return false;
  }
  
  /// 请求存储/照片权限
  static Future<bool> requestStorage(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android 13+ 使用photos权限
      if (await _getAndroidVersion() >= 33) {
        final status = await Permission.photos.status;
        if (status.isGranted) return true;
        if (status.isDenied) {
          final result = await Permission.photos.request();
          return result.isGranted;
        }
        if (status.isPermanentlyDenied) {
          return await _showPermissionDialog(
            context,
            '照片权限',
            '需要访问照片以选择头像，请在设置中开启',
          );
        }
      } else {
        // Android 12 及以下使用storage权限
        final status = await Permission.storage.status;
        if (status.isGranted) return true;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        if (status.isPermanentlyDenied) {
          return await _showPermissionDialog(
            context,
            '存储权限',
            '需要存储权限以保存和读取文件，请在设置中开启',
          );
        }
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }
      if (status.isPermanentlyDenied) {
        return await _showPermissionDialog(
          context,
          '相册权限',
          '需要访问相册以选择照片，请在设置中开启',
        );
      }
    }
    
    return false;
  }
  
  /// 请求通知权限
  static Future<bool> requestNotification(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android 13+ 需要请求通知权限
      if (await _getAndroidVersion() >= 33) {
        final status = await Permission.notification.status;
        if (status.isGranted) return true;
        if (status.isDenied) {
          final result = await Permission.notification.request();
          return result.isGranted;
        }
        if (status.isPermanentlyDenied) {
          return await _showPermissionDialog(
            context,
            '通知权限',
            '需要通知权限以接收设备消息和系统通知，请在设置中开启',
          );
        }
      }
      return true; // Android 12及以下不需要请求
    }
    
    return true; // iOS 由系统自动处理
  }
  
  /// 检查相机权限
  static Future<bool> checkCamera() async {
    return await Permission.camera.isGranted;
  }
  
  /// 检查存储权限
  static Future<bool> checkStorage() async {
    if (Platform.isAndroid) {
      if (await _getAndroidVersion() >= 33) {
        return await Permission.photos.isGranted;
      }
      return await Permission.storage.isGranted;
    }
    return await Permission.photos.isGranted;
  }
  
  /// 检查通知权限
  static Future<bool> checkNotification() async {
    if (Platform.isAndroid && await _getAndroidVersion() >= 33) {
      return await Permission.notification.isGranted;
    }
    return true;
  }
  
  /// 获取Android版本
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)').firstMatch(version);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      // 默认返回高版本
      return 33;
    }
    return 0;
  }
  
  /// 显示权限说明对话框
  static Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await openAppSettings();
    }
    
    return false;
  }
  
  /// 请求所有必要权限（首次使用时调用）
  static Future<void> requestInitialPermissions(BuildContext context) async {
    // 通知权限
    await requestNotification(context);
  }
  
  /// 显示权限说明（在请求前）
  static Future<bool> showPermissionExplanation(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('允许'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}

