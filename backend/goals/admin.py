# goals/admin.py
from django.contrib import admin
from .models import Goal


@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    list_display = ('name', 'profile', 'goal_type', 'status', 'target_amount', 'current_amount', 'progress_percentage', 'target_date', 'created_at')
    list_filter = ('goal_type', 'status', 'target_date')  # Removed 'is_synced', added 'target_date'
    search_fields = ('name', 'description', 'profile__user__email', 'remote_id')
    readonly_fields = ('progress_percentage', 'remaining_amount', 'is_completed', 'is_overdue', 'days_remaining', 'created_at', 'updated_at', 'remote_id')
    fieldsets = (
        ('Basic Information', {
            'fields': ('profile', 'name', 'description', 'goal_type', 'status')
        }),
        ('Financial Details', {
            'fields': ('target_amount', 'current_amount', 'currency', 'progress_percentage', 'remaining_amount')
        }),
        ('Dates', {
            'fields': ('target_date', 'completed_date', 'last_contribution_date', 'projected_completion_date')
        }),
        ('Tracking', {
            'fields': ('contribution_count', 'average_contribution', 'days_ahead_behind', 'goal_group')
        }),
        ('Sync & IDs', {
            'fields': ('remote_id', 'linked_category_id')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at')  # Removed 'is_synced'
        }),
    )
    
    def progress_percentage(self, obj):
        return f"{obj.progress_percentage:.1f}%"
    progress_percentage.short_description = 'Progress'
    
    def remaining_amount(self, obj):
        return f"KES {obj.remaining_amount:,.2f}"
    remaining_amount.short_description = 'Remaining'