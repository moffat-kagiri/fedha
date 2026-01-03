# backend/categories/apps.py
from django.apps import AppConfig


class CategoriesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'categories'
    
    def ready(self):
        """Import signals when app is ready."""
        # Import signals here if you add any
        pass