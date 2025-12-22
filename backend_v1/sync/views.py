# sync/views.py
from django.shortcuts import render
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.response import Response
from django.utils import timezone
from django.db import transaction as db_transaction
from .models import SyncQueue, SyncStatus
from .serializers import (
    SyncQueueSerializer, SyncStatusSerializer, BulkSyncRequestSerializer
)
from transactions.models import Transaction
from transactions.serializers import TransactionSerializer
from goals.models import Goal
from goals.serializers import GoalSerializer
from budgets.models import Budget
from budgets.serializers import BudgetSerializer
from accounts.models import Category
from accounts import serializers as account_serializers


class SyncQueueViewSet(viewsets.ModelViewSet):
    """ViewSet for SyncQueue model."""
    serializer_class = SyncQueueSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['status', 'entity_type', 'action']
    ordering = ['-priority', 'created_at']
    
    def get_queryset(self):
        """Return sync queue items for current user."""
        return SyncQueue.objects.filter(profile=self.request.user)
    
    def perform_create(self, serializer):
        """Set profile on create."""
        serializer.save(profile=self.request.user)
    
    @action(detail=False, methods=['get'])
    def status(self, request):
        """Get sync status summary."""
        queryset = self.get_queryset()
        
        pending = queryset.filter(status=SyncStatus.PENDING).count()
        processing = queryset.filter(status=SyncStatus.PROCESSING).count()
        completed = queryset.filter(status=SyncStatus.COMPLETED).count()
        failed = queryset.filter(status=SyncStatus.FAILED).count()
        
        # Get last successful sync
        last_completed = queryset.filter(
            status=SyncStatus.COMPLETED
        ).order_by('-updated_at').first()
        
        last_sync = last_completed.updated_at if last_completed else None
        
        return Response({
            'total_pending': pending,
            'total_processing': processing,
            'total_completed': completed,
            'total_failed': failed,
            'last_sync': last_sync
        })
    
    @action(detail=False, methods=['post'])
    def process_pending(self, request):
        """Process all pending sync items."""
        pending_items = self.get_queryset().filter(
            status=SyncStatus.PENDING
        )
        
        processed = 0
        failed = 0
        
        for item in pending_items:
            if item.should_retry:
                try:
                    item.mark_processing()
                    # Process the sync item based on entity type
                    self._process_sync_item(item)
                    item.mark_completed()
                    processed += 1
                except Exception as e:
                    item.mark_failed(str(e))
                    failed += 1
        
        return Response({
            'processed': processed,
            'failed': failed
        })
    
    def _process_sync_item(self, item):
        """Process a single sync item."""
        entity_type = item.entity_type
        action = item.action
        data = item.data
        
        # Map entity types to models and serializers
        entity_map = {
            'transaction': (Transaction, TransactionSerializer),
            'goal': (Goal, GoalSerializer),
            'budget': (Budget, BudgetSerializer),
            'category': (Category, CategorySerializer),
        }
        
        if entity_type not in entity_map:
            raise ValueError(f"Unknown entity type: {entity_type}")
        
        model_class, serializer_class = entity_map[entity_type]
        
        if action == 'create':
            serializer = serializer_class(data=data)
            if serializer.is_valid():
                serializer.save(profile=item.profile)
            else:
                raise ValueError(f"Validation error: {serializer.errors}")
        
        elif action == 'update':
            try:
                instance = model_class.objects.get(
                    id=item.entity_id,
                    profile=item.profile
                )
                serializer = serializer_class(instance, data=data, partial=True)
                if serializer.is_valid():
                    serializer.save()
                else:
                    raise ValueError(f"Validation error: {serializer.errors}")
            except model_class.DoesNotExist:
                raise ValueError(f"{entity_type} not found")
        
        elif action == 'delete':
            try:
                instance = model_class.objects.get(
                    id=item.entity_id,
                    profile=item.profile
                )
                instance.delete()
            except model_class.DoesNotExist:
                # Already deleted, mark as successful
                pass


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def bulk_sync(request):
    """
    Bulk sync endpoint that accepts multiple entity types.
    This is the main sync endpoint used by the mobile app.
    """
    serializer = BulkSyncRequestSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    results = {
        'transactions': {'created': 0, 'updated': 0, 'errors': []},
        'goals': {'created': 0, 'updated': 0, 'errors': []},
        'budgets': {'created': 0, 'updated': 0, 'errors': []},
        'categories': {'created': 0, 'updated': 0, 'errors': []},
    }
    
    with db_transaction.atomic():
        # Sync transactions
        if 'transactions' in serializer.validated_data:
            results['transactions'] = _sync_entities(
                request.user,
                serializer.validated_data['transactions'],
                Transaction,
                TransactionSerializer
            )
        
        # Sync goals
        if 'goals' in serializer.validated_data:
            results['goals'] = _sync_entities(
                request.user,
                serializer.validated_data['goals'],
                Goal,
                GoalSerializer
            )
        
        # Sync budgets
        if 'budgets' in serializer.validated_data:
            results['budgets'] = _sync_entities(
                request.user,
                serializer.validated_data['budgets'],
                Budget,
                BudgetSerializer
            )
        
        # Sync categories
        if 'categories' in serializer.validated_data:
            results['categories'] = _sync_entities(
                request.user,
                serializer.validated_data['categories'],
                Category,
                CategorySerializer
            )
    
    return Response({
        'success': True,
        'results': results,
        'timestamp': timezone.now()
    })


def _sync_entities(user, entities_data, model_class, serializer_class):
    """Helper function to sync a list of entities."""
    created = 0
    updated = 0
    errors = []
    
    for entity_data in entities_data:
        try:
            entity_data['profile'] = user.id
            entity_id = entity_data.get('id')
            
            if entity_id:
                # Try to update existing
                try:
                    instance = model_class.objects.get(id=entity_id, profile=user)
                    serializer = serializer_class(instance, data=entity_data, partial=True)
                    if serializer.is_valid():
                        serializer.save()
                        updated += 1
                    else:
                        errors.append({'id': entity_id, 'errors': serializer.errors})
                except model_class.DoesNotExist:
                    # Create with specified ID
                    serializer = serializer_class(data=entity_data)
                    if serializer.is_valid():
                        serializer.save(profile=user)
                        created += 1
                    else:
                        errors.append({'id': entity_id, 'errors': serializer.errors})
            else:
                # Create new
                serializer = serializer_class(data=entity_data)
                if serializer.is_valid():
                    serializer.save(profile=user)
                    created += 1
                else:
                    errors.append({'errors': serializer.errors})
        except Exception as e:
            errors.append({'id': entity_data.get('id'), 'error': str(e)})
    
    return {
        'created': created,
        'updated': updated,
        'errors': errors
    }


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def resolve_conflicts(request):
    """
    Resolve sync conflicts using conflict resolution strategies.
    """
    # This is a placeholder for more advanced conflict resolution
    # For now, server always wins
    conflicts = request.data.get('conflicts', [])
    resolved = []
    
    for conflict in conflicts:
        entity_type = conflict.get('entity_type')
        entity_id = conflict.get('entity_id')
        server_version = conflict.get('server_version')
        client_version = conflict.get('client_version')
        
        # Strategy: Last write wins (using updated_at timestamp)
        server_time = timezone.datetime.fromisoformat(
            server_version.get('updated_at')
        )
        client_time = timezone.datetime.fromisoformat(
            client_version.get('updated_at')
        )
        
        winner = 'server' if server_time > client_time else 'client'
        
        resolved.append({
            'entity_type': entity_type,
            'entity_id': entity_id,
            'resolution': winner,
            'data': server_version if winner == 'server' else client_version
        })
    
    return Response({
        'resolved': resolved
    })

