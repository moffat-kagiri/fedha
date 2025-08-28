// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncQueueItem _$SyncQueueItemFromJson(Map<String, dynamic> json) =>
    SyncQueueItem(
      id: json['id'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      data: json['data'] as Map<String, dynamic>,
      status: json['status'] as String? ?? 'pending',
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      nextRetryAt: json['nextRetryAt'] == null
          ? null
          : DateTime.parse(json['nextRetryAt'] as String),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SyncQueueItemToJson(SyncQueueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'data': instance.data,
      'status': instance.status,
      'retryCount': instance.retryCount,
      'maxRetries': instance.maxRetries,
      'errorMessage': instance.errorMessage,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'nextRetryAt': instance.nextRetryAt?.toIso8601String(),
      'priority': instance.priority,
    };
