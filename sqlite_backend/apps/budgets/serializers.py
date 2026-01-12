# apps/budgets/serializers.py
from rest_framework import serializers
from .models import Budget

class BudgetSerializer(serializers.ModelSerializer):
    """Serializer for Budget model - matches Flutter Budget"""
    
    # Computed fields (read-only)
    remaining_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    spent_percentage = serializers.DecimalField(
        max_digits=5, decimal_places=2, read_only=True
    )
    is_over_budget = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Budget
        fields = [
            'id', 'name', 'description', 'budget_amount', 'spent_amount',
            'category_id', 'profile_id', 'period', 'start_date', 'end_date',
            'is_active', 'is_synced', 'created_at', 'updated_at',
            # Computed fields
            'remaining_amount', 'spent_percentage', 'is_over_budget', 
            'days_remaining'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        """Create budget for authenticated user"""
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class BudgetSummarySerializer(serializers.Serializer):
    """Serializer for budget summary/overview"""
    total_budget = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_spent = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_remaining = serializers.DecimalField(max_digits=12, decimal_places=2)
    overall_percentage = serializers.DecimalField(max_digits=5, decimal_places=2)
    budgets_count = serializers.IntegerField()
    over_budget_count = serializers.IntegerField()
    active_budgets = BudgetSerializer(many=True)