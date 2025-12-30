import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'family.g.dart';

/// 家庭信息
@JsonSerializable()
class Family extends Equatable {
  final int id;
  final String name;
  final String? avatar;
  final String? description;
  
  @JsonKey(name: 'invite_code')
  final String inviteCode;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Family({
    required this.id,
    required this.name,
    this.avatar,
    this.description,
    required this.inviteCode,
    required this.createdAt,
    this.updatedAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) =>
      _$FamilyFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyToJson(this);

  Family copyWith({
    int? id,
    String? name,
    String? avatar,
    String? description,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      description: description ?? this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, avatar, description, inviteCode, createdAt, updatedAt];
}

/// 家庭成员
@JsonSerializable()
class FamilyMember extends Equatable {
  final int id; // family_member_id
  final String nickname; // 在家庭中的昵称
  final String role; // creator/member/admin/owner
  
  @JsonKey(name: 'family_id')
  final int familyId; // 家庭ID
  
  @JsonKey(name: 'account_id')
  final int accountId; // 账户ID
  
  @JsonKey(name: 'joined_at')
  final DateTime? joinedAt; // 加入时间

  const FamilyMember({
    required this.id,
    required this.nickname,
    required this.role,
    required this.familyId,
    required this.accountId,
    this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyMemberToJson(this);

  /// 是否是创建者
  bool get isCreator => role == 'creator' || role == 'owner';

  FamilyMember copyWith({
    int? id,
    String? nickname,
    String? role,
    int? familyId,
    int? accountId,
    DateTime? joinedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      accountId: accountId ?? this.accountId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [id, nickname, role, familyId, accountId, joinedAt];
}

/// 创建家庭请求
@JsonSerializable()
class CreateFamilyRequest {
  final String name;
  final String? avatar;
  final String? description;

  const CreateFamilyRequest({
    required this.name,
    this.avatar,
    this.description,
  });

  factory CreateFamilyRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateFamilyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFamilyRequestToJson(this);
}

/// 加入家庭请求
@JsonSerializable()
class JoinFamilyRequest {
  @JsonKey(name: 'invite_code')
  final String inviteCode;
  
  final String? nickname;

  const JoinFamilyRequest({
    required this.inviteCode,
    this.nickname,
  });

  factory JoinFamilyRequest.fromJson(Map<String, dynamic> json) =>
      _$JoinFamilyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JoinFamilyRequestToJson(this);
}

/// 更新成员昵称请求
@JsonSerializable()
class UpdateMemberRequest {
  final String nickname;

  const UpdateMemberRequest({
    required this.nickname,
  });

  factory UpdateMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMemberRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMemberRequestToJson(this);
}

