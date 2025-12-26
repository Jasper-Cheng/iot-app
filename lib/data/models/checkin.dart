import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkin.g.dart';

/// 签到统计
@JsonSerializable()
class CheckinStats extends Equatable {
  @JsonKey(name: 'total_check_ins')
  final int totalCheckIns;
  
  @JsonKey(name: 'continuous_days')
  final int continuousDays;
  
  @JsonKey(name: 'longest_continuous')
  final int longestContinuous;

  const CheckinStats({
    required this.totalCheckIns,
    required this.continuousDays,
    required this.longestContinuous,
  });

  factory CheckinStats.fromJson(Map<String, dynamic> json) =>
      _$CheckinStatsFromJson(json);

  Map<String, dynamic> toJson() => _$CheckinStatsToJson(this);

  @override
  List<Object?> get props => [totalCheckIns, continuousDays, longestContinuous];
}

/// 签到记录
@JsonSerializable()
class CheckinRecord extends Equatable {
  final int id;
  
  @JsonKey(name: 'check_in_type')
  final String checkInType; // normal/bonus/makeup
  
  @JsonKey(name: 'points_earned')
  final int pointsEarned;
  
  @JsonKey(name: 'continuous_days')
  final int continuousDays;
  
  @JsonKey(name: 'check_in_time')
  final DateTime checkInTime;
  
  final Map<String, dynamic>? extra;

  const CheckinRecord({
    required this.id,
    required this.checkInType,
    required this.pointsEarned,
    required this.continuousDays,
    required this.checkInTime,
    this.extra,
  });

  factory CheckinRecord.fromJson(Map<String, dynamic> json) =>
      _$CheckinRecordFromJson(json);

  Map<String, dynamic> toJson() => _$CheckinRecordToJson(this);

  @override
  List<Object?> get props => [id, checkInType, pointsEarned, continuousDays, checkInTime, extra];
}

/// 签到日历数据
@JsonSerializable()
class CheckinCalendar extends Equatable {
  final List<String> dates; // 签到日期列表 (YYYY-MM-DD)

  const CheckinCalendar({
    required this.dates,
  });

  factory CheckinCalendar.fromJson(Map<String, dynamic> json) =>
      _$CheckinCalendarFromJson(json);

  Map<String, dynamic> toJson() => _$CheckinCalendarToJson(this);

  @override
  List<Object?> get props => [dates];
}

/// 积分余额
@JsonSerializable()
class PointsBalance extends Equatable {
  @JsonKey(name: 'available_balance')
  final int availableBalance;

  const PointsBalance({
    required this.availableBalance,
  });

  factory PointsBalance.fromJson(Map<String, dynamic> json) =>
      _$PointsBalanceFromJson(json);

  Map<String, dynamic> toJson() => _$PointsBalanceToJson(this);

  @override
  List<Object?> get props => [availableBalance];
}

/// 积分历史记录
@JsonSerializable()
class PointsHistory extends Equatable {
  final int id;
  
  @JsonKey(name: 'account_id')
  final int accountId;
  
  final int points;
  final int? balance;
  final String type; // check_in/penalty/reward/earn/spend/expire
  final String description;
  
  final Map<String, dynamic>? extra;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const PointsHistory({
    required this.id,
    required this.accountId,
    required this.points,
    this.balance,
    required this.type,
    required this.description,
    this.extra,
    required this.createdAt,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) =>
      _$PointsHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PointsHistoryToJson(this);

  @override
  List<Object?> get props => [id, accountId, points, balance, type, description, extra, createdAt];
}

