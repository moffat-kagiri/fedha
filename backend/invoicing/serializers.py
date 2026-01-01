# invoicing/serializers.py
from rest_framework import serializers
from .models import Client, Invoice, Loan, InvoiceStatus


class ClientSerializer(serializers.ModelSerializer):
    """Serializer for Client model."""
    
    class Meta:
        model = Client
        fields = [
            'id', 'profile', 'name', 'email', 'phone',
            'address', 'notes', 'is_active', 'is_synced',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']


class InvoiceSerializer(serializers.ModelSerializer):
    """Serializer for Invoice model."""
    client_name = serializers.CharField(source='client.name', read_only=True)
    is_overdue = serializers.ReadOnlyField()
    days_until_due = serializers.ReadOnlyField()
    
    class Meta:
        model = Invoice
        fields = [
            'id', 'profile', 'client', 'client_name',
            'invoice_number', 'amount', 'currency',
            'issue_date', 'due_date', 'status',
            'description', 'notes',
            'is_active', 'is_synced',
            'created_at', 'updated_at',
            'is_overdue', 'days_until_due'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']
    
    def validate(self, attrs):
        """Validate invoice data."""
        amount = attrs.get('amount')
        issue_date = attrs.get('issue_date')
        due_date = attrs.get('due_date')
        
        if amount and amount <= 0:
            raise serializers.ValidationError({
                'amount': 'Amount must be positive'
            })
        
        if issue_date and due_date and issue_date >= due_date:
            raise serializers.ValidationError({
                'due_date': 'Due date must be after issue date'
            })
        
        return attrs


class LoanSerializer(serializers.ModelSerializer):
    """Serializer for Loan model."""
    is_active = serializers.ReadOnlyField()
    total_interest = serializers.SerializerMethodField()
    total_amount = serializers.SerializerMethodField()
    
    class Meta:
        model = Loan
        fields = [
            'id', 'profile', 'name',
            'principal_amount', 'currency',
            'interest_rate', 'interest_model',
            'start_date', 'end_date',
            'is_synced', 'created_at', 'updated_at',
            'is_active', 'total_interest', 'total_amount'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']
    
    def get_total_interest(self, obj):
        """Get calculated total interest."""
        return obj.calculate_total_interest()
    
    def get_total_amount(self, obj):
        """Get calculated total amount."""
        return obj.calculate_total_amount()
    
    def validate(self, attrs):
        """Validate loan data."""
        principal = attrs.get('principal_amount')
        interest_rate = attrs.get('interest_rate')
        start_date = attrs.get('start_date')
        end_date = attrs.get('end_date')
        
        if principal and principal <= 0:
            raise serializers.ValidationError({
                'principal_amount': 'Principal amount must be positive'
            })
        
        if interest_rate and (interest_rate < 0 or interest_rate > 100):
            raise serializers.ValidationError({
                'interest_rate': 'Interest rate must be between 0 and 100'
            })
        
        if start_date and end_date and start_date >= end_date:
            raise serializers.ValidationError({
                'end_date': 'End date must be after start date'
            })
        
        return attrs

