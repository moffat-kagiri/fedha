# transactions/serializers.py
from rest_framework import serializers
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
import json

class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model."""
    profile_id = serializers.UUIDField(write_only=True)
    
    # category field accepts string names
    category = serializers.CharField(write_only=True, required=False, allow_null=True)
    category_readable = serializers.CharField(source='category.name', read_only=True)
    
    goal_id = serializers.UUIDField(write_only=True, required=False, allow_null=True)
    amount_minor = serializers.IntegerField(write_only=True)
    date = serializers.DateTimeField(write_only=True)
    transaction_type = serializers.ChoiceField(
        choices=TransactionType.choices, 
        write_only=True, 
        source='type'
    )
    is_expense = serializers.BooleanField(required=False)
    
    # Tag handling: accept as list, store as comma-separated string
    tags = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        default=list,
        write_only=True
    )
    tags_list = serializers.ListField(
        child=serializers.CharField(max_length=50),
        read_only=True
    )
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'profile_id', 'category', 'category_readable',
            'goal', 'goal_id', 'amount', 'amount_minor', 'type', 'transaction_type',
            'status', 'payment_method', 'description', 'notes', 'reference', 
            'recipient', 'sms_source', 'is_expense', 'is_pending', 'is_recurring',
            'is_synced', 'date', 'created_at', 'updated_at', 'currency',
            'tags', 'tags_list', 'merchant_name', 'merchant_category',
            'location', 'latitude', 'longitude', 'is_flagged', 'anomaly_score',
            'budget_period', 'budget_id', 'budget_category_id', 'remote_id'
        ]
        read_only_fields = [
            'id', 'profile', 'goal', 'amount', 'type', 'category_readable',
            'created_at', 'updated_at', 'tags_list'
        ]
        extra_kwargs = {
            'currency': {'default': 'KES'},
            'status': {'default': 'completed'},
            'is_synced': {'default': True, 'required': False},
        }
    
    def validate(self, attrs):
        """Validate transaction data and convert amount_minor to amount."""
        # Remove write-only fields before validation
        amount_minor = attrs.pop('amount_minor', None)
        profile_id = attrs.pop('profile_id', None)
        category_name = attrs.pop('category', None)
        goal_id = attrs.pop('goal_id', None)
        transaction_type = attrs.pop('transaction_type', None)
        date = attrs.pop('date', None)
        tags = attrs.pop('tags', [])
        
        # Convert amount_minor to amount (divide by 100)
        if amount_minor is not None:
            if amount_minor <= 0:
                raise serializers.ValidationError({
                    'amount_minor': 'Amount must be positive'
                })
            attrs['amount'] = amount_minor / 100.0
        
        # Add date back to attrs (model expects 'date' field)
        if date is not None:
            attrs['date'] = date
        
        # Map transaction_type if provided
        if transaction_type is not None:
            attrs['type'] = transaction_type
        
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
        
        # Handle category - Always treat as string name
        if category_name is not None:
            from categories.models import Category
            
            profile = attrs.get('profile')
            
            # If category_name is empty string or None, set category to None
            if not category_name:
                attrs['category'] = None
            else:
                # Look for existing category by name
                found_category = None
                if profile:
                    found_category = Category.objects.filter(
                        profile=profile,
                        name__iexact=category_name
                    ).first()
                    
                    if not found_category:
                        # Try global categories (profile=None)
                        found_category = Category.objects.filter(
                            profile__isnull=True,
                            name__iexact=category_name
                        ).first()
                
                if found_category:
                    attrs['category'] = found_category
                else:
                    # Create the category automatically
                    if profile:
                        # Determine category type based on transaction type
                        transaction_type_val = attrs.get('type', TransactionType.EXPENSE)
                        
                        # Try to get CategoryType enum, fallback to string
                        try:
                            from categories.models import CategoryType
                            category_type_value = CategoryType.INCOME if transaction_type_val == TransactionType.INCOME else CategoryType.EXPENSE
                        except (ImportError, AttributeError):
                            # Fallback if CategoryType doesn't exist
                            category_type_value = 'income' if transaction_type_val == TransactionType.INCOME else 'expense'
                        
                        # Create category
                        category_data = {
                            'name': category_name,
                            'profile': profile,
                            'type': category_type_value,
                            'is_default': False,
                        }
                        
                        # Create the category
                        new_category = Category.objects.create(**category_data)
                        attrs['category'] = new_category
                    else:
                        # No profile, can't create category
                        attrs['category'] = None
        
        # Handle goal_id
        if goal_id:
            from goals.models import Goal
            try:
                goal = Goal.objects.get(id=goal_id)
                attrs['goal'] = goal
            except Goal.DoesNotExist:
                raise serializers.ValidationError({
                    'goal_id': f'Goal with id {goal_id} does not exist'
                })
        
        # Handle tags - convert list to comma-separated string
        if tags:
            # Clean and validate tags
            cleaned_tags = []
            for tag in tags:
                if tag and str(tag).strip():
                    cleaned_tag = str(tag).strip()[:50]
                    cleaned_tags.append(cleaned_tag)
            
            if cleaned_tags:
                attrs['tags'] = ','.join(cleaned_tags)
        
        # Auto-set is_expense based on type if not provided
        if 'is_expense' not in attrs and 'type' in attrs:
            attrs['is_expense'] = (attrs['type'] == TransactionType.EXPENSE)
        
        return attrs
    
    def create(self, validated_data):
        """Override create to handle tag conversion if needed."""
        # Ensure tags is properly converted to comma-separated string
        if 'tags' in validated_data:
            tags = validated_data['tags']
            if isinstance(tags, list):
                # Convert list to comma-separated string
                cleaned_tags = []
                for tag in tags:
                    if tag and str(tag).strip():
                        cleaned_tags.append(str(tag).strip()[:50])
                validated_data['tags'] = ','.join(cleaned_tags)
            elif isinstance(tags, str):
                # Already a string, ensure it's clean
                validated_data['tags'] = tags.strip()
        
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        """Override update to handle tag conversion if needed."""
        # Handle tags conversion
        if 'tags' in validated_data:
            tags = validated_data['tags']
            if isinstance(tags, list):
                # Convert list to comma-separated string
                cleaned_tags = []
                for tag in tags:
                    if tag and str(tag).strip():
                        cleaned_tags.append(str(tag).strip()[:50])
                validated_data['tags'] = ','.join(cleaned_tags)
            elif isinstance(tags, str):
                # Already a string, ensure it's clean
                validated_data['tags'] = tags.strip()
        
        return super().update(instance, validated_data)


class TransactionListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing transactions."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    tags_list = serializers.ListField(
        child=serializers.CharField(),
        read_only=True
    )
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'category', 'category_name',
            'amount', 'type', 'status', 'currency',
            'description', 'date', 'is_expense', 'tags_list',
            'merchant_name', 'payment_method'
        ]


class PendingTransactionSerializer(serializers.ModelSerializer):
    """Serializer for PendingTransaction model."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = PendingTransaction
        fields = [
            'id', 'profile', 'category', 'category_name', 'transaction',
            'raw_text', 'amount', 'description', 'date',
            'type', 'status', 'confidence', 'metadata',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']


class TransactionApprovalSerializer(serializers.Serializer):
    """Serializer for approving pending transactions."""
    category_id = serializers.UUIDField(required=False)
    category_name = serializers.CharField(required=False)


class TransactionSummarySerializer(serializers.Serializer):
    """Serializer for transaction summary."""
    total_income = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_expense = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_savings = serializers.DecimalField(max_digits=15, decimal_places=2)
    net_flow = serializers.DecimalField(max_digits=15, decimal_places=2)
    transaction_count = serializers.IntegerField()


class TransactionExportSerializer(serializers.ModelSerializer):
    """Serializer for exporting transactions."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    tags_csv = serializers.CharField(source='tags', read_only=True)
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'date', 'amount', 'currency', 'type', 'status',
            'description', 'category_name', 'payment_method',
            'merchant_name', 'tags_csv', 'reference', 'recipient'
        ]