# backend/transactions/serializers.py
from rest_framework import serializers
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
from django.utils.dateparse import parse_datetime
from datetime import datetime
import pytz

class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model - Fixed for bulk_sync."""
    
    # ✅ FIX: Accept EITHER profile OR profile_id
    profile_id = serializers.UUIDField(write_only=True, required=False)
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'profile_id', 
            'category', 'goal_id',
            'amount', 'type',
            'status', 'payment_method', 'description', 'notes',
            'date', 'created_at', 'updated_at', 'currency',
            'is_expense', 'is_pending', 'is_recurring', 'is_synced',
            'tags', 'merchant_name', 'merchant_category',
            'location', 'latitude', 'longitude', 'budget_id', 'remote_id',
            'is_deleted', 'deleted_at',  # ✅ Include soft-delete fields
            'reference', 'recipient', 'sms_source', 'recurring_pattern'
        ]
        read_only_fields = [
            'id', 'created_at', 'updated_at'
        ]
        extra_kwargs = {
            'profile': {'required': False},  # ✅ Make optional for bulk_sync
            'currency': {'default': 'KES'},
            'status': {'default': 'completed'},
            'is_synced': {'default': True, 'required': False},
        }

    def validate(self, attrs):
        """Validate transaction data - FIXED for bulk_sync."""
        from accounts.models import Profile
        import uuid
        
        # ✅ CRITICAL FIX: Handle profile in multiple formats
        profile = attrs.get('profile')
        profile_id = attrs.pop('profile_id', None)
        
        # Priority 1: Check if profile_id was provided (write-only field)
        if profile_id:
            try:
                profile_obj = Profile.objects.get(id=profile_id)
                attrs['profile'] = profile_obj
            except Profile.DoesNotExist:
                raise serializers.ValidationError({
                    'profile_id': f'Profile {profile_id} does not exist'
                })
        # Priority 2: Check if profile is a UUID string (from bulk_sync view)
        elif profile and isinstance(profile, str):
            try:
                # Try to parse as UUID
                profile_uuid = uuid.UUID(profile)
                profile_obj = Profile.objects.get(id=profile_uuid)
                attrs['profile'] = profile_obj
            except (ValueError, Profile.DoesNotExist) as e:
                raise serializers.ValidationError({
                    'profile': f'Invalid profile: {profile} - {str(e)}'
                })
        # Priority 3: Check if profile is already a Profile instance
        elif isinstance(profile, Profile):
            # Already good, do nothing
            pass
        else:
            # No valid profile provided
            raise serializers.ValidationError({
                'profile': 'Profile is required. Provide either profile_id or profile.'
            })
        
        # ✅ FIX #2: Handle date format
        date_value = attrs.get('date')
        if date_value:
            if isinstance(date_value, str):
                # Try to parse the date
                try:
                    # Handle missing timezone
                    if not date_value.endswith('Z') and '+' not in date_value:
                        # Assume UTC if no timezone
                        date_value = date_value.replace('.000', '.000Z')
                    
                    parsed_date = parse_datetime(date_value)
                    if parsed_date:
                        # Ensure timezone aware
                        if parsed_date.tzinfo is None:
                            parsed_date = pytz.UTC.localize(parsed_date)
                        attrs['date'] = parsed_date
                    else:
                        raise ValueError("Invalid date format")
                except Exception as e:
                    raise serializers.ValidationError({
                        'date': f'Invalid date format: {date_value}. Expected ISO 8601 format.'
                    })
        
        # ✅ Validate amount
        amount = attrs.get('amount')
        if amount is not None:
            if isinstance(amount, str):
                try:
                    amount = float(amount)
                    attrs['amount'] = amount
                except ValueError:
                    raise serializers.ValidationError({
                        'amount': 'Amount must be a number'
                    })
            
            if amount <= 0:
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
        
        # ✅ FIX #3: Handle null values for string fields
        # Convert null to empty string for fields that don't accept null
        string_fields = ['tags', 'description', 'notes', 'reference', 'recipient', 
                        'merchant_name', 'merchant_category', 'sms_source', 
                        'recurring_pattern', 'location']
        
        for field in string_fields:
            if field in attrs and attrs[field] is None:
                attrs[field] = ''
        
        return attrs


class TransactionListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing transactions."""
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
    category_name = serializers.CharField(source='category', read_only=True)
    tags_csv = serializers.CharField(source='tags', read_only=True)
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'date', 'amount', 'currency', 'type', 'status',
            'description', 'category_name', 'payment_method',
            'merchant_name', 'tags_csv', 'reference', 'recipient'
        ]