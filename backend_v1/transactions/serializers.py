# transactions/serializers.py
from rest_framework import serializers
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
from accounts.serializers import CategorySerializer


class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    currency = serializers.CharField(read_only=True)
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'category', 'category_name', 'goal',
            'amount', 'type', 'status', 'payment_method',
            'description', 'notes', 'reference', 'recipient',
            'sms_source', 'is_expense', 'is_pending', 'is_recurring',
            'is_synced', 'transaction_date', 'created_at', 'updated_at',
            'currency'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at', 'is_expense']
    
    def validate(self, attrs):
        """Validate transaction data."""
        amount = attrs.get('amount')
        
        if amount and amount <= 0:
            raise serializers.ValidationError({
                'amount': 'Amount must be positive'
            })
        
        return attrs


class PendingTransactionSerializer(serializers.ModelSerializer):
    """Serializer for PendingTransaction model."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = PendingTransaction
        fields = [
            'id', 'profile', 'category', 'category_name', 'transaction',
            'raw_text', 'amount', 'description', 'transaction_date',
            'type', 'status', 'confidence', 'metadata',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']


class TransactionApprovalSerializer(serializers.Serializer):
    """Serializer for approving pending transactions."""
    category_id = serializers.UUIDField(required=False)


class TransactionSummarySerializer(serializers.Serializer):
    """Serializer for transaction summary."""
    total_income = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_expense = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_savings = serializers.DecimalField(max_digits=15, decimal_places=2)
    net_flow = serializers.DecimalField(max_digits=15, decimal_places=2)
    transaction_count = serializers.IntegerField()

