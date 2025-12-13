# apps/goals/serializers.py
from rest_framework import serializers
from .models import Goal

class GoalSerializer(serializers.ModelSerializer):
    """Serializer for Goal model - matches Flutter Goal"""
    
    # Computed fields (read-only)
    progress_percentage = serializers.DecimalField(
        max_digits=5, decimal_places=2, read_only=True
    )
    is_completed = serializers.BooleanField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True)
    amount_needed = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    daily_savings_needed = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    monthly_savings_needed = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    
    class Meta:
        model = Goal
        fields = [
            'id', 'name', 'description', 'target_amount', 'current_amount',
            'target_date', 'completed_date', 'profile_id', 'goal_type',
            'status', 'priority', 'is_synced', 'created_at', 'updated_at',
            # Computed fields
            'progress_percentage', 'is_completed', 'is_overdue',
            'days_remaining', 'amount_needed', 'daily_savings_needed',
            'monthly_savings_needed'
        ]
        read_only_fields = [
            'id', 'created_at', 'updated_at', 'completed_date'
        ]
    
    def create(self, validated_data):
        """Create goal for authenticated user"""
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class GoalContributionSerializer(serializers.Serializer):
    """Serializer for adding contribution to goal"""
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=True)
    note = serializers.CharField(required=False, allow_blank=True)


class GoalSummarySerializer(serializers.Serializer):
    """Serializer for goal summary/overview"""
    total_target = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_saved = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_remaining = serializers.DecimalField(max_digits=12, decimal_places=2)
    overall_progress = serializers.DecimalField(max_digits=5, decimal_places=2)
    goals_count = serializers.IntegerField()
    completed_count = serializers.IntegerField()
    active_count = serializers.IntegerField()
    overdue_count = serializers.IntegerField()
    goals = GoalSerializer(many=True)