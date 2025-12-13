# apps/transactions/serializers.py
from rest_framework import serializers
from .models import Transaction, TransactionCandidate, Category

class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model"""
    
    class Meta:
        model = Category
        fields = [
            'id', 'name', 'description', 'color', 'icon', 'type',
            'is_active', 'is_synced', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        """Create category for authenticated user"""
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model - matches Flutter Transaction"""
    
    # Read-only computed fields
    category_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Transaction
        fields = [
            'uuid', 'id', 'amount', 'type', 'category_id', 'category',
            'date', 'notes', 'description', 'is_synced', 'profile_id',
            'updated_at', 'goal_id', 'sms_source', 'reference', 'recipient',
            'is_pending', 'is_expense', 'is_recurring', 'payment_method',
            'created_at', 'category_name'
        ]
        read_only_fields = ['id', 'uuid', 'created_at', 'updated_at', 'is_expense', 'category_name']
    
    def get_category_name(self, obj):
        """Get category name from category_id"""
        try:
            category = Category.objects.get(id=obj.category_id, user=obj.user)
            return category.name
        except Category.DoesNotExist:
            return obj.category_id
    
    def create(self, validated_data):
        """Create transaction for authenticated user"""
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class TransactionCandidateSerializer(serializers.ModelSerializer):
    """Serializer for TransactionCandidate - SMS-extracted transactions"""
    
    class Meta:
        model = TransactionCandidate
        fields = [
            'id', 'raw_text', 'amount', 'description', 'category_id',
            'date', 'type', 'status', 'confidence', 'transaction_id',
            'metadata', 'created_at', 'updated_at',
            'is_pending', 'is_approved', 'is_rejected',
            'is_high_confidence', 'is_low_confidence'
        ]
        read_only_fields = [
            'id', 'created_at', 'updated_at',
            'is_pending', 'is_approved', 'is_rejected',
            'is_high_confidence', 'is_low_confidence'
        ]
    
    def create(self, validated_data):
        """Create candidate for authenticated user"""
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class BulkTransactionSerializer(serializers.Serializer):
    """Serializer for bulk transaction sync"""
    transactions = TransactionSerializer(many=True)
    
    def create(self, validated_data):
        """Handle bulk creation/update of transactions"""
        user = self.context['request'].user
        transactions_data = validated_data.get('transactions', [])
        
        created = []
        updated = []
        conflicts = []
        
        for txn_data in transactions_data:
            txn_id = txn_data.get('id')
            
            try:
                # Check if exists
                existing = Transaction.objects.get(id=txn_id, user=user)
                
                # Update existing
                serializer = TransactionSerializer(
                    existing, 
                    data=txn_data, 
                    partial=True,
                    context=self.context
                )
                if serializer.is_valid():
                    serializer.save()
                    updated.append(serializer.data)
                else:
                    conflicts.append({'id': txn_id, 'errors': serializer.errors})
                    
            except Transaction.DoesNotExist:
                # Create new
                txn_data['user'] = user
                serializer = TransactionSerializer(data=txn_data, context=self.context)
                if serializer.is_valid():
                    serializer.save()
                    created.append(serializer.data)
                else:
                    conflicts.append({'id': txn_id, 'errors': serializer.errors})
        
        return {
            'created': created,
            'updated': updated,
            'conflicts': conflicts
        }


class TransactionStatsSerializer(serializers.Serializer):
    """Serializer for transaction statistics"""
    total_income = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_expense = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_savings = serializers.DecimalField(max_digits=12, decimal_places=2)
    net_balance = serializers.DecimalField(max_digits=12, decimal_places=2)
    transaction_count = serializers.IntegerField()
    by_category = serializers.DictField()
    by_month = serializers.DictField()