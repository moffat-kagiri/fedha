# goals/serializers.py
from rest_framework import serializers
from .models import Goal, GoalType, GoalStatus, GoalPriority


class GoalSerializer(serializers.ModelSerializer):
    """Serializer for Goal model."""
    progress_percentage = serializers.ReadOnlyField()
    remaining_amount = serializers.ReadOnlyField()
    is_completed = serializers.ReadOnlyField()
    is_overdue = serializers.ReadOnlyField()
    days_remaining = serializers.ReadOnlyField()
    
    class Meta:
        model = Goal
        fields = [
            'id', 'profile', 'name', 'description',
            'target_amount', 'current_amount',
            'target_date', 'completed_date',
            'goal_type', 'status', 'priority',
            'is_synced', 'created_at', 'updated_at',
            'progress_percentage', 'remaining_amount',
            'is_completed', 'is_overdue', 'days_remaining'
        ]
        read_only_fields = [
            'id', 'profile', 'completed_date',
            'created_at', 'updated_at'
        ]
    
    def validate(self, attrs):
        """Validate goal data."""
        target_amount = attrs.get('target_amount')
        current_amount = attrs.get('current_amount', 0)
        
        if target_amount and target_amount <= 0:
            raise serializers.ValidationError({
                'target_amount': 'Target amount must be positive'
            })
        
        if current_amount and current_amount < 0:
            raise serializers.ValidationError({
                'current_amount': 'Current amount cannot be negative'
            })
        
        return attrs


class GoalContributionSerializer(serializers.Serializer):
    """Serializer for goal contributions."""
    amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    
    def validate_amount(self, value):
        """Validate contribution amount."""
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive")
        return value


class BulkGoalSerializer(serializers.Serializer):
    """Serializer for bulk goal sync."""
    goals = GoalSerializer(many=True)
    
    def create(self, validated_data):
        """Create or update multiple goals."""
        goals_data = validated_data.get('goals', [])
        created = []
        updated = []
        
        for goal_data in goals_data:
            goal_id = goal_data.get('id')
            
            if goal_id:
                # Update existing goal
                try:
                    goal = Goal.objects.get(id=goal_id)
                    for attr, value in goal_data.items():
                        setattr(goal, attr, value)
                    goal.save()
                    updated.append(goal)
                except Goal.DoesNotExist:
                    # Create new goal with specified ID
                    goal = Goal.objects.create(**goal_data)
                    created.append(goal)
            else:
                # Create new goal
                goal = Goal.objects.create(**goal_data)
                created.append(goal)
        
        return {
            'created': created,
            'updated': updated
        }

