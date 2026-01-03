# goals/serializers.py - CLEANED VERSION
from rest_framework import serializers
from django.utils import timezone
from .models import Goal, GoalType, GoalStatus

class GoalSerializer(serializers.ModelSerializer):
    """Serializer for Goal model."""
    progress_percentage = serializers.ReadOnlyField()
    remaining_amount = serializers.ReadOnlyField()
    is_overdue = serializers.ReadOnlyField()
    days_remaining = serializers.ReadOnlyField()
    
    # ✅ FIXED: Accept profile_id as string
    profile_id = serializers.CharField(write_only=True)
    due_date = serializers.DateTimeField(write_only=True, source='target_date', required=False)
    
    status = serializers.ChoiceField(
        choices=GoalStatus.choices,
        write_only=True,
        required=False,
        default=GoalStatus.ACTIVE
    )
    
    goal_type = serializers.ChoiceField(
        choices=GoalType.choices,
        write_only=True,
        required=True
    )
    
    goal_status = serializers.CharField(source='status', read_only=True)
    
    class Meta:
        model = Goal
        fields = [
            'id', 'profile', 'profile_id', 'name', 'description',
            'goal_type', 'status', 'goal_status', 'target_amount', 'current_amount',
            'currency', 'target_date', 'due_date', 'last_contribution_date',
            'contribution_count', 'average_contribution', 'linked_category',
            'projected_completion_date', 'days_ahead_behind', 'goal_group',
            'created_at', 'updated_at', 'completed_date', 'remote_id',
            'progress_percentage', 'remaining_amount', 'is_overdue', 'days_remaining'
        ]
        read_only_fields = [
            'id', 'profile', 'goal_status', 'created_at', 'updated_at', 'completed_date',
            'last_contribution_date', 'contribution_count', 'average_contribution',
            'projected_completion_date', 'days_ahead_behind',
            'progress_percentage', 'remaining_amount', 'is_overdue', 'days_remaining'
        ]
        extra_kwargs = {
            'currency': {'default': 'KES'},
            'current_amount': {'default': 0.0},
            'linked_category': {'required': False, 'allow_null': True},
        }
    
    def validate(self, attrs):
        """Validate goal data and handle field conversions."""
        # Remove write-only fields
        profile_id = attrs.pop('profile_id', None)
        due_date = attrs.pop('due_date', None)
        
        # Map due_date to target_date
        if due_date is not None:
            attrs['target_date'] = due_date
        
        # ✅ FIXED: Handle profile_id as STRING (UUID or name)
        if profile_id:
            from accounts.models import Profile
            
            # Try as UUID first
            profile = None
            try:
                import uuid
                uuid_obj = uuid.UUID(profile_id)
                profile = Profile.objects.filter(id=uuid_obj).first()
            except (ValueError, AttributeError):
                pass
            
            # Try as email if UUID fails
            if not profile:
                profile = Profile.objects.filter(email=profile_id).first()
            
            if not profile:
                raise serializers.ValidationError({
                    'profile_id': f'Profile {profile_id} does not exist'
                })
            
            attrs['profile'] = profile
        
        # Validate amounts
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
            remote_id = goal_data.get('remote_id')
            
            # Try to find goal by remote_id first (for sync operations)
            goal = None
            if remote_id:
                try:
                    goal = Goal.objects.get(remote_id=remote_id)
                except Goal.DoesNotExist:
                    pass
            
            # If not found by remote_id, try by local id
            if not goal and goal_id:
                try:
                    goal = Goal.objects.get(id=goal_id)
                except Goal.DoesNotExist:
                    pass
            
            if goal:
                # Update existing goal
                for attr, value in goal_data.items():
                    if attr not in ['id', 'remote_id']:  # Don't update primary keys
                        setattr(goal, attr, value)
                goal.save()
                updated.append(goal)
            else:
                # Create new goal
                goal = Goal.objects.create(**goal_data)
                created.append(goal)
        
        return {
            'created': created,
            'updated': updated
        }