# transactions/views.py
# Create your views here.
from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db.models import Sum, Q
from django.utils import timezone
from datetime import timedelta
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
from .serializers import (
    TransactionSerializer, PendingTransactionSerializer,
    TransactionApprovalSerializer, TransactionSummarySerializer
)
from accounts.models import Category


class TransactionViewSet(viewsets.ModelViewSet):
    """ViewSet for Transaction model."""
    serializer_class = TransactionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type', 'status', 'category', 'payment_method', 'is_synced']
    search_fields = ['description', 'notes', 'reference', 'recipient']
    ordering_fields = ['transaction_date', 'amount', 'created_at']
    ordering = ['-transaction_date']
    
    def get_queryset(self):
        """Return transactions for current user with date filtering."""
        queryset = Transaction.objects.filter(profile=self.request.user)
        
        # Filter by profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        
        # Date range filtering
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(transaction_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(transaction_date__lte=end_date)
        
        # Filter by month
        month = self.request.query_params.get('month')  # Format: YYYY-MM
        if month:
            try:
                year, month_num = month.split('-')
                queryset = queryset.filter(
                    transaction_date__year=year,
                    transaction_date__month=month_num
                )
            except ValueError:
                pass
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        serializer.save(profile=self.request.user)
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync transactions from mobile app."""
        transactions_data = request.data if isinstance(request.data, list) else []
        
        created_count = 0
        updated_count = 0
        errors = []
        
        for transaction_data in transactions_data:
            try:
                # Ensure profile is set
                transaction_data['profile'] = request.user.id
                
                transaction_id = transaction_data.get('id')
                
                if transaction_id:
                    # Try to update existing transaction
                    try:
                        transaction = Transaction.objects.get(
                            id=transaction_id,
                            profile=request.user
                        )
                        serializer = TransactionSerializer(
                            transaction,
                            data=transaction_data,
                            partial=True
                        )
                        if serializer.is_valid():
                            serializer.save()
                            updated_count += 1
                        else:
                            errors.append({
                                'id': transaction_id,
                                'errors': serializer.errors
                            })
                    except Transaction.DoesNotExist:
                        # Create new transaction with specified ID
                        serializer = TransactionSerializer(data=transaction_data)
                        if serializer.is_valid():
                            serializer.save(profile=request.user)
                            created_count += 1
                        else:
                            errors.append({
                                'id': transaction_id,
                                'errors': serializer.errors
                            })
                else:
                    # Create new transaction
                    serializer = TransactionSerializer(data=transaction_data)
                    if serializer.is_valid():
                        serializer.save(profile=request.user)
                        created_count += 1
                    else:
                        errors.append({
                            'errors': serializer.errors
                        })
            except Exception as e:
                errors.append({
                    'id': transaction_data.get('id'),
                    'error': str(e)
                })
        
        return Response({
            'success': True,
            'created': created_count,
            'updated': updated_count,
            'errors': errors
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get transaction summary."""
        queryset = self.get_queryset().filter(status=TransactionStatus.COMPLETED)
        
        # Calculate totals by type
        income = queryset.filter(type=TransactionType.INCOME).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        expense = queryset.filter(type=TransactionType.EXPENSE).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        savings = queryset.filter(type=TransactionType.SAVINGS).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        net_flow = income - expense
        
        return Response({
            'total_income': income,
            'total_expense': expense,
            'total_savings': savings,
            'net_flow': net_flow,
            'transaction_count': queryset.count()
        })
    
    @action(detail=False, methods=['get'])
    def monthly_summary(self, request):
        """Get monthly transaction summary for the last 12 months."""
        from django.db.models.functions import TruncMonth
        
        # Get last 12 months of data
        end_date = timezone.now()
        start_date = end_date - timedelta(days=365)
        
        queryset = self.get_queryset().filter(
            status=TransactionStatus.COMPLETED,
            transaction_date__gte=start_date,
            transaction_date__lte=end_date
        )
        
        # Group by month
        monthly_data = queryset.annotate(
            month=TruncMonth('transaction_date')
        ).values('month', 'type').annotate(
            total=Sum('amount')
        ).order_by('month')
        
        # Format response
        summary = {}
        for item in monthly_data:
            month_str = item['month'].strftime('%Y-%m')
            if month_str not in summary:
                summary[month_str] = {
                    'income': 0,
                    'expense': 0,
                    'savings': 0
                }
            
            summary[month_str][item['type']] = float(item['total'])
        
        return Response(summary)


class PendingTransactionViewSet(viewsets.ModelViewSet):
    """ViewSet for PendingTransaction model."""
    serializer_class = PendingTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'type']
    search_fields = ['description', 'raw_text']
    ordering_fields = ['created_at', 'amount', 'confidence']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Return pending transactions for current user."""
        queryset = PendingTransaction.objects.filter(profile=self.request.user)
        
        # Filter by profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        
        # Only show pending by default
        only_pending = self.request.query_params.get('only_pending', 'true')
        if only_pending.lower() == 'true':
            queryset = queryset.filter(status=TransactionStatus.PENDING)
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        serializer.save(profile=self.request.user)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a pending transaction."""
        pending = self.get_object()
        
        if pending.status != TransactionStatus.PENDING:
            return Response({
                'error': 'Only pending transactions can be approved'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = TransactionApprovalSerializer(data=request.data)
        
        if serializer.is_valid():
            category_id = serializer.validated_data.get('category_id')
            category = None
            
            if category_id:
                try:
                    category = Category.objects.get(
                        id=category_id,
                        profile=request.user
                    )
                except Category.DoesNotExist:
                    return Response({
                        'error': 'Category not found'
                    }, status=status.HTTP_404_NOT_FOUND)
            
            try:
                transaction = pending.approve(category=category)
                return Response({
                    'message': 'Transaction approved',
                    'transaction': TransactionSerializer(transaction).data
                }, status=status.HTTP_200_OK)
            except ValueError as e:
                return Response({
                    'error': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a pending transaction."""
        pending = self.get_object()
        
        try:
            pending.reject()
            return Response({
                'message': 'Transaction rejected'
            }, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

