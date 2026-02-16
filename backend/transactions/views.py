# transactions/views.py
from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db.models import Sum, Q, QuerySet
from django.utils import timezone
from datetime import timedelta
from .models import Transaction, PendingTransaction, TransactionType, TransactionStatus
from accounts.models import Profile
from .serializers import (
    TransactionSerializer,
    TransactionListSerializer,
    PendingTransactionSerializer,
    TransactionApprovalSerializer,
    TransactionSummarySerializer,
    TransactionExportSerializer
)
from categories.models import Category


class TransactionViewSet(viewsets.ModelViewSet):
    """ViewSet for Transaction model."""
    serializer_class = TransactionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type', 'status', 'category', 'payment_method', 'is_synced']
    search_fields = ['description', 'notes', 'reference', 'recipient']
    ordering_fields = ['date', 'amount', 'created_at']
    ordering = ['-date']
    
    def get_serializer_context(self):
        """Add request to serializer context."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def get_queryset(self) -> 'QuerySet[Transaction]':
        """Return transactions for current user with date filtering.
        
        CRITICAL FIX: request.user IS the Profile (AUTH_USER_MODEL='accounts.Profile')
        NOT request.user.profile - Profile IS the custom user model itself.
        """
        # ✅ FIX: request.user IS the Profile (custom auth model)
        user_profile = self.request.user
        profile_id = self.request.query_params.get('profile_id')
        
        # 🔍 DEBUG: Log query execution details
        print(f"\n🔍 GET /api/transactions/ EXECUTION:")
        print(f"  📱 Current user (request.user): {user_profile}")
        print(f"  📱 Current user ID: {user_profile.id if user_profile else 'None'}")
        print(f"  🔎 Query param profile_id: {profile_id}")
        
        # Filter: User's transactions that are NOT soft-deleted
        queryset = Transaction.objects.filter(profile=user_profile, is_deleted=False)
        print(f"  📊 After basic filter (profile={user_profile.id}, is_deleted=False): {queryset.count()} txns")
        
        # Security check: Validate profile_id parameter if provided
        if profile_id:
            if str(user_profile.id) != str(profile_id):
                print(f"  ❌ SECURITY: User {user_profile.id} != requested {profile_id}")
                return Transaction.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
            print(f"  ✅ Profile validation passed")
        
        # Date range filtering
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(date__gte=start_date)
        if end_date:
            queryset = queryset.filter(date__lte=end_date)
        
        # Filter by month
        month = self.request.query_params.get('month')  # Format: YYYY-MM
        if month:
            try:
                year, month_num = month.split('-')
                queryset = queryset.filter(
                    date__year=year,
                    date__month=month_num
                )
            except ValueError:
                pass
        
        return queryset
    
    def perform_create(self, serializer):
        """Override create to let serializer handle profile assignment."""
        # The serializer now handles profile assignment via profile_id
        # We don't need to set profile here anymore
        serializer.save()
    
    def create(self, request, *args, **kwargs):
        """Override create to handle profile_id validation."""
        print(f"Transaction POST data: {request.data}")
        
        data = request.data.copy()
        if 'category_id' in data and 'category' not in data:
            data['category'] = data.pop('category_id')
    
        # Check if profile_id is provided
        profile_id = request.data.get('profile_id')
        if not profile_id:
            print("No profile_id provided")
            return Response(
                {'error': 'profile_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verify the user owns this profile
        # request.user IS the Profile instance (AUTH_USER_MODEL = 'accounts.Profile')
        user_profile = request.user  # This is already the Profile
        
        if str(user_profile.id) != str(profile_id):
            print(f"User {user_profile.id} doesn't own profile {profile_id}")
            return Response(
                {'error': 'You can only create transactions for your own profile'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        print(f"User {user_profile.id} is authorized for profile {profile_id}")
        
        try:
            # Get serializer and validate
            serializer = self.get_serializer(data=request.data)
            print("Serializer created")
            
            # Check if data is valid
            if not serializer.is_valid():
                print(f"TRANSACTION VALIDATION ERRORS: {serializer.errors}")
                print(f"Raw errors dict: {dict(serializer.errors)}")
                
                # Log each field error in detail
                for field_name, errors in serializer.errors.items():
                    print(f"Field '{field_name}': {errors}")
                
                return Response(
                    serializer.errors,
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            print("Transaction data is valid, creating...")
            print(f"Validated data: {serializer.validated_data}")
            
            # If valid, proceed with creation
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            print("Transaction created successfully!")
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            print(f"EXCEPTION in create method: {str(e)}")
            print(f"Exception type: {type(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync transactions from mobile app - FIXED."""
        import logging
        import json
        import traceback
        
        logger = logging.getLogger('transactions')
        
        logger.info("========== TRANSACTION BULK_SYNC DEBUG ==========")
        logger.info(f"Content-Type: {request.content_type}")
        logger.info(f"Request body type: {type(request.data)}")
        
        try:
            transactions_data = request.data if isinstance(request.data, list) else []
            logger.info(f"Received {len(transactions_data)} transactions")
            
            if not transactions_data:
                logger.warning("No transactions data received")
                return Response({
                    'success': False,
                    'error': 'No transactions data provided',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get user profile
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            logger.info(f"User profile: {user_profile.id}")
            
            created_count = 0
            updated_count = 0
            errors = []
            created_ids = []  # ✅ NEW: Track created transaction IDs
            
            for idx, transaction_data in enumerate(transactions_data):
                try:
                    logger.info("=" * 50)
                    logger.info(f"Processing transaction {idx + 1}/{len(transactions_data)}")
                    logger.info(f"Raw data: {json.dumps(transaction_data, indent=2, default=str)}")
                    
                    # CRITICAL FIX: Ensure profile is in the data
                    # The serializer needs EITHER 'profile' OR 'profile_id' to validate
                    if 'profile' not in transaction_data and 'profile_id' not in transaction_data:
                        # Add profile as UUID string - serializer will convert to Profile instance
                        transaction_data['profile'] = str(user_profile.id)
                        logger.info(f"Added profile to data: {user_profile.id}")
                    
                    transaction_id = transaction_data.get('id')
                    
                    if transaction_id:
                        # Try to update existing transaction
                        try:
                            transaction = Transaction.objects.get(id=transaction_id, profile=user_profile)
                            logger.info(f"Updating existing transaction: {transaction_id}")
                            
                            serializer = TransactionSerializer(
                                transaction, 
                                data=transaction_data, 
                                partial=True,
                                context={'request': request}
                            )
                            
                            if serializer.is_valid():
                                # FIX: Explicitly set profile
                                serializer.save(profile=user_profile)
                                updated_count += 1
                                logger.info(f"Successfully updated transaction {transaction_id}")
                            else:
                                logger.error(f"Validation failed for transaction {transaction_id}")
                                logger.error(f"Errors: {json.dumps(serializer.errors, indent=2)}")
                                errors.append({
                                    'id': transaction_id,
                                    'errors': serializer.errors,
                                    'data_sent': transaction_data
                                })
                        
                        except Transaction.DoesNotExist:
                            # Create new transaction with this ID
                            logger.info(f"Creating new transaction with ID: {transaction_id}")
                            
                            serializer = TransactionSerializer(
                                data=transaction_data,
                                context={'request': request}
                            )
                            
                            if serializer.is_valid():
                                # FIX: Explicitly set profile
                                instance = serializer.save(profile=user_profile)
                                created_count += 1
                                created_ids.append(str(instance.id))  # ✅ NEW: Track ID
                                logger.info(f"Successfully created transaction {transaction_id} (server ID: {instance.id})")
                            else:
                                logger.error(f"Validation failed for new transaction {transaction_id}")
                                logger.error(f"Errors: {json.dumps(serializer.errors, indent=2)}")
                                errors.append({
                                    'id': transaction_id,
                                    'errors': serializer.errors,
                                    'data_sent': transaction_data
                                })
                    else:
                        # Create completely new transaction (no ID provided)
                        logger.info("Creating new transaction (no ID provided)")
                        
                        serializer = TransactionSerializer(
                            data=transaction_data,
                            context={'request': request}
                        )
                        
                        if serializer.is_valid():
                            # FIX: Explicitly set profile
                            instance = serializer.save(profile=user_profile)
                            created_count += 1
                            created_ids.append(str(instance.id))  # ✅ NEW: Track ID
                            logger.info("Successfully created new transaction (server ID: {})".format(instance.id))
                        else:
                            logger.error("Validation failed for new transaction")
                            logger.error(f"Errors: {json.dumps(serializer.errors, indent=2)}")
                            errors.append({
                                'errors': serializer.errors,
                                'data_sent': transaction_data
                            })
                            
                except Exception as e:
                    logger.exception(f"Exception processing transaction {idx + 1}: {str(e)}")
                    errors.append({
                        'id': transaction_data.get('id'),
                        'error': str(e),
                        'traceback': traceback.format_exc(),
                        'data_sent': transaction_data
                    })
            
            logger.info("=" * 50)
            logger.info("SYNC COMPLETE")
            logger.info(f"Created: {created_count}")
            logger.info(f"Updated: {updated_count}")
            logger.info(f"Errors: {len(errors)}")
            
            if errors:
                logger.error("Detailed errors:")
                for error in errors:
                    logger.error(f"  {json.dumps(error, indent=2, default=str)}")
            
            response_data = {
                'success': True,
                'created': created_count,
                'updated': updated_count,
                'created_ids': created_ids,  # ✅ NEW: Return created IDs
                'errors': errors
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f"Fatal error in bulk_sync: {str(e)}")
            return Response({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'])
    def batch_update(self, request):
        """✅ REFINED: Batch update transactions from mobile app.
        
        Request format:
        [
            {'id': uuid, 'amount': 100, 'type': 'expense', 'description': '...', ...},
            {'id': uuid, 'category': 'food', ...},
        ]
        
        Response:
        {'success': true, 'updated': N, 'errors': [...], 'failed_ids': [...]}
        """
        import logging
        from django.utils import timezone
        
        logger = logging.getLogger('transactions')
        logger.info("========== TRANSACTION BATCH_UPDATE ==========")
        
        try:
            transactions_data = request.data if isinstance(request.data, list) else []
            logger.info(f"Received {len(transactions_data)} transactions to update")
            
            if not transactions_data:
                return Response({
                    'success': False,
                    'error': 'No transactions data provided',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            updated_count = 0
            errors = []
            failed_ids = []
            
            for idx, transaction_data in enumerate(transactions_data):
                try:
                    transaction_id = transaction_data.get('id')
                    if not transaction_id:
                        errors.append({
                            'index': idx,
                            'error': 'Transaction ID required for update'
                        })
                        continue
                    
                    try:
                        # ✅ Only update non-deleted transactions
                        transaction = Transaction.objects.get(
                            id=transaction_id, 
                            profile=user_profile,
                            is_deleted=False  # Don't update soft-deleted
                        )
                        
                        logger.info(f"Processing update for {transaction_id}")
                        
                        serializer = TransactionSerializer(
                            transaction,
                            data=transaction_data,
                            partial=True,
                            context={'request': request}
                        )
                        
                        if serializer.is_valid():
                            # ✅ Explicitly set updated_at to current time
                            serializer.save(
                                profile=user_profile,
                                updated_at=timezone.now()
                            )
                            updated_count += 1
                            logger.info(f" Updated transaction {transaction_id}: {transaction_data}")
                        else:
                            logger.error(f"Validation failed: {serializer.errors}")
                            failed_ids.append(transaction_id)
                            errors.append({
                                'id': transaction_id,
                                'errors': serializer.errors
                            })
                    except Transaction.DoesNotExist:
                        logger.error(f"Transaction {transaction_id} not found or deleted")
                        failed_ids.append(transaction_id)
                        errors.append({
                            'id': transaction_id,
                            'error': 'Transaction not found or already deleted'
                        })
                        
                except Exception as e:
                    logger.exception(f"Error updating transaction: {str(e)}")
                    failed_ids.append(transaction_data.get('id'))
                    errors.append({
                        'id': transaction_data.get('id'),
                        'error': str(e)
                    })
            
            logger.info(f" BATCH_UPDATE COMPLETE: {updated_count} updated, {len(errors)} errors")
            
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
        """✅ REFINED: Batch delete transactions with soft-delete support.
        
        Request format:
        {
            'transaction_ids': [uuid1, uuid2, ...],
            'profile_id': uuid  # Optional, for validation
        }
        
        Response:
        {'success': true, 'deleted': N, 'soft_deleted': N, 'errors': [...], 'failed_ids': [...]}
        
        ✅ Uses SOFT DELETE: Sets is_deleted=True, deleted_at=now()
        ✅ Data is preserved for audit trail
        ✅ GET queries automatically exclude soft-deleted
        ✅ Can be synced to frontend as deletion signal
        """
        import logging
        from django.utils import timezone
        
        logger = logging.getLogger('transactions')
        logger.info("========== TRANSACTION BATCH_DELETE (SOFT) ==========")
        
        try:
            # Support both 'ids' and 'transaction_ids' parameter names
            transaction_ids = request.data.get('transaction_ids') or request.data.get('ids', [])
            logger.info(f" Received request to delete {len(transaction_ids)} transactions")
            
            if not transaction_ids:
                return Response({
                    'success': False,
                    'error': 'No transaction IDs provided (use transaction_ids or ids)',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            deleted_count = 0
            already_deleted = 0
            errors = []
            failed_ids = []
            now = timezone.now()
            
            for tx_id in transaction_ids:
                try:
                    # ✅ SOFT DELETE: Don't actually delete, just mark as deleted
                    transaction = Transaction.objects.get(id=tx_id, profile=user_profile)
                    
                    if transaction.is_deleted:
                        # Already soft-deleted, count separately
                        already_deleted += 1
                        logger.info(f" Transaction {tx_id} already soft-deleted")
                        continue
                    
                    # Perform soft delete
                    transaction.is_deleted = True
                    transaction.deleted_at = now
                    transaction.save(update_fields=['is_deleted', 'deleted_at', 'updated_at'])
                    
                    deleted_count += 1
                    logger.info(f" Soft-deleted transaction {tx_id} at {now}")
                    
                except Transaction.DoesNotExist:
                    logger.error(f"Transaction {tx_id} not found")
                    failed_ids.append(tx_id)
                    errors.append({
                        'id': tx_id,
                        'error': 'Transaction not found'
                    })
                except Exception as e:
                    logger.exception(f"Error deleting transaction {tx_id}: {str(e)}")
                    failed_ids.append(tx_id)
                    errors.append({
                        'id': tx_id,
                        'error': str(e)
                    })
            
            logger.info(
                f" BATCH_DELETE COMPLETE: "
                f"soft_deleted={deleted_count}, "
                f"already_deleted={already_deleted}, "
                f"failed={len(failed_ids)}, "
                f"errors={len(errors)}"
            )
            
            return Response({
                'success': len(failed_ids) == 0,
                'deleted': deleted_count,
                'soft_deleted': deleted_count,  # ← Clarify it's soft delete
                'already_deleted': already_deleted,
                'failed_count': len(failed_ids),
                'failed_ids': failed_ids,
                'errors': errors if errors else None,
                'note': 'Transactions are soft-deleted (marked as deleted, data preserved)'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f"Fatal error in batch_delete: {str(e)}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
            date__gte=start_date,
            date__lte=end_date
        )
        
        # Group by month
        monthly_data = queryset.annotate(
            month=TruncMonth('date')
        ).values('month', 'type').annotate(
            total=Sum('amount')
        ).order_by('month')
        
        # Format response
        summary = {}
        for item in monthly_data:
            month_str = item['month'].strftime('%Y-%m')
            if month_str not in summary:
                summary[month_str] = {
                    'income': 0.0,
                    'expense': 0.0,
                    'savings': 0.0
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
        # Get user's profile
        try:
            user_profile = self.request.user.profile
        except (Profile.DoesNotExist, AttributeError):
            return PendingTransaction.objects.none()
        
        queryset = PendingTransaction.objects.filter(profile=user_profile)
        
        # Validate profile_id if provided (must own this profile)
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            # Security: Ensure user owns this profile
            if str(user_profile.id) != str(profile_id):
                return PendingTransaction.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
        
        # Only show pending by default
        only_pending = self.request.query_params.get('only_pending', 'true')
        if only_pending.lower() == 'true':
            queryset = queryset.filter(status=TransactionStatus.PENDING)
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        from rest_framework import serializers as rest_serializers
        
        # Get user's profile
        try:
            user_profile = self.request.user.profile
            serializer.save(profile=user_profile)
        except (Profile.DoesNotExist, AttributeError):
            # If no profile exists, raise validation error
            raise rest_serializers.ValidationError({
                'profile': 'User profile not found'
            })
    
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
