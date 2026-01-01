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
    
    # Add category name for easier display
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = Budget
        fields = [
            'id', 'profile', 'category', 'category_name',
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

