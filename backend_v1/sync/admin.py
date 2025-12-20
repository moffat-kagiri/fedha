# sync/admin.py
from django.contrib import admin
from .models import SyncQueue


@admin.register(SyncQueue)
class SyncQueueAdmin(admin.ModelAdmin):
    """Admin interface for SyncQueue model."""
    list_display = ['profile', 'action', 'entity_type', 'status', 
                   'retry_count', 'priority', 'created_at']
    list_filter = ['action', 'entity_type', 'status', 'created_at']
    search_fields = ['entity_id', 'error_message']
    readonly_fields = ['created_at', 'updated_at', 'can_retry', 'should_retry']
    actions = ['process_selected', 'reset_selected']
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('profile', 'action', 'entity_type', 'entity_id')
        }),
        ('Data', {
            'fields': ('data',),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('status', 'priority')
        }),
        ('Retry Info', {
            'fields': ('retry_count', 'max_retries', 'next_retry_at', 
                      'can_retry', 'should_retry')
        }),
        ('Error', {
            'fields': ('error_message',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def process_selected(self, request, queryset):
        """Process selected sync items."""
        count = 0
        for item in queryset:
            if item.should_retry:
                try:
                    item.mark_processing()
                    # Process logic here
                    item.mark_completed()
                    count += 1
                except Exception as e:
                    item.mark_failed(str(e))
        self.message_user(request, f"{count} items processed")
    process_selected.short_description = "Process selected items"
    
    def reset_selected(self, request, queryset):
        """Reset selected sync items to pending."""
        count = queryset.update(
            status='pending',
            retry_count=0,
            error_message=None,
            next_retry_at=None
        )
        self.message_user(request, f"{count} items reset to pending")
    reset_selected.short_description = "Reset selected items to pending"

