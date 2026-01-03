# goals/serializers.py
from rest_framework import serializers
from django.utils import timezone
from .models import Goal, GoalType, GoalStatus


class GoalSerializer(serializers.ModelSerializer):
    """Serializer for Goal model."""
    progress_percentage = serializers.ReadOnlyField()
    remaining_amount = serializers.ReadOnlyField()
    is_completed = serializers.ReadOnlyField()
    is_overdue = serializers.ReadOnlyField()
    days_remaining = serializers.ReadOnlyField()
    
    # Add write-only fields for Flutter integration
    profile_id = serializers.UUIDField(write_only=True)
    due_date = serializers.DateTimeField(write_only=True, source='target_date')
    is_completed_field = serializers.BooleanField(
        write_only=True, 
        required=False, 
        source='goal_status'  # ✅ Changed from 'status' to 'goal_status' to match db_column
    )
    goal_type = serializers.ChoiceField(
        choices=GoalType.choices,
        write_only=True,
        required=False,
        default=GoalType.SAVINGS
    )
    
    class Meta:
        model = Goal
        fields = [
            'id', 'profile', 'profile_id', 'name', 'description',
            'target_amount', 'current_amount',
            'target_date', 'due_date', 'completed_date',
            'goal_type', 'status', 'is_completed_field',  # status maps to goal_status in DB
            'created_at', 'updated_at', 'remote_id',  # ✅ Added remote_id, removed is_synced
            'progress_percentage', 'remaining_amount',
            'is_completed', 'is_overdue', 'days_remaining'
        ]
        read_only_fields = [
            'id', 'profile', 'completed_date', 'status', 'goal_type',
            'created_at', 'updated_at', 'remote_id'  # ✅ remote_id is read-only from API
        ]
        extra_kwargs = {
            'status': {'source': 'goal_status'},  # Map serializer 'status' to model 'goal_status' field
        }
    
    def validate(self, attrs):
        """Validate goal data and handle field conversions."""
        # Remove write-only fields before validation
        profile_id = attrs.pop('profile_id', None)
        due_date = attrs.pop('due_date', None)
        is_completed_field = attrs.pop('is_completed_field', None)
        goal_type = attrs.pop('goal_type', None)
        
        # Map due_date to target_date
        if due_date is not None:
            attrs['target_date'] = due_date
        
        # Map is_completed_field to status enum
        if is_completed_field is not None:
            # Note: status field in model maps to goal_status column in DB
            attrs['goal_status'] = GoalStatus.COMPLETED if is_completed_field else GoalStatus.ACTIVE
        
        # Map goal_type if provided
        if goal_type is not None:
            attrs['goal_type'] = goal_type
        
        # Handle profile_id
        if profile_id:
            from accounts.models import Profile
            try:
                profile = Profile.objects.get(id=profile_id)
                attrs['profile'] = profile
            except Profile.DoesNotExist:
                raise serializers.ValidationError({
                    'profile_id': f'Profile with id {profile_id} does not exist'
                })
        
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
        
        # Ensure current_amount doesn't exceed target_amount
        if target_amount and current_amount > target_amount:
            attrs['current_amount'] = target_amount
            # Auto-complete if exceeds target
            if 'goal_status' not in attrs or attrs['goal_status'] != GoalStatus.COMPLETED:
                attrs['goal_status'] = GoalStatus.COMPLETED
                attrs['completed_date'] = timezone.now()
        
        # Auto-set completed_date if status is COMPLETED
        if attrs.get('goal_status') == GoalStatus.COMPLETED and not attrs.get('completed_date'):
            attrs['completed_date'] = timezone.now()
        
        # Handle remote_id from Flutter if provided
        # In your Flutter app, you might send remote_id for updates
        # But for new creations, remote_id will be null
        
        return attrs
    
    def create(self, validated_data):
        """Override create to ensure profile is set."""
        # Profile should already be in validated_data from validate method
        if 'profile' not in validated_data:
            # If somehow profile is missing, try to get from request
            request = self.context.get('request')
            if request and hasattr(request, 'user'):
                from accounts.models import Profile
                try:
                    profile = Profile.objects.get(user=request.user)
                    validated_data['profile'] = profile
                except Profile.DoesNotExist:
                    pass
        
        return super().create(validated_data)


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
        