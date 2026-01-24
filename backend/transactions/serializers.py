# transactions/serializers.py
from rest_framework import serializers
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
import json

class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model - Simplified for database schema."""
    profile_id = serializers.UUIDField(write_only=True)
    
    # ✅ REMOVE amount_minor, just use amount directly
    # ✅ REMOVE transaction_type, just use type directly
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'profile_id', 
            'category', 'goal_id',
            'amount', 'type',  # ✅ Direct field names
            'status', 'payment_method', 'description', 'notes',
            'date', 'created_at', 'updated_at', 'currency',
            'is_expense', 'is_pending', 'is_recurring', 'is_synced',
            'tags', 'merchant_name', 'merchant_category',
            'location', 'latitude', 'longitude', 'budget_id', 'remote_id',
            'reference', 'recipient', 'sms_source', 'recurring_pattern'
        ]
        read_only_fields = [
            'id', 'profile', 'created_at', 'updated_at'
        ]
        extra_kwargs = {
            'currency': {'default': 'KES'},
            'status': {'default': 'completed'},
            'is_synced': {'default': True, 'required': False},
        }

    def validate(self, attrs):
        """Validate transaction data."""
        profile_id = attrs.pop('profile_id', None)
        
        # ✅ Handle profile_id properly
        if profile_id:
            from accounts.models import Profile
            try:
                profile = Profile.objects.get(id=profile_id)
                attrs['profile'] = profile
            except Profile.DoesNotExist:
                raise serializers.ValidationError({
                    'profile_id': f'Profile {profile_id} does not exist'
                })
        
        # ✅ Ensure profile exists
        if 'profile' not in attrs:
            raise serializers.ValidationError({
                'profile': 'Profile is required'
            })
        
        # ✅ Validate amount
        amount = attrs.get('amount')
        if amount is not None and amount <= 0:
            raise serializers.ValidationError({
                'amount': 'Amount must be positive'
            })
        
        # ✅ Set defaults
        if 'currency' not in attrs:
            attrs['currency'] = 'KES'
        
        if 'status' not in attrs:
            attrs['status'] = 'completed'
        
        # ✅ Auto-set is_expense
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
    # ✅ Updated: Read category as string (not ForeignKey)
    category_name = serializers.CharField(source='category', read_only=True)
    
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
    # ✅ Updated: Read category as string (not ForeignKey)
    category_name = serializers.CharField(source='category', read_only=True)
    tags_csv = serializers.CharField(source='tags', read_only=True)
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'date', 'amount', 'currency', 'type', 'status',
            'description', 'category_name', 'payment_method',
            'merchant_name', 'tags_csv', 'reference', 'recipient'
        ]