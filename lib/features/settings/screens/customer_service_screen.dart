import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// 联系客服页面
class CustomerServiceScreen extends ConsumerWidget {
  const CustomerServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('联系客服'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 客服热线
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: Colors.blue),
                  ),
                  title: const Text('客服热线'),
                  subtitle: const Text('400-888-8888'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: '400-888-8888'));
                      Fluttertoast.showToast(
                        msg: '已复制到剪贴板',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '服务时间：周一至周日 9:00-18:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 在线客服
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_outlined, color: Colors.green),
              ),
              title: const Text('在线客服'),
              subtitle: const Text('点击进入在线聊天'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Fluttertoast.showToast(
                  msg: '在线客服功能开发中...',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 邮箱联系
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: Colors.orange),
              ),
              title: const Text('邮箱联系'),
              subtitle: const Text('support@iot-app.com'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'support@iot-app.com'));
                  Fluttertoast.showToast(
                    msg: '已复制到剪贴板',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 常见问题
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '常见问题',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildFAQItem(
                  '如何添加设备？',
                  '在首页点击"+"按钮，选择"添加设备"，输入设备序列号即可绑定设备。',
                ),
                _buildFAQItem(
                  '如何创建家庭？',
                  '进入"家庭"页面，点击右上角"+"按钮，选择"创建家庭"，填写家庭信息即可。',
                ),
                _buildFAQItem(
                  '忘记密码怎么办？',
                  '在登录页面点击"忘记密码"，通过手机号验证后可重置密码。',
                ),
                _buildFAQItem(
                  '设备离线怎么处理？',
                  '请检查设备电源和网络连接，确保设备在线。如仍无法连接，请联系客服。',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 提示信息
          Center(
            child: Text(
              '如需更多帮助，请通过以上方式联系我们',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

