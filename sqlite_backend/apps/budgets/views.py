# apps/budgets/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum, Count, Q
from decimal import Decimal

from .models import Budget
from .serializers import BudgetSerializer, BudgetSummarySerializer


class BudgetViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Budget CRUD operations
    Matches Flutter: BudgetService
    """
    serializer_class = BudgetSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Budget.objects.filter(user=self.request.user)
        
        # Filter by profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        
        # Filter by active status
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        # Filter by period
        period = self.request.query_params.get('period')
        if period:
            queryset = queryset.filter(period=period)
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """
        Get budget summary/overview
        Matches Flutter: getBudgetSummary()
        """
        queryset = self.get_queryset().filter(is_active=True)
        
        # Calculate aggregates
        summary = queryset.aggregate(
            total_budget=Sum('budget_amount') or Decimal('0'),
            total_spent=Sum('spent_amount') or Decimal('0'),
            budgets_count=Count('id'),
            over_budget_count=Count('id', filter=Q(spent_amount__gt=models.F('budget_amount')))
        )
        
        summary['total_remaining'] = summary['total_budget'] - summary['total_spent']
        
        if summary['total_budget'] > 0:
            summary['overall_percentage'] = float(
                (summary['total_spent'] / summary['total_budget'] * 100)
            )
        else:
            summary['overall_percentage'] = 0.0
        
        # Get active budgets with computed fields
        active_budgets = []
        for budget in queryset:
            budget_data = BudgetSerializer(budget).data
            active_budgets.append(budget_data)
        
        summary['active_budgets'] = active_budgets
        
        return Response(summary)
    
    @action(detail=True, methods=['post'])
    def update_spent(self, request, pk=None):
        """
        Update spent amount for a budget
        Matches Flutter: updateBudgetSpent()
        """
        budget = self.get_object()
        amount = request.data.get('amount')
        
        if amount is None:
            return Response({
                'success': False,
                'error': 'Amount is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            budget.spent_amount = Decimal(str(amount))
            budget.save()
            
            serializer = self.get_serializer(budget)
            return Response({
                'success': True,
                'budget': serializer.data
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def add_spending(self, request, pk=None):
        """
        Add to spent amount (incremental)
        Matches Flutter: addSpending()
        """
        budget = self.get_object()
        amount = request.data.get('amount')
        
        if amount is None:
            return Response({
                'success': False,
                'error': 'Amount is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            budget.spent_amount += Decimal(str(amount))
            budget.save()
            
            serializer = self.get_serializer(budget)
            return Response({
                'success': True,
                'budget': serializer.data
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active budgets"""
        budgets = self.get_queryset().filter(is_active=True)
        serializer = self.get_serializer(budgets, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def over_budget(self, request):
        """Get budgets that are over budget"""
        from django.db.models import F
        budgets = self.get_queryset().filter(
            spent_amount__gt=F('budget_amount'),
            is_active=True
        )
        serializer = self.get_serializer(budgets, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """
        Bulk sync budgets from Flutter app
        """
        budgets_data = request.data
        user = request.user
        
        created = []
        updated = []
        conflicts = []
        
        for budget_data in budgets_data:
            budget_id = budget_data.get('id')
            
            try:
                # Check if exists
                existing = Budget.objects.get(id=budget_id, user=user)
                
                # Update existing
                serializer = BudgetSerializer(
                    existing, 
                    data=budget_data, 
                    partial=True,
                    context={'request': request}
                )
                if serializer.is_valid():
                    serializer.save()
                    updated.append(serializer.data)
                else:
                    conflicts.append({'id': budget_id, 'errors': serializer.errors})
                    
            except Budget.DoesNotExist:
                # Create new
                serializer = BudgetSerializer(
                    data=budget_data,
                    context={'request': request}
                )
                if serializer.is_valid():
                    serializer.save()
                    created.append(serializer.data)
                else:
                    conflicts.append({'id': budget_id, 'errors': serializer.errors})
        
        return Response({
            'success': True,
            'created': len(created),
            'updated': len(updated),
            'conflicts': len(conflicts),
            'data': {
                'created': created,
                'updated': updated,
                'conflicts': conflicts
            }
        })