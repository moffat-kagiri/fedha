# budgets/serializers.py
from rest_framework import serializers
from .models import Budget, BudgetPeriod

class BudgetSerializer(serializers.ModelSerializer):
    """Serializer for Budget model."""
    remaining_amount = serializers.ReadOnlyField()
    spent_percentage = serializers.ReadOnlyField()
    is_over_budget = serializers.ReadOnlyField()
    days_remaining = serializers.ReadOnlyField()
    is_current = serializers.ReadOnlyField()
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    # ✅ FIXED: Accept as strings
    profile_id = serializers.CharField(write_only=True, required=False)
    category_id = serializers.CharField(write_only=True, required=False, allow_null=True, allow_blank=True)
    
    class Meta:
        model = Budget
        fields = [
            'id', 'profile', 'profile_id', 'category', 'category_id', 'category_name',
            'name', 'description',
            'budget_amount', 'spent_amount',
            'period', 'start_date', 'end_date',
            'is_active', 'is_synced',
            'created_at', 'updated_at',
            'remaining_amount', 'spent_percentage',
            'is_over_budget', 'days_remaining', 'is_current'
        ]
        read_only_fields = [
            'id', 'profile', 'created_at', 'updated_at'
        ]
    
    def validate(self, attrs):
        """Validate budget data."""
        profile_id = attrs.pop('profile_id', None)
        category_id = attrs.pop('category_id', None)
        
        # Handle profile_id
        if profile_id:
            from accounts.models import Profile
            try:
                import uuid
                uuid_obj = uuid.UUID(profile_id)
                profile = Profile.objects.get(id=uuid_obj)
                attrs['profile'] = profile
            except (ValueError, AttributeError, Profile.DoesNotExist):
                raise serializers.ValidationError({
                    'profile_id': f'Profile {profile_id} does not exist'
                })
        
        # Handle category_id as string
        if category_id is not None and category_id.strip():
            from categories.models import Category
            profile = attrs.get('profile')
            
            if not profile:
                raise serializers.ValidationError({
                    'category_id': 'Profile must be specified before category'
                })
            
            # Try UUID, then name
            category = None
            try:
                import uuid
                uuid_obj = uuid.UUID(category_id)
                category = Category.objects.filter(id=uuid_obj, profile=profile).first()
            except (ValueError, AttributeError):
                category = Category.objects.filter(
                    profile=profile,
                    name__iexact=category_id
                ).first()
            
            if not category:
                raise serializers.ValidationError({
                    'category_id': f'Category {category_id} not found'
                })
            
            attrs['category'] = category
        
        # Validate amounts
        budget_amount = attrs.get('budget_amount')
        start_date = attrs.get('start_date')
        end_date = attrs.get('end_date')
        
        if budget_amount and budget_amount <= 0:
            raise serializers.ValidationError({
                'budget_amount': 'Budget amount must be positive'
            })
        
        if start_date and end_date and start_date >= end_date:
            raise serializers.ValidationError({
                'end_date': 'End date must be after start date'
            })
        
        return attrs
        
class BudgetSummarySerializer(serializers.Serializer):
    """Serializer for budget summary."""
    total_budget = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_spent = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_remaining = serializers.DecimalField(max_digits=15, decimal_places=2)
    overall_percentage = serializers.FloatField()
    active_budgets = serializers.IntegerField()
    over_budget_count = serializers.IntegerField()

