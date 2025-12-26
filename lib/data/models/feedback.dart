import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'feedback.g.dart';

/// 反馈信息
@JsonSerializable()
class FeedbackModel extends Equatable {
  final int id;
  
  @JsonKey(name: 'account_id')
  final int accountId;
  
  final String? name;
  final String type; // bug/feature/improvement/complaint/praise/other
  final String content;
  
  @JsonKey(name: 'contact_info')
  final String? contactInfo;
  
  final String status; // pending/processing/resolved/rejected/closed
  final String source; // app/web
  
  final String? replay; // 管理员回复
  
  @JsonKey(name: 'processed_at')
  final DateTime? processedAt;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  final Map<String, dynamic>? extra;

  const FeedbackModel({
    required this.id,
    required this.accountId,
    this.name,
    required this.type,
    required this.content,
    this.contactInfo,
    required this.status,
    required this.source,
    this.replay,
    this.processedAt,
    required this.createdAt,
    this.updatedAt,
    this.extra,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FeedbackModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        accountId,
        name,
        type,
        content,
        contactInfo,
        status,
        source,
        replay,
        processedAt,
        createdAt,
        updatedAt,
        extra,
      ];
}

/// 提交反馈请求
@JsonSerializable()
class SubmitFeedbackRequest {
  final String? name;
  final String type;
  final String content;
  
  @JsonKey(name: 'contact_info')
  final String? contactInfo;
  
  final Map<String, dynamic>? extra;

  const SubmitFeedbackRequest({
    this.name,
    required this.type,
    required this.content,
    this.contactInfo,
    this.extra,
  });

  factory SubmitFeedbackRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitFeedbackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitFeedbackRequestToJson(this);
}

/// 版本信息
@JsonSerializable()
class VersionInfo extends Equatable {
  final String version;
  final String? description;
  
  @JsonKey(name: 'release_date')
  final String? releaseDate;
  
  @JsonKey(name: 'download_url')
  final String? downloadUrl;

  const VersionInfo({
    required this.version,
    this.description,
    this.releaseDate,
    this.downloadUrl,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) =>
      _$VersionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VersionInfoToJson(this);

  @override
  List<Object?> get props => [version, description, releaseDate, downloadUrl];
}

