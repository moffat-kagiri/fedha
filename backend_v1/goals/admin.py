# goals/admin.py
from django.contrib import admin
from .models import Goal


@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    """Admin interface for Goal model."""
    list_display = ['name', 'profile', 'target_amount', 'current_amount', 
                   'progress_percentage', 'status', 'target_date']
    list_filter = ['status', 'goal_type', 'priority', 'created_at']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at', 'updated_at', 'progress_percentage', 
                      'remaining_amount', 'days_remaining']
    date_hierarchy = 'target_date'
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('profile', 'name', 'description')
        }),
        ('Goal Details', {
            'fields': ('goal_type', 'priority', 'status')
        }),
        ('Amounts', {
            'fields': ('target_amount', 'current_amount', 'progress_percentage', 'remaining_amount')
        }),
        ('Dates', {
            'fields': ('target_date', 'completed_date', 'days_remaining')
        }),
        ('Sync', {
            'fields': ('is_synced',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

