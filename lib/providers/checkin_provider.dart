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

  const CheckinState({
    this.checkedInDates = const [],
    this.stats,
    this.history = const [],
    this.pointsBalance = 0,
    this.pointsHistory = const [],
    this.hasCheckedInToday = false,
    this.isLoading = false,
    this.error,
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
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final checkedInDates = await _repository.getCheckInCalendar();
      final stats = await _repository.getCheckInStats();
      final history = await _repository.getCheckInHistory();
      final pointsBalance = await _repository.getPointsBalance();
      final pointsHistory = await _repository.getPointsHistory();

      // 检查今天是否已签到
      final today = DateTime.now();
      final hasCheckedInToday = checkedInDates.any((date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day);

      state = state.copyWith(
        checkedInDates: checkedInDates,
        stats: stats,
        history: history,
        pointsBalance: pointsBalance,
        pointsHistory: pointsHistory,
        hasCheckedInToday: hasCheckedInToday,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.extractErrorMessage(e),
      );
    }
  }

  /// 签到
  Future<CheckinRecord?> checkIn() async {
    if (state.hasCheckedInToday) {
      state = state.copyWith(error: '今天已经签到过了');
      return null;
    }

    try {
      final record = await _repository.checkIn();
      
      // 重新加载数据
      await loadData();
      
      return record;
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.extractErrorMessage(e));
      return null;
    }
  }

  /// 刷新
  Future<void> refresh() async {
    await loadData();
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

