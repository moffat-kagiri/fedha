# transactions/admin.py
from django.contrib import admin
from .models import Transaction, PendingTransaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    """Admin interface for Transaction model."""
    list_display = ['profile', 'amount', 'type', 'category', 'transaction_date', 'status']
    list_filter = ['type', 'status', 'payment_method', 'transaction_date']
    search_fields = ['description', 'notes', 'reference', 'recipient']
    date_hierarchy = 'transaction_date'
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('profile', 'category', 'goal')
        }),
        ('Transaction Details', {
            'fields': ('amount', 'type', 'status', 'payment_method', 'transaction_date')
        }),
        ('Description', {
            'fields': ('description', 'notes', 'reference', 'recipient')
        }),
        ('Flags', {
            'fields': ('is_expense', 'is_pending', 'is_recurring', 'is_synced')
        }),
        ('SMS Source', {
            'fields': ('sms_source',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(PendingTransaction)
class PendingTransactionAdmin(admin.ModelAdmin):
    """Admin interface for PendingTransaction model."""
    list_display = ['profile', 'amount', 'type', 'status', 'confidence', 'created_at']
    list_filter = ['type', 'status', 'created_at']
    search_fields = ['description', 'raw_text']
    readonly_fields = ['created_at', 'updated_at']
    actions = ['approve_selected', 'reject_selected']
    
    def approve_selected(self, request, queryset):
        """Approve selected pending transactions."""
        count = 0
        for pending in queryset:
            if pending.status == 'pending':
                pending.approve()
                count += 1
        self.message_user(request, f"{count} transactions approved")
    approve_selected.short_description = "Approve selected pending transactions"
    
    def reject_selected(self, request, queryset):
        """Reject selected pending transactions."""
        count = 0
        for pending in queryset:
            if pending.status == 'pending':
                pending.reject()
                count += 1
        self.message_user(request, f"{count} transactions rejected")
    reject_selected.short_description = "Reject selected pending transactions"

