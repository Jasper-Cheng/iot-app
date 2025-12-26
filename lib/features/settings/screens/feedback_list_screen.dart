import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/models/feedback.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_handler.dart';

/// 反馈列表页面
class FeedbackListScreen extends ConsumerStatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  ConsumerState<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends ConsumerState<FeedbackListScreen> {
  final _repository = SettingsRepository();
  List<FeedbackModel> _feedbackList = [];
  bool _isLoading = true;
  String? _error;
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFeedbackList();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadFeedbackList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _repository.getFeedbackList(
        skip: 0,
        limit: _limit,
      );
      setState(() {
        _feedbackList = list;
        _skip = 0;
        _hasMore = list.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.extractErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final list = await _repository.getFeedbackList(
        skip: _skip + _limit,
        limit: _limit,
      );
      setState(() {
        _feedbackList.addAll(list);
        _skip += _limit;
        _hasMore = list.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.extractErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'bug':
        return '问题反馈';
      case 'feature':
        return '功能建议';
      case 'improvement':
        return '改进建议';
      case 'complaint':
        return '投诉';
      case 'praise':
        return '表扬';
      case 'other':
        return '其他';
      default:
        return type;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待处理';
      case 'processing':
        return '处理中';
      case 'resolved':
        return '已解决';
      case 'rejected':
        return '已拒绝';
      case 'closed':
        return '已关闭';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('反馈列表'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeedbackList,
        child: _isLoading && _feedbackList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _feedbackList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFeedbackList,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : _feedbackList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.feedback_outlined,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无反馈记录',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _feedbackList.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _feedbackList.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final item = _feedbackList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getTypeText(item.type),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(item.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(item.status),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: _getStatusColor(item.status),
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  AppDateUtils.formatDateTime(item.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).disabledColor,
                                      ),
                                ),
                              ),
                              expandedAlignment: Alignment.center,
                              children: [
                                if (item.content.isNotEmpty) ...[
                                  Text(
                                    '反馈内容',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.content,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (item.contactInfo != null && item.contactInfo!.isNotEmpty) ...[
                                  Text(
                                    '联系方式',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.contactInfo!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (item.replay != null && item.replay!.isNotEmpty) ...[
                                  Text(
                                    '管理员回复',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.replay!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (item.updatedAt != null)
                                  Row(
                                    children: [
                                      Text(
                                        '更新时间: ',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).disabledColor,
                                        ),
                                      ),
                                      Text(
                                        AppDateUtils.formatDateTime(item.updatedAt!),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).disabledColor,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

