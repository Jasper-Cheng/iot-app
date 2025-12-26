// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackModel _$FeedbackModelFromJson(Map<String, dynamic> json) =>
    FeedbackModel(
      id: (json['id'] as num).toInt(),
      accountId: (json['account_id'] as num).toInt(),
      name: json['name'] as String?,
      type: json['type'] as String,
      content: json['content'] as String,
      contactInfo: json['contact_info'] as String?,
      status: json['status'] as String,
      source: json['source'] as String,
      replay: json['replay'] as String?,
      processedAt: json['processed_at'] == null
          ? null
          : DateTime.parse(json['processed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      extra: json['extra'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FeedbackModelToJson(FeedbackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'name': instance.name,
      'type': instance.type,
      'content': instance.content,
      'contact_info': instance.contactInfo,
      'status': instance.status,
      'source': instance.source,
      'replay': instance.replay,
      'processed_at': instance.processedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'extra': instance.extra,
    };

SubmitFeedbackRequest _$SubmitFeedbackRequestFromJson(
        Map<String, dynamic> json) =>
    SubmitFeedbackRequest(
      name: json['name'] as String?,
      type: json['type'] as String,
      content: json['content'] as String,
      contactInfo: json['contact_info'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SubmitFeedbackRequestToJson(
        SubmitFeedbackRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'content': instance.content,
      'contact_info': instance.contactInfo,
      'extra': instance.extra,
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
