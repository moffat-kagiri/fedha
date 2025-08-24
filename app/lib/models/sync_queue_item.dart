import 'package:json_annotation/json_annotation.dart';
part 'sync_queue_item.g.dart';

@JsonSerializable()
class SyncQueueItem {
  String id;
  String action; // 'create', 'update', 'delete'
  String entityType; // 'transaction', 'goal', 'budget', etc.
  String entityId;
  Map<String, dynamic> data;
  String status; // 'pending', 'processing', 'completed', 'failed'
  int retryCount;
  int maxRetries;
  String? errorMessage;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? nextRetryAt;
  int priority; // Higher number = higher priority

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.data,
    this.status = 'pending',
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.nextRetryAt,
    this.priority = 0,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get canRetry => retryCount < maxRetries && !isCompleted;
  bool get shouldRetry => canRetry && (nextRetryAt == null || DateTime.now().isAfter(nextRetryAt!));

  Duration get nextRetryDelay {
    // Exponential backoff: 2^retryCount seconds
    return Duration(seconds: 1 << retryCount);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'data': data,
      'status': status,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'priority': priority,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'] ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      status: json['status'] ?? 'pending',
      retryCount: json['retry_count'] ?? 0,
      maxRetries: json['max_retries'] ?? 3,
      errorMessage: json['error_message'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
      nextRetryAt: json['next_retry_at'] != null 
        ? DateTime.parse(json['next_retry_at']) 
        : null,
      priority: json['priority'] ?? 0,
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? data,
    String? status,
    int? retryCount,
    int? maxRetries,
    String? errorMessage,
    DateTime? nextRetryAt,
    int? priority,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      priority: priority ?? this.priority,
      updatedAt: DateTime.now(),
    );
  }

  void markAsProcessing() {
    status = 'processing';
    updatedAt = DateTime.now();
  }

  void markAsCompleted() {
    status = 'completed';
    updatedAt = DateTime.now();
  }

  void markAsFailed(String error) {
    status = 'failed';
    errorMessage = error;
    retryCount++;
    updatedAt = DateTime.now();
    
    if (canRetry) {
      nextRetryAt = DateTime.now().add(nextRetryDelay);
      status = 'pending'; // Reset to pending for retry
    }
  }

  @override
  String toString() {
    return 'SyncQueueItem(id: $id, action: $action, entity: $entityType:$entityId, status: $status, retries: $retryCount/$maxRetries)';
  }
}

part 'budget.g.dart';

@JsonSerializable()
class Budget {
   String id;
   String name;
   String? description;
   double budgetAmount;
   // … other fields, getters, constructors, toJson/fromJson, etc.
}
