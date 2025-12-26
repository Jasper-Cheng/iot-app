// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) => Family(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'description': instance.description,
      'invite_code': instance.inviteCode,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) => FamilyMember(
      id: (json['id'] as num).toInt(),
      nickname: json['nickname'] as String,
      role: json['role'] as String,
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      joinedAt: json['joined_at'] == null
          ? null
          : DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$FamilyMemberToJson(FamilyMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'role': instance.role,
      'account': instance.account.toJson(),
      'joined_at': instance.joinedAt?.toIso8601String(),
    };

CreateFamilyRequest _$CreateFamilyRequestFromJson(Map<String, dynamic> json) =>
    CreateFamilyRequest(
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CreateFamilyRequestToJson(
        CreateFamilyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'avatar': instance.avatar,
      'description': instance.description,
    };

JoinFamilyRequest _$JoinFamilyRequestFromJson(Map<String, dynamic> json) =>
    JoinFamilyRequest(
      inviteCode: json['invite_code'] as String,
      nickname: json['nickname'] as String?,
    );

Map<String, dynamic> _$JoinFamilyRequestToJson(JoinFamilyRequest instance) =>
    <String, dynamic>{
      'invite_code': instance.inviteCode,
      'nickname': instance.nickname,
    };

UpdateMemberRequest _$UpdateMemberRequestFromJson(Map<String, dynamic> json) =>
    UpdateMemberRequest(
      nickname: json['nickname'] as String,
    );

Map<String, dynamic> _$UpdateMemberRequestToJson(
        UpdateMemberRequest instance) =>
    <String, dynamic>{
      'nickname': instance.nickname,
    };
