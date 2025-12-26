// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckinStats _$CheckinStatsFromJson(Map<String, dynamic> json) => CheckinStats(
      totalCheckIns: (json['total_check_ins'] as num).toInt(),
      continuousDays: (json['continuous_days'] as num).toInt(),
      longestContinuous: (json['longest_continuous'] as num).toInt(),
    );

Map<String, dynamic> _$CheckinStatsToJson(CheckinStats instance) =>
    <String, dynamic>{
      'total_check_ins': instance.totalCheckIns,
      'continuous_days': instance.continuousDays,
      'longest_continuous': instance.longestContinuous,
    };

CheckinRecord _$CheckinRecordFromJson(Map<String, dynamic> json) =>
    CheckinRecord(
      id: (json['id'] as num).toInt(),
      checkInType: json['check_in_type'] as String,
      pointsEarned: (json['points_earned'] as num).toInt(),
      continuousDays: (json['continuous_days'] as num).toInt(),
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      extra: json['extra'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CheckinRecordToJson(CheckinRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'check_in_type': instance.checkInType,
      'points_earned': instance.pointsEarned,
      'continuous_days': instance.continuousDays,
      'check_in_time': instance.checkInTime.toIso8601String(),
      'extra': instance.extra,
    };

CheckinCalendar _$CheckinCalendarFromJson(Map<String, dynamic> json) =>
    CheckinCalendar(
      dates: (json['dates'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$CheckinCalendarToJson(CheckinCalendar instance) =>
    <String, dynamic>{
      'dates': instance.dates,
    };

PointsBalance _$PointsBalanceFromJson(Map<String, dynamic> json) =>
    PointsBalance(
      availableBalance: (json['available_balance'] as num).toInt(),
    );

Map<String, dynamic> _$PointsBalanceToJson(PointsBalance instance) =>
    <String, dynamic>{
      'available_balance': instance.availableBalance,
    };

PointsHistory _$PointsHistoryFromJson(Map<String, dynamic> json) =>
    PointsHistory(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PointsHistoryToJson(PointsHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
    };
