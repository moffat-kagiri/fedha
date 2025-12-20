# budgets/admin.py
from django.contrib import admin
from .models import Budget


@admin.register(Budget)
class BudgetAdmin(admin.ModelAdmin):
    """Admin interface for Budget model."""
    list_display = ['name', 'profile', 'budget_amount', 'spent_amount',
                   'spent_percentage', 'period', 'is_active', 'start_date']
    list_filter = ['period', 'is_active', 'created_at']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at', 'updated_at', 'remaining_amount', 
                      'spent_percentage', 'is_over_budget', 'days_remaining']
    date_hierarchy = 'start_date'
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('profile', 'category', 'name', 'description')
        }),
        ('Budget Details', {
            'fields': ('budget_amount', 'spent_amount', 'remaining_amount', 'spent_percentage')
        }),
        ('Period', {
            'fields': ('period', 'start_date', 'end_date', 'days_remaining')
        }),
        ('Status', {
            'fields': ('is_active', 'is_over_budget', 'is_synced')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

