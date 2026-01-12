from django.contrib import admin
from .models import Transaction, Category, TransactionCandidate

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['date', 'amount', 'type', 'category_id', 'user']
    list_filter = ['type', 'date', 'is_synced']
    search_fields = ['description', 'category_id']

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'user', 'is_active']
    list_filter = ['type', 'is_active']