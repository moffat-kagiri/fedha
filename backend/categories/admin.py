# categories/admin.py
from django.contrib import admin
from .models import Category, DefaultCategory


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    """Admin interface for Category model."""
    list_display = ['name', 'type', 'profile', 'is_active', 'is_global', 'created_at']
    list_filter = ['type', 'is_active', 'created_at']
    search_fields = ['name', 'description', 'profile__email', 'profile__phone_number']
    readonly_fields = ['created_at', 'updated_at']
    
    def is_global(self, obj):
        return obj.profile is None
    is_global.boolean = True
    is_global.short_description = 'Global Category'


@admin.register(DefaultCategory)
class DefaultCategoryAdmin(admin.ModelAdmin):
    """Admin interface for DefaultCategory model."""
    list_display = ['name', 'type', 'color', 'icon']
    list_filter = ['type']
    search_fields = ['name', 'description']
    