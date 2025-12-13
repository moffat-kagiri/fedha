from django.contrib import admin
from .models import User

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['email', 'first_name', 'last_name', 'date_joined', 'is_active']
    search_fields = ['email', 'first_name', 'last_name']
    list_filter = ['is_active', 'date_joined']