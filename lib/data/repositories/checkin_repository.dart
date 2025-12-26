import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/checkin.dart';

/// 签到数据仓库
class CheckinRepository {
  final _dio = DioClient().dio;

  /// 签到
  Future<CheckinRecord> checkIn() async {
    final response = await _dio.post(ApiConstants.checkIn);
    return CheckinRecord.fromJson(response.data);
  }

  /// 获取签到日历（本月已签到的日期）
  Future<List<DateTime>> getCheckInCalendar() async {
    final response = await _dio.get(ApiConstants.checkInCalendar);
    final List<dynamic> dates = response.data['dates'];
    return dates.map((e) => DateTime.parse(e as String)).toList();
  }

  /// 获取签到统计
  Future<CheckinStats> getCheckInStats() async {
    final response = await _dio.get(ApiConstants.checkInStats);
    return CheckinStats.fromJson(response.data);
  }

  /// 获取签到历史
  Future<List<CheckinRecord>> getCheckInHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
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
    final response = await _dio.get(ApiConstants.pointsBalance);
    return response.data['balance'] as int;
  }

  /// 获取积分历史
  Future<List<PointsHistory>> getPointsHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
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

