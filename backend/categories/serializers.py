# backend/categories/serializers.py
from rest_framework import serializers
from .models import Category, CategoryType


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model."""
    profile_id = serializers.UUIDField(write_only=True, required=False)
    
    class Meta:
        model = Category
        fields = [
            'id', 'profile', 'profile_id', 'name', 'description',
            'color', 'icon', 'type', 'is_active', 'is_synced',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']
        extra_kwargs = {
            'color': {'default': '#2196F3'},
            'icon': {'default': 'category'},
            'type': {'default': CategoryType.EXPENSE},
        }
    
    def validate(self, attrs):
        """Validate category data."""
        profile_id = attrs.pop('profile_id', None)
        
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
        
        # Validate color format (hex color)
        color = attrs.get('color')
        if color and not color.startswith('#'):
            attrs['color'] = f"#{color}"
        
        return attrs
    
    def create(self, validated_data):
        """Override create to ensure profile is set."""
        if 'profile' not in validated_data:
            request = self.context.get('request')
            if request and hasattr(request, 'user'):
                from accounts.models import Profile
                try:
                    profile = Profile.objects.get(user=request.user)
                    validated_data['profile'] = profile
                except Profile.DoesNotExist:
                    pass
        
        return super().create(validated_data)


class CategorySummarySerializer(serializers.Serializer):
    """Serializer for category spending summary."""
    category_id = serializers.UUIDField()
    category_name = serializers.CharField()
    category_type = serializers.CharField()
    total_amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    transaction_count = serializers.IntegerField()
    percentage = serializers.FloatField()