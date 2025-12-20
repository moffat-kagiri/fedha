# budgets/views.py
# Create your views here.
from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.utils import timezone
from .models import Budget
from .serializers import BudgetSerializer, BudgetSummarySerializer


class BudgetViewSet(viewsets.ModelViewSet):
    """ViewSet for Budget model."""
    serializer_class = BudgetSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['period', 'is_active', 'category']
    search_fields = ['name', 'description']
    ordering_fields = ['created_at', 'start_date', 'budget_amount', 'spent_amount']
    ordering = ['-start_date']
    
    def get_queryset(self):
        """Return budgets for current user."""
        queryset = Budget.objects.filter(profile=self.request.user)
        
        # Filter by profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        
        # Filter current budgets
        current_only = self.request.query_params.get('current_only')
        if current_only and current_only.lower() == 'true':
            now = timezone.now()
            queryset = queryset.filter(
                start_date__lte=now,
                end_date__gte=now,
                is_active=True
            )
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        serializer.save(profile=self.request.user)
    
    @action(detail=False, methods=['get'])
    def current(self, request):
        """Get current active budget."""
        now = timezone.now()
        current_budget = Budget.objects.filter(
            profile=request.user,
            start_date__lte=now,
            end_date__gte=now,
            is_active=True
        ).order_by('-start_date').first()
        
        if current_budget:
            serializer = BudgetSerializer(current_budget)
            return Response(serializer.data)
        
        return Response({
            'message': 'No current budget found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=True, methods=['post'])
    def update_spent(self, request, pk=None):
        """Recalculate spent amount from transactions."""
        budget = self.get_object()
        budget.update_spent_amount()
        
        serializer = BudgetSerializer(budget)
        return Response({
            'message': 'Spent amount updated',
            'budget': serializer.data
        })
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync budgets from mobile app."""
        budgets_data = request.data if isinstance(request.data, list) else []
        
        created_count = 0
        updated_count = 0
        errors = []
        
        for budget_data in budgets_data:
            try:
                # Ensure profile is set
                budget_data['profile'] = request.user.id
                
                budget_id = budget_data.get('id')
                
                if budget_id:
                    # Try to update existing budget
                    try:
                        budget = Budget.objects.get(id=budget_id, profile=request.user)
                        serializer = BudgetSerializer(budget, data=budget_data, partial=True)
                        if serializer.is_valid():
                            serializer.save()
                            updated_count += 1
                        else:
                            errors.append({
                                'id': budget_id,
                                'errors': serializer.errors
                            })
                    except Budget.DoesNotExist:
                        # Create new budget with specified ID
                        serializer = BudgetSerializer(data=budget_data)
                        if serializer.is_valid():
                            serializer.save(profile=request.user)
                            created_count += 1
                        else:
                            errors.append({
                                'id': budget_id,
                                'errors': serializer.errors
                            })
                else:
                    # Create new budget
                    serializer = BudgetSerializer(data=budget_data)
                    if serializer.is_valid():
                        serializer.save(profile=request.user)
                        created_count += 1
                    else:
                        errors.append({
                            'errors': serializer.errors
                        })
            except Exception as e:
                errors.append({
                    'id': budget_data.get('id'),
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
        """Get summary of all budgets."""
        budgets = self.get_queryset().filter(is_active=True)
        
        # Get current budgets
        now = timezone.now()
        current_budgets = budgets.filter(
            start_date__lte=now,
            end_date__gte=now
        )
        
        total_budget = sum(b.budget_amount for b in current_budgets)
        total_spent = sum(b.spent_amount for b in current_budgets)
        total_remaining = total_budget - total_spent
        overall_percentage = (total_spent / total_budget * 100) if total_budget > 0 else 0
        
        over_budget_count = sum(1 for b in current_budgets if b.is_over_budget)
        
        return Response({
            'total_budget': total_budget,
            'total_spent': total_spent,
            'total_remaining': total_remaining,
            'overall_percentage': round(overall_percentage, 2),
            'active_budgets': current_budgets.count(),
            'over_budget_count': over_budget_count
        })

