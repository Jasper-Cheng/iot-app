// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sn: json['sn'] as String,
      status: json['status'] as String,
      accountId: (json['account_id'] as num?)?.toInt(),
      modelId: (json['model_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sn': instance.sn,
      'status': instance.status,
      'account_id': instance.accountId,
      'model_id': instance.modelId,
      'created_at': instance.createdAt.toIso8601String(),
    };

BindDeviceRequest _$BindDeviceRequestFromJson(Map<String, dynamic> json) =>
    BindDeviceRequest(
      sn: json['sn'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$BindDeviceRequestToJson(BindDeviceRequest instance) =>
    <String, dynamic>{
      'sn': instance.sn,
      'name': instance.name,
    };

UpdateDeviceNameRequest _$UpdateDeviceNameRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateDeviceNameRequest(
      name: json['name'] as String,
    );

Map<String, dynamic> _$UpdateDeviceNameRequestToJson(
        UpdateDeviceNameRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
    };
