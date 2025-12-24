import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  AppColors._();

  // 主色
  static const primary = Color(0xFFBFFE01); // 亮绿色
  static const primaryText = Color(0xFF1A1A1A); // 主色文字

  // 功能色
  static const success = Color(0xFF52C41A);
  static const warning = Color(0xFFFAAD14);
  static const danger = Color(0xFFFF4D4F);
  static const info = Color(0xFF1890FF);

  // 暗色主题背景
  static const darkBgPrimary = Color(0xFF0D0D0D);
  static const darkBgSecondary = Color(0xFF1A1A1A);
  static const darkBgCard = Color(0xFF141414);
  static const darkBorder = Color(0xFF2A2A2A);
  static const darkText = Color(0xFFE8E8E8);
  static const darkTextSecondary = Color(0xFFB0B0B0);

  // 亮色主题背景
  static const lightBgPrimary = Color(0xFFFCFCFC);
  static const lightBgSecondary = Color(0xFFF5F5F5);
  static const lightBgCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE8E8E8);
  static const lightText = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF666666);

  // 设备状态色
  static const statusOnline = Color(0xFF52C41A);
  static const statusOffline = Color(0xFF999999);
  static const statusFatal = Color(0xFFFF4D4F);
  static const statusBound = Color(0xFF1890FF);
  static const statusUnbound = Color(0xFFD9D9D9);
}

