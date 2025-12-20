# invoicing/admin.py
from django.contrib import admin
from .models import Client, Invoice, Loan


@admin.register(Client)
class ClientAdmin(admin.ModelAdmin):
    """Admin interface for Client model."""
    list_display = ['name', 'email', 'phone', 'profile', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'email', 'phone']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    """Admin interface for Invoice model."""
    list_display = ['invoice_number', 'client', 'amount', 'status', 
                   'issue_date', 'due_date', 'is_overdue']
    list_filter = ['status', 'issue_date', 'due_date']
    search_fields = ['invoice_number', 'description', 'client__name']
    date_hierarchy = 'issue_date'
    readonly_fields = ['created_at', 'updated_at', 'is_overdue', 'days_until_due']
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('profile', 'client', 'invoice_number')
        }),
        ('Amount', {
            'fields': ('amount', 'currency')
        }),
        ('Dates', {
            'fields': ('issue_date', 'due_date', 'days_until_due')
        }),
        ('Status', {
            'fields': ('status', 'is_overdue', 'is_active')
        }),
        ('Details', {
            'fields': ('description', 'notes')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(Loan)
class LoanAdmin(admin.ModelAdmin):
    """Admin interface for Loan model."""
    list_display = ['name', 'profile', 'principal_amount', 'interest_rate',
                   'interest_model', 'start_date', 'end_date', 'is_active']
    list_filter = ['interest_model', 'start_date']
    search_fields = ['name']
    date_hierarchy = 'start_date'
    readonly_fields = ['created_at', 'updated_at', 'is_active']

