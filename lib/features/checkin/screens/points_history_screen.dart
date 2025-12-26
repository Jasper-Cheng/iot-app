import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/checkin_repository.dart';
import '../../../data/models/checkin.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_handler.dart';

/// 积分记录页面
class PointsHistoryScreen extends ConsumerStatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  ConsumerState<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends ConsumerState<PointsHistoryScreen> {
  final _repository = CheckinRepository();
  List<PointsHistory> _history = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
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

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _repository.getPointsHistory(
        page: 1,
        pageSize: _pageSize,
      );
      setState(() {
        _history = history;
        _page = 1;
        _hasMore = history.length >= _pageSize;
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
      final history = await _repository.getPointsHistory(
        page: _page + 1,
        pageSize: _pageSize,
      );
      setState(() {
        _history.addAll(history);
        _page++;
        _hasMore = history.length >= _pageSize;
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
      case 'check_in':
        return '签到奖励';
      case 'penalty':
        return '违规扣除';
      case 'reward':
        return '活动奖励';
      case 'earn':
        return '获得';
      case 'spend':
        return '消费';
      case 'expire':
        return '过期';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'check_in':
      case 'reward':
      case 'earn':
        return Colors.green;
      case 'penalty':
      case 'spend':
        return Colors.orange;
      case 'expire':
        return Colors.grey;
      default:
        return Colors.black87;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'check_in':
        return Icons.calendar_today;
      case 'penalty':
        return Icons.remove_circle_outline;
      case 'reward':
        return Icons.card_giftcard;
      case 'earn':
        return Icons.add_circle_outline;
      case 'spend':
        return Icons.remove_circle_outline;
      case 'expire':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
  
  bool _isPositive(String type) {
    switch (type) {
      case 'check_in':
      case 'reward':
      case 'earn':
        return true;
      case 'penalty':
      case 'spend':
      case 'expire':
        return false;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('积分记录'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading && _history.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _history.isEmpty
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
                          onPressed: _loadHistory,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无积分记录',
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
                        itemCount: _history.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _history.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final item = _history[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getTypeColor(item.type).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getTypeIcon(item.type),
                                  color: _getTypeColor(item.type),
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    _getTypeText(item.type),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isPositive(item.type) ? '+${item.points}' : '${item.points}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: _getTypeColor(item.type),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppDateUtils.formatDateTime(item.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).disabledColor,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

