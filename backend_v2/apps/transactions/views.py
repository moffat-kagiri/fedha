# apps/transactions/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum, Q, Count
from django.utils import timezone
from datetime import datetime, timedelta
from decimal import Decimal

from .models import Transaction, TransactionCandidate, Category
from .serializers import (
    TransactionSerializer, TransactionCandidateSerializer,
    CategorySerializer, BulkTransactionSerializer
)


class CategoryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Category CRUD operations
    Matches Flutter: CategoryService
    """
    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Category.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """Get categories filtered by type (income/expense)"""
        category_type = request.query_params.get('type', 'expense')
        categories = self.get_queryset().filter(type__in=[category_type, 'both'])
        serializer = self.get_serializer(categories, many=True)
        return Response(serializer.data)


class TransactionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Transaction CRUD operations
    Matches Flutter: TransactionService
    """
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Transaction.objects.filter(user=self.request.user)
        
        # Filter by profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        if start_date:
            queryset = queryset.filter(date__gte=start_date)
        if end_date:
            queryset = queryset.filter(date__lte=end_date)
        
        # Filter by type
        txn_type = self.request.query_params.get('type')
        if txn_type:
            queryset = queryset.filter(type=txn_type)
        
        # Filter by category
        category_id = self.request.query_params.get('category_id')
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        
        return queryset.order_by('-date')
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """
        Bulk sync transactions from Flutter app
        Handles create/update with conflict resolution
        """
        serializer = BulkTransactionSerializer(
            data={'transactions': request.data},
            context={'request': request}
        )
        
        if serializer.is_valid():
            result = serializer.save()
            return Response({
                'success': True,
                'created': len(result['created']),
                'updated': len(result['updated']),
                'conflicts': len(result['conflicts']),
                'data': result
            })
        
        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Get transaction statistics
        Matches Flutter: getTransactionStats()
        """
        queryset = self.get_queryset()
        
        # Calculate totals by type
        stats = queryset.aggregate(
            total_income=Sum('amount', filter=Q(type='income')) or Decimal('0'),
            total_expense=Sum('amount', filter=Q(type='expense')) or Decimal('0'),
            total_savings=Sum('amount', filter=Q(type='savings')) or Decimal('0'),
            transaction_count=Count('id')
        )
        
        stats['net_balance'] = (
            stats['total_income'] - stats['total_expense']
        )
        
        # By category
        by_category = {}
        category_stats = queryset.values('category_id', 'type').annotate(
            total=Sum('amount'),
            count=Count('id')
        )
        for item in category_stats:
            cat_id = item['category_id']
            if cat_id not in by_category:
                by_category[cat_id] = {
                    'income': Decimal('0'),
                    'expense': Decimal('0'),
                    'count': 0
                }
            by_category[cat_id][item['type']] = float(item['total'])
            by_category[cat_id]['count'] += item['count']
        
        stats['by_category'] = by_category
        
        # By month (last 6 months)
        six_months_ago = timezone.now() - timedelta(days=180)
        monthly_data = queryset.filter(date__gte=six_months_ago).values(
            'date__year', 'date__month', 'type'
        ).annotate(
            total=Sum('amount')
        ).order_by('date__year', 'date__month')
        
        by_month = {}
        for item in monthly_data:
            month_key = f"{item['date__year']}-{item['date__month']:02d}"
            if month_key not in by_month:
                by_month[month_key] = {'income': 0, 'expense': 0, 'savings': 0}
            by_month[month_key][item['type']] = float(item['total'])
        
        stats['by_month'] = by_month
        
        return Response(stats)
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Get recent transactions (last 30 days)"""
        thirty_days_ago = timezone.now() - timedelta(days=30)
        transactions = self.get_queryset().filter(date__gte=thirty_days_ago)[:50]
        serializer = self.get_serializer(transactions, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['delete'])
    def bulk_delete(self, request):
        """Delete multiple transactions"""
        ids = request.data.get('ids', [])
        deleted_count = Transaction.objects.filter(
            id__in=ids,
            user=request.user
        ).delete()[0]
        
        return Response({
            'success': True,
            'deleted': deleted_count
        })


class TransactionCandidateViewSet(viewsets.ModelViewSet):
    """
    ViewSet for TransactionCandidate (SMS-extracted transactions)
    Matches Flutter: SmsTransactionService
    """
    serializer_class = TransactionCandidateSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return TransactionCandidate.objects.filter(user=self.request.user)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """
        Approve a candidate and create actual transaction
        Matches Flutter: approveCandidate()
        """
        candidate = self.get_object()
        
        # Create transaction from candidate
        transaction_data = {
            'amount': candidate.amount,
            'type': candidate.type,
            'category_id': candidate.category_id or 'uncategorized',
            'date': candidate.date,
            'description': candidate.description,
            'sms_source': candidate.raw_text,
            'profile_id': request.user.id,
        }
        
        txn_serializer = TransactionSerializer(
            data=transaction_data,
            context={'request': request}
        )
        
        if txn_serializer.is_valid():
            transaction = txn_serializer.save()
            
            # Update candidate
            candidate.status = 'completed'
            candidate.transaction_id = transaction.id
            candidate.save()
            
            return Response({
                'success': True,
                'transaction': txn_serializer.data
            })
        
        return Response({
            'success': False,
            'errors': txn_serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """
        Reject a candidate
        Matches Flutter: rejectCandidate()
        """
        candidate = self.get_object()
        candidate.status = 'cancelled'
        candidate.save()
        
        return Response({
            'success': True,
            'message': 'Candidate rejected'
        })
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get all pending candidates"""
        candidates = self.get_queryset().filter(status='pending')
        serializer = self.get_serializer(candidates, many=True)
        return Response(serializer.data)