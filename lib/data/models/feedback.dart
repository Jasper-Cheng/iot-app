import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'feedback.g.dart';

/// 反馈信息
@JsonSerializable()
class FeedbackModel extends Equatable {
  final int id;
  final String type; // bug/feature/improvement/complaint/praise/other
  final String content;
  final String? contact;
  final String? images; // JSON 字符串数组
  final String status; // pending/processing/resolved/closed
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const FeedbackModel({
    required this.id,
    required this.type,
    required this.content,
    this.contact,
    this.images,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FeedbackModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackModelToJson(this);

  @override
  List<Object?> get props => [id, type, content, contact, images, status, createdAt, updatedAt];
}

/// 提交反馈请求
@JsonSerializable()
class SubmitFeedbackRequest {
  final String type;
  final String content;
  final String? contact;
  final List<String>? images;

  const SubmitFeedbackRequest({
    required this.type,
    required this.content,
    this.contact,
    this.images,
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

