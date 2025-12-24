import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// 登录响应
@JsonSerializable()
class LoginResponse extends Equatable {
  @JsonKey(name: 'access_token')
  final String accessToken;
  
  @JsonKey(name: 'token_type')
  final String tokenType;
  
  final String role;
  final Account account;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.role,
    required this.account,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  @override
  List<Object?> get props => [accessToken, tokenType, role, account];
}

/// 账户信息
@JsonSerializable()
class Account extends Equatable {
  final int id;
  final String nickname;
  final String? gender; // male/female/other
  final String phone;
  final String? email;
  final String? avatar;
  final String role; // user/admin
  
  @JsonKey(name: 'current_family_id')
  final int? currentFamilyId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.nickname,
    this.gender,
    required this.phone,
    this.email,
    this.avatar,
    required this.role,
    this.currentFamilyId,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);

  Account copyWith({
    int? id,
    String? nickname,
    String? gender,
    String? phone,
    String? email,
    String? avatar,
    String? role,
    int? currentFamilyId,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      currentFamilyId: currentFamilyId ?? this.currentFamilyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nickname,
        gender,
        phone,
        email,
        avatar,
        role,
        currentFamilyId,
        createdAt,
      ];
}

/// 注册请求
@JsonSerializable()
class RegisterRequest {
  final String nickname;
  final String phone;
  final String password;
  final String? gender;
  final String? email;
  final String? avatar;

  const RegisterRequest({
    required this.nickname,
    required this.phone,
    required this.password,
    this.gender,
    this.email,
    this.avatar,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

/// 登录请求
@JsonSerializable()
class LoginRequest {
  final String phone;
  final String password;

  const LoginRequest({
    required this.phone,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

