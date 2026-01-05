import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/device_mapping.dart';

part 'device.g.dart';

/// 设备信息
@JsonSerializable()
class Device extends Equatable {
  final int id;
  final String name;
  final String sn; // 格式: MODEL-YYMMDD-SERIAL
  final String status; // unbound/bound/offline/online/fatal
  
  @JsonKey(name: 'account_id')
  final int? accountId;
  
  @JsonKey(name: 'model_id')
  final int modelId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'ble_name')
  final String? bleName;

  @JsonKey(name: 'ble_mac')
  final String? bleMac;

  const Device({
    required this.id,
    required this.name,
    required this.sn,
    required this.status,
    this.accountId,
    required this.modelId,
    required this.createdAt,
    this.bleName,
    this.bleMac,
  });

  factory Device.fromJson(Map<String, dynamic> json) =>
      _$DeviceFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceToJson(this);

  /// 获取卡片类型
  String get cardName => DeviceMapping.getCardTypeBySN(sn);

  /// 获取型号代码
  String get modelCode => DeviceMapping.getModelCodeBySN(sn);

  /// 获取设备名称
  String get deviceName => DeviceMapping.getDeviceNameByModel(modelCode);

  /// 获取设备图标
  String get deviceIcon => DeviceMapping.getDeviceIconByModel(modelCode);

  /// 是否在线
  bool get isOnline => status == 'online';

  /// 是否离线
  bool get isOffline => status == 'offline';

  /// 是否故障
  bool get isFatal => status == 'fatal';

  /// 是否已绑定
  bool get isBound => status == 'bound' || status == 'online' || status == 'offline';

  Device copyWith({
    int? id,
    String? name,
    String? sn,
    String? status,
    int? accountId,
    int? modelId,
    DateTime? createdAt,
    String? bleName,
    String? bleMac,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      sn: sn ?? this.sn,
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      modelId: modelId ?? this.modelId,
      createdAt: createdAt ?? this.createdAt,
      bleName: bleName ?? this.bleName,
      bleMac: bleMac ?? this.bleMac,
    );
  }

  @override
  List<Object?> get props => [id, name, sn, status, accountId, modelId, createdAt, bleName, bleMac];
}

/// 绑定设备请求
@JsonSerializable()
class BindDeviceRequest {
  final String sn;
  final String? name;

  const BindDeviceRequest({
    required this.sn,
    this.name,
  });

  factory BindDeviceRequest.fromJson(Map<String, dynamic> json) =>
      _$BindDeviceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BindDeviceRequestToJson(this);
}

/// 更新设备名称请求
@JsonSerializable()
class UpdateDeviceNameRequest {
  final String name;

  const UpdateDeviceNameRequest({
    required this.name,
  });

  factory UpdateDeviceNameRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateDeviceNameRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateDeviceNameRequestToJson(this);
}

