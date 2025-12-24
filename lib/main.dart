import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/storage/storage_service.dart';
import 'core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  await StorageService().init();

  // 初始化网络客户端
  DioClient().init();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
