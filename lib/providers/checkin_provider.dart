import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/checkin.dart';
import '../data/repositories/checkin_repository.dart';
import '../core/utils/error_handler.dart';

/// 签到状态
class CheckinState {
  final List<DateTime> checkedInDates;
  final CheckinStats? stats;
  final List<CheckinRecord> history;
  final int pointsBalance;
  final List<PointsHistory> pointsHistory;
  final bool hasCheckedInToday;
  final bool isLoading;
  final String? error;
  // 打卡历史分页相关
  final int historyPage;
  final bool isLoadingHistory;
  final bool hasMoreHistory;

  const CheckinState({
    this.checkedInDates = const [],
    this.stats,
    this.history = const [],
    this.pointsBalance = 0,
    this.pointsHistory = const [],
    this.hasCheckedInToday = false,
    this.isLoading = false,
    this.error,
    this.historyPage = 1,
    this.isLoadingHistory = false,
    this.hasMoreHistory = true,
  });

  CheckinState copyWith({
    List<DateTime>? checkedInDates,
    CheckinStats? stats,
    List<CheckinRecord>? history,
    int? pointsBalance,
    List<PointsHistory>? pointsHistory,
    bool? hasCheckedInToday,
    bool? isLoading,
    String? error,
    int? historyPage,
    bool? isLoadingHistory,
    bool? hasMoreHistory,
  }) {
    return CheckinState(
      checkedInDates: checkedInDates ?? this.checkedInDates,
      stats: stats ?? this.stats,
      history: history ?? this.history,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      pointsHistory: pointsHistory ?? this.pointsHistory,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      historyPage: historyPage ?? this.historyPage,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
    );
  }
}

/// 签到状态管理
class CheckinNotifier extends StateNotifier<CheckinState> {
  final CheckinRepository _repository;

  CheckinNotifier(this._repository) : super(const CheckinState()) {
    loadData();
  }

  /// 加载数据
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> loadData({int? year, int? month}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final checkedInDates = await _repository.getCheckInCalendar(year: year, month: month);
      final stats = await _repository.getCheckInStats();
      // 移除积分相关接口请求：pointsBalance 和 pointsHistory

      // 检查今天是否已签到
      final today = DateTime.now();
      final hasCheckedInToday = checkedInDates.any((date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day);

      state = state.copyWith(
        checkedInDates: checkedInDates,
        stats: stats,
        hasCheckedInToday: hasCheckedInToday,
        isLoading: false,
        error: null, // 清除之前的错误
      );
      return (success: true, message: '数据加载成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return (success: false, message: errorMessage);
    }
  }

  /// 加载打卡历史（第一页）
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> loadCheckInHistory() async {
    state = state.copyWith(
      isLoadingHistory: true,
      historyPage: 1,
      hasMoreHistory: true,
      error: null, // 清除之前的错误
    );

    try {
      final history = await _repository.getCheckInHistory(page: 1, pageSize: 20);
      state = state.copyWith(
        history: history,
        isLoadingHistory: false,
        hasMoreHistory: history.length >= 20,
      );
      return (success: true, message: '打卡历史加载成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        isLoadingHistory: false,
        error: errorMessage,
      );
      return (success: false, message: errorMessage);
    }
  }

  /// 加载更多打卡历史（分页）
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> loadMoreCheckInHistory() async {
    if (state.isLoadingHistory || !state.hasMoreHistory) {
      return (success: false, message: '无法加载更多数据');
    }

    state = state.copyWith(isLoadingHistory: true);

    try {
      final nextPage = state.historyPage + 1;
      final history = await _repository.getCheckInHistory(page: nextPage, pageSize: 20);
      
      state = state.copyWith(
        history: [...state.history, ...history],
        historyPage: nextPage,
        isLoadingHistory: false,
        hasMoreHistory: history.length >= 20,
        error: null, // 清除之前的错误
      );
      return (success: true, message: '加载成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        isLoadingHistory: false,
        error: errorMessage,
      );
      return (success: false, message: errorMessage);
    }
  }

  /// 加载指定月份的日历数据
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> loadCalendarForMonth(int year, int month) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final checkedInDates = await _repository.getCheckInCalendar(year: year, month: month);
      state = state.copyWith(
        checkedInDates: checkedInDates,
        isLoading: false,
      );
      return (success: true, message: '日历数据加载成功');
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return (success: false, message: errorMessage);
    }
  }

  /// 获取本地 IP 地址
  Future<String?> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      // 获取 IP 地址失败
    }
    return null;
  }

  /// 签到
  /// 返回 ({bool success, String message, CheckinRecord? record}) 表示状态、消息和签到记录
  Future<({bool success, String message, CheckinRecord? record})> checkIn() async {
    if (state.hasCheckedInToday) {
      final errorMessage = '今天已经签到过了';
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage, record: null);
    }

    try {
      // 构建 extra 参数
      final extra = <String, dynamic>{
        'platform': Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown',
        'user_agent': 'FastIoT Mobile App 1.0.0',
      };

      // 尝试获取 IP 地址
      final ipAddress = await _getLocalIpAddress();
      if (ipAddress != null) {
        extra['ip_address'] = ipAddress;
      }

      final record = await _repository.checkIn(extra: extra);
      
      // 重新加载数据
      await loadData();
      
      return (success: true, message: '签到成功！获得 ${record.pointsEarned} 积分', record: record);
    } catch (e) {
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return (success: false, message: errorMessage, record: null);
    }
  }

  /// 刷新
  /// 返回 ({bool success, String message}) 表示状态和消息
  Future<({bool success, String message})> refresh() async {
    return await loadData();
  }
}

/// 签到 Provider
final checkinProvider = StateNotifierProvider<CheckinNotifier, CheckinState>((ref) {
  return CheckinNotifier(CheckinRepository());
});

/// 积分余额 Provider
final pointsBalanceProvider = Provider<int>((ref) {
  final state = ref.watch(checkinProvider);
  return state.pointsBalance;
});

/// 今日是否已签到 Provider
final hasCheckedInTodayProvider = Provider<bool>((ref) {
  final state = ref.watch(checkinProvider);
  return state.hasCheckedInToday;
});

