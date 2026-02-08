# budgets/views.py - COMPLETE FILE WITH CRUD SYNC
from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.utils import timezone
from accounts.models import Profile
from .models import Budget
from .serializers import BudgetSerializer, BudgetSummarySerializer


class BudgetViewSet(viewsets.ModelViewSet):
    """ViewSet for Budget model with full CRUD sync support."""
    serializer_class = BudgetSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['period', 'is_active', 'category']
    search_fields = ['name', 'description']
    ordering_fields = ['created_at', 'start_date', 'budget_amount', 'spent_amount']
    ordering = ['-start_date']
    
    def get_queryset(self):
        """Return budgets for current user (excluding soft-deleted)."""
        if isinstance(self.request.user, Profile):
            user_profile = self.request.user
        else:
            user_profile = self.request.user.profile
        
        # ✅ Filter out soft-deleted budgets
        queryset = Budget.objects.filter(profile=user_profile, is_deleted=False)
        
        # Validate profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            if str(user_profile.id) != str(profile_id):
                return Budget.objects.none()
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
        if isinstance(self.request.user, Profile):
            profile = self.request.user
        else:
            profile = self.request.user.profile
        serializer.save(profile=profile)
    
    @action(detail=False, methods=['get'])
    def current(self, request):
        """Get current active budget."""
        now = timezone.now()
        current_budget = Budget.objects.filter(
            profile=request.user,
            start_date__lte=now,
            end_date__gte=now,
            is_active=True,
            is_deleted=False
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
    def batch_sync(self, request):
        """✅ Batch sync budgets (create/update) from mobile app.
        
        Request format:
        POST /api/budgets/batch_sync/
        [
            {
                'id': 'uuid',  # optional (for updates)
                'name': 'Monthly Expenses',
                'budget_amount': 50000,
                'period': 'monthly',
                'start_date': '2026-01-01T00:00:00Z',
                'end_date': '2026-01-31T23:59:59Z',
                'profile_id': 'uuid'
            },
            ...
        ]
        
        Response:
        {
            'success': True,
            'created': N,
            'updated': M,
            'created_ids': ['server_id_1', ...],
            'updated_ids': ['id_1', ...],
            'errors': []
        }
        """
        import logging
        logger = logging.getLogger('budgets')
        logger.info("========== BUDGETS BATCH_SYNC ==========")
        
        try:
            budgets_data = request.data.get('budgets') if isinstance(request.data, dict) else request.data
            if not isinstance(budgets_data, list):
                budgets_data = [budgets_data] if budgets_data else []
            
            logger.info(f"[RECV] Received {len(budgets_data)} budgets to sync")
            
            if not budgets_data:
                return Response({
                    'success': False,
                    'error': 'No budgets data provided',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            logger.info(f"[USER] Syncing for profile: {user_profile.id}")
            
            created_count = 0
            updated_count = 0
            created_ids = []
            updated_ids = []
            errors = []
            
            for idx, budget_data in enumerate(budgets_data):
                try:
                    budget_id = budget_data.get('id')
                    
                    if budget_id:
                        try:
                            budget = Budget.objects.get(id=budget_id, profile=user_profile)
                            serializer = BudgetSerializer(budget, data=budget_data, partial=True)
                            if serializer.is_valid():
                                serializer.save()
                                updated_count += 1
                                updated_ids.append(budget_id)
                                logger.info(f"[OK] Updated budget {budget_id}")
                            else:
                                errors.append({'id': budget_id, 'error': 'Validation failed', 'details': serializer.errors})
                        except Budget.DoesNotExist:
                            budget_data['profile_id'] = str(user_profile.id)
                            serializer = BudgetSerializer(data=budget_data)
                            if serializer.is_valid():
                                budget = serializer.save(profile=user_profile)
                                created_count += 1
                                created_ids.append(str(budget.id))
                                logger.info(f"[OK] Created budget: {budget.id}")
                            else:
                                errors.append({'id': budget_id, 'error': 'Validation failed', 'details': serializer.errors})
                    else:
                        budget_data['profile_id'] = str(user_profile.id)
                        serializer = BudgetSerializer(data=budget_data)
                        if serializer.is_valid():
                            budget = serializer.save(profile=user_profile)
                            created_count += 1
                            created_ids.append(str(budget.id))
                            logger.info(f"[OK] Created new budget: {budget.id}")
                        else:
                            errors.append({'error': 'Validation failed', 'details': serializer.errors})
                            
                except Exception as e:
                    logger.exception(f"[ERR] Exception syncing budget: {str(e)}")
                    errors.append({'id': budget_data.get('id'), 'error': str(e)})
            
            response_data = {
                'success': len(errors) == 0,
                'created': created_count,
                'updated': updated_count,
                'created_ids': created_ids,
                'updated_ids': updated_ids,
                'errors': errors
            }
            
            logger.info(f"[DONE] BATCH_SYNC COMPLETE: created={created_count}, updated={updated_count}, errors={len(errors)}")
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f"[FATAL] Fatal error in batch_sync: {str(e)}")
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'])
    def batch_update(self, request):
        """✅ Batch update budgets from mobile app.
        
        Request format:
        POST /api/budgets/batch_update/
        [
            {'id': uuid, 'budget_amount': 50000, 'spent_amount': 15000, ...},
            {'id': uuid, 'name': 'Updated Budget', ...},
        ]
        
        Response:
        {
            'success': true,
            'updated': N,
            'failed_count': M,
            'failed_ids': [...],
            'errors': [...]
        }
        """
        import logging
        from django.utils import timezone
        
        logger = logging.getLogger('budgets')
        logger.info("========== BUDGETS BATCH_UPDATE ==========")
        
        try:
            budgets_data = request.data if isinstance(request.data, list) else []
            logger.info(f"📝 Received {len(budgets_data)} budgets to update")
            
            if not budgets_data:
                return Response({
                    'success': False,
                    'error': 'No budgets data provided',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            updated_count = 0
            errors = []
            failed_ids = []
            
            for idx, budget_data in enumerate(budgets_data):
                try:
                    budget_id = budget_data.get('id')
                    if not budget_id:
                        errors.append({
                            'index': idx,
                            'error': 'Budget ID required for update'
                        })
                        continue
                    
                    try:
                        # ✅ Only update non-deleted budgets
                        budget = Budget.objects.get(
                            id=budget_id,
                            profile=user_profile,
                            is_deleted=False
                        )
                        
                        logger.info(f"Processing update for {budget_id}")
                        
                        serializer = BudgetSerializer(
                            budget,
                            data=budget_data,
                            partial=True,
                            context={'request': request}
                        )
                        
                        if serializer.is_valid():
                            serializer.save(
                                profile=user_profile,
                                updated_at=timezone.now()
                            )
                            updated_count += 1
                            logger.info(f"✅ Updated budget {budget_id}")
                        else:
                            logger.error(f"Validation failed: {serializer.errors}")
                            failed_ids.append(budget_id)
                            errors.append({
                                'id': budget_id,
                                'errors': serializer.errors
                            })
                    except Budget.DoesNotExist:
                        logger.error(f"Budget {budget_id} not found or deleted")
                        failed_ids.append(budget_id)
                        errors.append({
                            'id': budget_id,
                            'error': 'Budget not found or already deleted'
                        })
                        
                except Exception as e:
                    logger.exception(f"Error updating budget: {str(e)}")
                    failed_ids.append(budget_data.get('id'))
                    errors.append({
                        'id': budget_data.get('id'),
                        'error': str(e)
                    })
            
            logger.info(f"✅ BATCH_UPDATE COMPLETE: {updated_count} updated, {len(errors)} errors")
            
            return Response({
                'success': len(failed_ids) == 0,
                'updated': updated_count,
                'failed_count': len(failed_ids),
                'failed_ids': failed_ids,
                'errors': errors if errors else None
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f"Fatal error in batch_update: {str(e)}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'])
    def batch_delete(self, request):
        """✅ Batch soft-delete budgets.
        
        Request format:
        POST /api/budgets/batch_delete/
        {
            'ids': ['id1', 'id2', ...]
        }
        
        Response:
        {
            'success': true,
            'deleted': N,
            'soft_deleted': N,
            'already_deleted': M,
            'failed_count': L,
            'failed_ids': [...],
            'errors': [...]
        }
        """
        import logging
        from django.utils import timezone
        
        logger = logging.getLogger('budgets')
        logger.info("========== BUDGETS BATCH_DELETE (SOFT) ==========")
        
        try:
            budget_ids = request.data.get('ids', [])
            logger.info(f"🗑️ Received request to delete {len(budget_ids)} budgets")
            
            if not budget_ids:
                return Response({
                    'success': False,
                    'error': 'No budget IDs provided',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            deleted_count = 0
            already_deleted = 0
            errors = []
            failed_ids = []
            now = timezone.now()
            
            for budget_id in budget_ids:
                try:
                    budget = Budget.objects.get(id=budget_id, profile=user_profile)
                    
                    if budget.is_deleted:
                        already_deleted += 1
                        logger.info(f"ℹ️ Budget {budget_id} already soft-deleted")
                        continue
                    
                    # Soft delete
                    budget.is_deleted = True
                    budget.deleted_at = now
                    budget.save(update_fields=['is_deleted', 'deleted_at', 'updated_at'])
                    
                    deleted_count += 1
                    logger.info(f"✅ Soft-deleted budget {budget_id}")
                    
                except Budget.DoesNotExist:
                    logger.error(f"Budget {budget_id} not found")
                    failed_ids.append(budget_id)
                    errors.append({'id': budget_id, 'error': 'Budget not found'})
                except Exception as e:
                    logger.exception(f"Error deleting budget {budget_id}")
                    failed_ids.append(budget_id)
                    errors.append({'id': budget_id, 'error': str(e)})
            
            logger.info(f"✅ BATCH_DELETE COMPLETE: {deleted_count} deleted, {already_deleted} already deleted")
            
            return Response({
                'success': len(failed_ids) == 0,
                'deleted': deleted_count,
                'soft_deleted': deleted_count,
                'already_deleted': already_deleted,
                'failed_count': len(failed_ids),
                'failed_ids': failed_ids,
                'errors': errors if errors else None
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f"Fatal error in batch_delete")
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get summary of all budgets."""
        budgets = self.get_queryset().filter(is_active=True, is_deleted=False)
        
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

