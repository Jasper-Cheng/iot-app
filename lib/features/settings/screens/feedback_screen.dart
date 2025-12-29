import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/settings_repository.dart';

/// 意见反馈页面
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  
  String _selectedType = 'bug';
  bool _isSubmitting = false;

  final _types = const {
    'bug': 'bug',
    'feature': '功能建议',
    'improvement': '改进建议',
    'complaint': '投诉',
    'praise': '表扬',
    'other': '其他',
  };

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('意见反馈'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 反馈类型选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '反馈类型',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _types.entries.map((entry) {
                        return ChoiceChip(
                          label: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 13),
                          ),
                          selected: _selectedType == entry.key,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedType = entry.key;
                              });
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 反馈内容
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '反馈内容',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '请详细描述您的问题或建议...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 8,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入反馈内容';
                        }
                        if (value.length < 10) {
                          return '反馈内容至少10个字符';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 联系方式（可选）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '联系方式（可选）',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        hintText: '请输入您的联系方式',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 提交按钮
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '提交反馈',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = SettingsRepository();
      await repository.submitFeedback(
        type: _selectedType,
        content: _contentController.text,
        contactInfo: _contactController.text.isEmpty ? null : _contactController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('反馈提交成功，感谢您的宝贵意见！'),
            backgroundColor: Colors.green,
          ),
        );
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

