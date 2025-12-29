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

  /// 获取签到日历（已签到的日期）
  /// [year] 年份，默认当前年
  /// [month] 月份，默认当前月
  Future<List<DateTime>> getCheckInCalendar({int? year, int? month}) async {
    final queryParameters = <String, dynamic>{};
    if (year != null) queryParameters['year'] = year;
    if (month != null) queryParameters['month'] = month;
    
    final response = await _dio.get(
      ApiConstants.checkInCalendar,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    // API 返回格式: {"year":2025,"month":11,"check_in_dates":["2025-11-12",...]}
    final List<dynamic> dates = response.data['check_in_dates'] ?? response.data['dates'] ?? [];
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

