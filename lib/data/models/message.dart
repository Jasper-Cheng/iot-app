import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

/// 设备消息
@JsonSerializable()
class DeviceMessage extends Equatable {
  final int id;
  
  @JsonKey(name: 'device_id')
  final int deviceId;
  
  final String level; // low/normal/error/fatal
  final String message;
  final Map<String, dynamic>? detail;
  final String status; // new/read
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const DeviceMessage({
    required this.id,
    required this.deviceId,
    required this.level,
    required this.message,
    this.detail,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory DeviceMessage.fromJson(Map<String, dynamic> json) =>
      _$DeviceMessageFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceMessageToJson(this);

  /// 是否已读
  bool get isRead => status == 'read';

  /// 是否未读
  bool get isNew => status == 'new';

  DeviceMessage copyWith({
    int? id,
    int? deviceId,
    String? level,
    String? message,
    Map<String, dynamic>? detail,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceMessage(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      level: level ?? this.level,
      message: message ?? this.message,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, deviceId, level, message, detail, status, createdAt, updatedAt];
}

/// 系统消息
@JsonSerializable()
class SystemMessage extends Equatable {
  final int id;
  final String title;
  final String content;
  final String type; // announcement/maintenance/update/alert/notification
  final String priority; // low/normal/high/urgent
  final List<String> platforms;
  final Map<String, dynamic>? extra;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const SystemMessage({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.platforms,
    this.extra,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SystemMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SystemMessageToJson(this);

  @override
  List<Object?> get props => [id, title, content, type, priority, platforms, extra, createdAt, updatedAt];
}

