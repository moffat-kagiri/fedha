# categories/models.py
import uuid
from django.db import models
from django.utils import timezone
from django.conf import settings


class CategoryType(models.TextChoices):
    INCOME = 'income', 'Income'
    EXPENSE = 'expense', 'Expense'
    SAVINGS = 'savings', 'Savings'


class Category(models.Model):
    """
    Transaction categories.
    Can be profile-specific or global (when profile is None).
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='categories',
        null=True,
        blank=True,
        help_text='If null, this is a global/default category'
    )
    
    name = models.CharField(max_length=255)  # Match DB: 255 chars
    description = models.TextField(null=True, blank=True)
    color = models.CharField(max_length=7, null=True, blank=True)  # Nullable in DB
    icon = models.CharField(max_length=100, null=True, blank=True, db_column='icon_name')  # Map to icon_name
    type = models.CharField(
        max_length=20,
        choices=CategoryType.choices,
        default=CategoryType.EXPENSE
    )
    
    is_default = models.BooleanField(default=False)  # From existing DB
    is_active = models.BooleanField(default=True)  # New field
    is_synced = models.BooleanField(default=False)  # New field
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'categories'
        ordering = ['name']
        verbose_name_plural = 'Categories'
        indexes = [
            models.Index(fields=['profile'], name='idx_categories_profile_id'),
            models.Index(fields=['type'], name='idx_categories_type'),
            models.Index(fields=['is_active'], name='categories_is_active_idx'),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['profile', 'name'],
                name='unique_profile_category_name'
            )
        ]
    
    def __str__(self):
        return f"{self.name} ({self.type})"
    
    @property
    def is_global(self):
        """Check if this is a global category."""
        return self.profile is None
    
    @classmethod
    def get_or_create_default_categories(cls, profile):
        """Create default categories for a new profile."""
        default_categories = [
            # Income categories
            {'name': 'Salary', 'type': CategoryType.INCOME, 'color': '#4CAF50', 'icon': 'attach_money'},
            {'name': 'Business', 'type': CategoryType.INCOME, 'color': '#2196F3', 'icon': 'business'},
            {'name': 'Investment', 'type': CategoryType.INCOME, 'color': '#9C27B0', 'icon': 'trending_up'},
            {'name': 'Gift', 'type': CategoryType.INCOME, 'color': '#FF9800', 'icon': 'card_giftcard'},
            {'name': 'Other Income', 'type': CategoryType.INCOME, 'color': '#607D8B', 'icon': 'add_circle'},
            
            # Expense categories
            {'name': 'Food', 'type': CategoryType.EXPENSE, 'color': '#FF5722', 'icon': 'restaurant'},
            {'name': 'Transport', 'type': CategoryType.EXPENSE, 'color': '#00BCD4', 'icon': 'directions_car'},
            {'name': 'Utilities', 'type': CategoryType.EXPENSE, 'color': '#FFC107', 'icon': 'lightbulb'},
            {'name': 'Entertainment', 'type': CategoryType.EXPENSE, 'color': '#E91E63', 'icon': 'movie'},
            {'name': 'Healthcare', 'type': CategoryType.EXPENSE, 'color': '#F44336', 'icon': 'local_hospital'},
            {'name': 'Groceries', 'type': CategoryType.EXPENSE, 'color': '#8BC34A', 'icon': 'shopping_cart'},
            {'name': 'Dining Out', 'type': CategoryType.EXPENSE, 'color': '#FF6F00', 'icon': 'local_dining'},
            {'name': 'Shopping', 'type': CategoryType.EXPENSE, 'color': '#673AB7', 'icon': 'shopping_bag'},
            {'name': 'Education', 'type': CategoryType.EXPENSE, 'color': '#3F51B5', 'icon': 'school'},
            {'name': 'Rent', 'type': CategoryType.EXPENSE, 'color': '#795548', 'icon': 'home'},
            {'name': 'Other Expense', 'type': CategoryType.EXPENSE, 'color': '#9E9E9E', 'icon': 'remove_circle'},
        ]
        
        created_categories = []
        for cat_data in default_categories:
            category, created = cls.objects.get_or_create(
                profile=profile,
                name=cat_data['name'],
                defaults={
                    'type': cat_data['type'],
                    'color': cat_data['color'],
                    'icon': cat_data['icon'],
                    'is_active': True,
                    'is_default': False,
                }
            )
            if created:
                created_categories.append(category)
        
        return created_categories


class DefaultCategory(models.Model):
    """
    Template categories that are copied for new users.
    """
    name = models.CharField(max_length=255)
    description = models.TextField(null=True, blank=True)
    color = models.CharField(max_length=7)
    icon = models.CharField(max_length=100)
    type = models.CharField(max_length=20)
    
    class Meta:
        db_table = 'default_categories'
        verbose_name_plural = 'Default Categories'
    
    def __str__(self):
        return f"{self.name} ({self.type})"