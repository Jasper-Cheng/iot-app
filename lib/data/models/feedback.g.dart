// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackModel _$FeedbackModelFromJson(Map<String, dynamic> json) =>
    FeedbackModel(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      content: json['content'] as String,
      contact: json['contact'] as String?,
      images: json['images'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$FeedbackModelToJson(FeedbackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'content': instance.content,
      'contact': instance.contact,
      'images': instance.images,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

SubmitFeedbackRequest _$SubmitFeedbackRequestFromJson(
        Map<String, dynamic> json) =>
    SubmitFeedbackRequest(
      type: json['type'] as String,
      content: json['content'] as String,
      contact: json['contact'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SubmitFeedbackRequestToJson(
        SubmitFeedbackRequest instance) =>
    <String, dynamic>{
      'type': instance.type,
      'content': instance.content,
      'contact': instance.contact,
      'images': instance.images,
    };

VersionInfo _$VersionInfoFromJson(Map<String, dynamic> json) => VersionInfo(
      version: json['version'] as String,
      description: json['description'] as String?,
      releaseDate: json['release_date'] as String?,
      downloadUrl: json['download_url'] as String?,
    );

Map<String, dynamic> _$VersionInfoToJson(VersionInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'description': instance.description,
      'release_date': instance.releaseDate,
      'download_url': instance.downloadUrl,
    };

