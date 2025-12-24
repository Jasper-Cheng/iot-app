import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/checkin.dart';
import '../mock/mock_data.dart';

/// 签到数据仓库
class CheckinRepository {
  final _dio = DioClient().dio;
  final bool useMock = false; // 是否使用 Mock 数据，改为 false 连接实际后端

  /// 签到
  Future<CheckinRecord> checkIn() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return CheckinRecord(
        id: DateTime.now().millisecondsSinceEpoch,
        checkInType: 'normal',
        pointsEarned: 5,
        continuousDays: 8,
        checkInTime: DateTime.now(),
        extra: null,
      );
    }

    final response = await _dio.post(ApiConstants.checkIn);
    return CheckinRecord.fromJson(response.data);
  }

  /// 获取签到日历（本月已签到的日期）
  Future<List<DateTime>> getCheckInCalendar() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final dates = MockData.mockCheckinCalendar['dates'] as List;
      return dates.map((e) => DateTime.parse(e as String)).toList();
    }

    final response = await _dio.get(ApiConstants.checkInCalendar);
    final List<dynamic> dates = response.data['dates'];
    return dates.map((e) => DateTime.parse(e as String)).toList();
  }

  /// 获取签到统计
  Future<CheckinStats> getCheckInStats() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return CheckinStats.fromJson(MockData.mockCheckinStats);
    }

    final response = await _dio.get(ApiConstants.checkInStats);
    return CheckinStats.fromJson(response.data);
  }

  /// 获取签到历史
  Future<List<CheckinRecord>> getCheckInHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockCheckinHistory
          .map((e) => CheckinRecord.fromJson(e))
          .toList();
    }

    final response = await _dio.get(
      ApiConstants.checkInHistory,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    final List<dynamic> data = response.data;
    return data.map((e) => CheckinRecord.fromJson(e)).toList();
  }

  /// 获取积分余额
  Future<int> getPointsBalance() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return 520; // Mock 积分余额
    }

    final response = await _dio.get(ApiConstants.pointsBalance);
    return response.data['balance'] as int;
  }

  /// 获取积分历史
  Future<List<PointsHistory>> getPointsHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        PointsHistory(
          id: 1,
          type: 'earn',
          amount: 5,
          description: '每日签到',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PointsHistory(
          id: 2,
          type: 'earn',
          amount: 20,
          description: '连续签到7天奖励',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }

    final response = await _dio.get(
      ApiConstants.pointsHistory,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    final List<dynamic> data = response.data;
    return data.map((e) => PointsHistory.fromJson(e)).toList();
  }
}

