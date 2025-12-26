import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 关于我们页面
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('关于我们'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Logo
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.home_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App名称
          const Center(
            child: Text(
              '智能家居 IoT',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 版本号
          const Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // App简介
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App简介',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '智能家居 IoT 是一款专业的智能家居管理应用，致力于为用户提供便捷、智能的家庭设备管理服务。通过本应用，您可以轻松控制各类智能设备，实现家庭自动化，享受智慧生活。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 核心功能
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '核心功能',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.devices,
                    '设备管理',
                    '支持12种智能设备，一键控制',
                  ),
                  _buildFeatureItem(
                    Icons.family_restroom,
                    '家庭共享',
                    '创建家庭，与家人共享设备',
                  ),
                  _buildFeatureItem(
                    Icons.notifications,
                    '消息提醒',
                    '实时接收设备状态和系统通知',
                  ),
                  _buildFeatureItem(
                    Icons.calendar_today,
                    '签到积分',
                    '每日签到赚积分，兑换好礼',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 联系方式
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '联系我们',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.email, '邮箱', 'support@iot-app.com'),
                  _buildContactItem(Icons.phone, '电话', '400-888-8888'),
                  _buildContactItem(Icons.language, '官网', 'www.iot-app.com'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 版权信息
          Center(
            child: Text(
              'Copyright © 2025 IoT App\nAll Rights Reserved',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

