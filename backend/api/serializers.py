from rest_framework import serializers
from .models import Transaction, Profile

class TransactionSerializer(serializers.ModelSerializer):
    type = serializers.CharField(source='get_type_display')
    category = serializers.CharField(source='get_category_display')
    date = serializers.DateTimeField(format='%Y-%m-%dT%H:%M:%S.%fZ')

    class Meta:
        model = Transaction
        fields = ['date', ...]

    class Meta:
        model = Transaction
        fields = ['id', 'amount', 'type', 'category', 'date', 'notes']

    def validate_type(self, value):
        if value not in dict(Transaction.TransactionType.choices):
            raise serializers.ValidationError("Invalid transaction type")
        return value