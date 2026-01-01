# sync/serializers.py
from rest_framework import serializers
from .models import SyncQueue, SyncAction, SyncStatus


class SyncQueueSerializer(serializers.ModelSerializer):
    """Serializer for SyncQueue model."""
    can_retry = serializers.ReadOnlyField()
    should_retry = serializers.ReadOnlyField()
    
    class Meta:
        model = SyncQueue
        fields = [
            'id', 'profile', 'action', 'entity_type', 'entity_id',
            'data', 'status', 'retry_count', 'max_retries',
            'error_message', 'priority', 'next_retry_at',
            'created_at', 'updated_at',
            'can_retry', 'should_retry'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']


class SyncStatusSerializer(serializers.Serializer):
    """Serializer for sync status response."""
    total_pending = serializers.IntegerField()
    total_processing = serializers.IntegerField()
    total_completed = serializers.IntegerField()
    total_failed = serializers.IntegerField()
    last_sync = serializers.DateTimeField(allow_null=True)


class BulkSyncRequestSerializer(serializers.Serializer):
    """Serializer for bulk sync requests."""
    transactions = serializers.ListField(child=serializers.DictField(), required=False)
    goals = serializers.ListField(child=serializers.DictField(), required=False)
    budgets = serializers.ListField(child=serializers.DictField(), required=False)
    categories = serializers.ListField(child=serializers.DictField(), required=False)
