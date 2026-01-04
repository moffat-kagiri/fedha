from django.db.models.signals import post_save
from django.dispatch import receiver
from django.db import transaction
from .models import Profile

@receiver(post_save, sender=Profile)
def create_default_categories(sender, instance, created, **kwargs):
    """Create default categories for new profiles."""
    if created:
        try:
            # Use transaction.on_commit to ensure categories table exists
            from categories.models import Category
            
            # Check if the Category table exists
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'categories')")
                table_exists = cursor.fetchone()[0]
            
            if table_exists:
                Category.get_or_create_default_categories(instance)
        except Exception as e:
            # Log the error but don't crash
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"Could not create default categories for {instance}: {e}")