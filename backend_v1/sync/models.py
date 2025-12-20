# sync/models.py
import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta


class SyncAction(models.TextChoices):
    CREATE = 'create', 'Create'
    UPDATE = 'update', 'Update'
    DELETE = 'delete', 'Delete'


class SyncStatus(models.TextChoices):
    PENDING = 'pending', 'Pending'
    PROCESSING = 'processing', 'Processing'
    COMPLETED = 'completed', 'Completed'
    FAILED = 'failed', 'Failed'


class SyncQueue(models.Model):
    """Queue for syncing offline changes to server."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='sync_queue'
    )
    
    action = models.CharField(max_length=20, choices=SyncAction.choices)
    entity_type = models.CharField(max_length=50)
    entity_id = models.UUIDField()
    data = models.JSONField()
    
    status = models.CharField(
        max_length=20,
        choices=SyncStatus.choices,
        default=SyncStatus.PENDING
    )
    
    retry_count = models.IntegerField(default=0)
    max_retries = models.IntegerField(default=3)
    error_message = models.TextField(null=True, blank=True)
    priority = models.IntegerField(default=0)
    
    next_retry_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'sync_queue'
        ordering = ['-priority', 'created_at']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['status']),
            models.Index(fields=['-priority']),
            models.Index(fields=['next_retry_at']),
        ]
    
    def __str__(self):
        return f"{self.action} {self.entity_type}:{self.entity_id}"
    
    @property
    def can_retry(self):
        """Check if item can be retried."""
        return (self.retry_count < self.max_retries and 
                self.status != SyncStatus.COMPLETED)
    
    @property
    def should_retry(self):
        """Check if item should be retried now."""
        if not self.can_retry:
            return False
        if self.next_retry_at is None:
            return True
        return timezone.now() >= self.next_retry_at
    
    def mark_processing(self):
        """Mark item as processing."""
        self.status = SyncStatus.PROCESSING
        self.save(update_fields=['status', 'updated_at'])
    
    def mark_completed(self):
        """Mark item as completed."""
        self.status = SyncStatus.COMPLETED
        self.save(update_fields=['status', 'updated_at'])
    
    def mark_failed(self, error_message):
        """Mark item as failed and schedule retry."""
        self.status = SyncStatus.FAILED
        self.error_message = error_message
        self.retry_count += 1
        
        if self.can_retry:
            # Exponential backoff
            delay_seconds = 2 ** self.retry_count
            self.next_retry_at = timezone.now() + timedelta(seconds=delay_seconds)
            self.status = SyncStatus.PENDING
        
        self.save(update_fields=[
            'status', 'error_message', 'retry_count',
            'next_retry_at', 'updated_at'
        ])

