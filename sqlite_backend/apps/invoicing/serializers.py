# apps/invoicing/serializers.py
from rest_framework import serializers
from .models import Client, Invoice, Loan

class ClientSerializer(serializers.ModelSerializer):
    """Serializer for Client model"""
    
    class Meta:
        model = Client
        fields = [
            'id', 'name', 'email', 'phone', 'address', 'notes',
            'is_active', 'is_synced', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class InvoiceSerializer(serializers.ModelSerializer):
    """Serializer for Invoice model"""
    
    client_name = serializers.CharField(source='client.name', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Invoice
        fields = [
            'id', 'invoice_number', 'client', 'client_name',
            'amount', 'currency', 'issue_date', 'due_date', 'status',
            'description', 'notes', 'is_active', 'is_synced',
            'created_at', 'updated_at', 'is_overdue'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'is_overdue']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class LoanSerializer(serializers.ModelSerializer):
    """Serializer for Loan model"""
    
    class Meta:
        model = Loan
        fields = [
            'id', 'name', 'principal_minor', 'currency', 'interest_rate',
            'start_date', 'end_date', 'profile_id', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)