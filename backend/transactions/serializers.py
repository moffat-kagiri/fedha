# transactions/serializers.py
from rest_framework import serializers
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
from accounts import serializers as account_serializers


class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    profile_id = serializers.UUIDField(write_only=True)  # ✅ Accept profile_id from Flutter
    category_id = serializers.UUIDField(write_only=True, required=False, allow_null=True)
    goal_id = serializers.UUIDField(write_only=True, required=False, allow_null=True)
    amount_minor = serializers.IntegerField(write_only=True)  # ✅ Accept amount_minor
    date = serializers.DateTimeField(write_only=True, source='transaction_date')  # ✅ Map 'date' to 'transaction_date'
    transaction_type = serializers.ChoiceField(
        choices=TransactionType.choices, 
        write_only=True, 
        source='type'  # ✅ Map 'transaction_type' to 'type'
    )
    is_expense = serializers.BooleanField(required=False)  # ✅ Make optional
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'profile', 'profile_id', 'category', 'category_id', 'category_name', 
            'goal', 'goal_id', 'amount', 'amount_minor', 'type', 'transaction_type',
            'status', 'payment_method', 'description', 'notes', 'reference', 
            'recipient', 'sms_source', 'is_expense', 'is_pending', 'is_recurring',
            'is_synced', 'transaction_date', 'date', 'created_at', 'updated_at',
            'currency'
        ]
        read_only_fields = [
            'id', 'profile', 'category', 'goal', 'amount', 'type',  # These come from write-only fields
            'created_at', 'updated_at', 'currency'
        ]
        extra_kwargs = {
            'currency': {'default': 'KES'},  # ✅ Set default currency
            'status': {'default': 'completed'},  # ✅ Set default status
        }
    
    def validate(self, attrs):
        """Validate transaction data and convert amount_minor to amount."""
        # Remove write-only fields before validation
        amount_minor = attrs.pop('amount_minor', None)
        profile_id = attrs.pop('profile_id', None)
        category_id = attrs.pop('category_id', None)
        goal_id = attrs.pop('goal_id', None)
        transaction_type = attrs.pop('transaction_type', None)
        date = attrs.pop('date', None)  # This is actually 'transaction_date' due to source mapping
        
        # Convert amount_minor to amount (divide by 100)
        if amount_minor is not None:
            if amount_minor <= 0:
                raise serializers.ValidationError({
                    'amount_minor': 'Amount must be positive'
                })
            attrs['amount'] = amount_minor / 100.0
        
        # Map date field if provided
        if date is not None:
            attrs['transaction_date'] = date
        
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
        
        # Handle category_id
        if category_id:
            from categories.models import Category
            try:
                category = Category.objects.get(id=category_id)
                attrs['category'] = category
            except Category.DoesNotExist:
                raise serializers.ValidationError({
                    'category_id': f'Category with id {category_id} does not exist'
                })
        elif attrs.get('category') is None:
            # If no category provided, set to default 'other' category
            from categories.models import Category
            try:
                other_category = Category.objects.get(name='other')
                attrs['category'] = other_category
            except Category.DoesNotExist:
                pass  # Let the model handle the default
        
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
        
        # Auto-set is_expense based on type if not provided
        if 'is_expense' not in attrs and 'type' in attrs:
            attrs['is_expense'] = (attrs['type'] == TransactionType.EXPENSE)
        
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