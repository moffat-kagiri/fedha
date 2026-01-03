# transactions/serializers.py
from rest_framework import serializers
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
import json

class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model - Updated for string storage."""
    profile_id = serializers.UUIDField(write_only=True)
    
    # ✅ Accept category as STRING name (no ID lookup needed)
    category = serializers.CharField(
        write_only=True, 
        required=False, 
        allow_null=True,
        allow_blank=True,
        max_length=255
    )
    category_readable = serializers.CharField(source='category', read_only=True)
    
    # ✅ Accept goal_id as STRING (name or ID string)
    goal_id = serializers.CharField(
        write_only=True, 
        required=False, 
        allow_null=True,
        allow_blank=True,
        max_length=255
    )
    
    amount_minor = serializers.IntegerField(write_only=True)
    date = serializers.DateTimeField(write_only=True)
    transaction_type = serializers.ChoiceField(
        choices=TransactionType.choices, 
        write_only=True, 
        source='type'
    )
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'profile_id', 
            'category', 'category_readable',  # category is now CharField
            'goal_id',  # goal_id is now CharField
            'amount', 'amount_minor', 'type', 'transaction_type',
            'status', 'payment_method', 'description', 'notes',
            'date', 'created_at', 'updated_at', 'currency',
            'is_expense', 'is_pending', 'is_recurring', 'is_synced',
            'tags', 'merchant_name', 'merchant_category',
            'location', 'latitude', 'longitude', 'budget_id', 'remote_id'
        ]
        read_only_fields = [
            'id', 'profile', 'amount', 'type', 
            'category_readable', 'created_at', 'updated_at'
        ]
        extra_kwargs = {
            'currency': {'default': 'KES'},
            'status': {'default': 'completed'},
            'is_synced': {'default': True, 'required': False},
        }
    
    def validate(self, attrs):
        """Validate transaction data - simplified for string storage."""
        # Remove write-only fields
        amount_minor = attrs.pop('amount_minor', None)
        profile_id = attrs.pop('profile_id', None)
        transaction_type = attrs.pop('type', None)
        date = attrs.pop('date', None)
        
        # ✅ Note: category and goal_id remain in attrs as strings
        # They will be saved directly to the database
        
        # Convert amount
        if amount_minor is not None:
            if amount_minor <= 0:
                raise serializers.ValidationError({
                    'amount_minor': 'Amount must be positive'
                })
            attrs['amount'] = amount_minor / 100.0
        
        # Add date
        if date is not None:
            attrs['date'] = date
        
        # Map transaction type
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
                    'profile_id': f'Profile {profile_id} does not exist'
                })
        
        # ✅ SIMPLIFIED: category is already a string, no lookup needed
        # The database will store the string directly
        
        # ✅ SIMPLIFIED: goal_id is already a string, no lookup needed
        # The database will store the string directly
        
        # Auto-set is_expense
        if 'is_expense' not in attrs and 'type' in attrs:
            attrs['is_expense'] = (attrs['type'] == TransactionType.EXPENSE)
        
        return attrs

class TransactionListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing transactions."""
    # ✅ Directly read the category string from the database
    category_name = serializers.CharField(source='category', read_only=True)
    
    tags_list = serializers.ListField(
        child=serializers.CharField(),
        read_only=True
    )
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'category', 'category_name',
            'goal_id', 'amount', 'type', 'status', 'currency',
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