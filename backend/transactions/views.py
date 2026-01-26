# transactions/views.py
from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db.models import Sum, Q, QuerySet
from django.utils import timezone
from datetime import timedelta, datetime
from typing import Any, Optional, Dict, List, Union, cast
from django.db import models
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
    
    def get_serializer_context(self) -> Dict[str, Any]:
        """Add request to serializer context."""
        context: Dict[str, Any] = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def get_queryset(self) -> QuerySet[Transaction]:
        """Return transactions for current user with date filtering."""
        # Get user's profile
        try:
            user_profile: Profile = self.request.user.profile
        except (Profile.DoesNotExist, AttributeError):
            # If no profile exists, return empty queryset
            return Transaction.objects.none()
        
        queryset: QuerySet[Transaction] = Transaction.objects.filter(profile=user_profile)
        
        # Validate profile_id if provided (must own this profile)
        profile_id: Optional[str] = self.request.query_params.get('profile_id')
        if profile_id:
            # Security: Ensure user owns this profile
            if str(user_profile.id) != str(profile_id):
                return Transaction.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
        
        # Date range filtering
        start_date: Optional[str] = self.request.query_params.get('start_date')
        end_date: Optional[str] = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(date__gte=start_date)
        if end_date:
            queryset = queryset.filter(date__lte=end_date)
        
        # Filter by month
        month: Optional[str] = self.request.query_params.get('month')  # Format: YYYY-MM
        if month:
            try:
                year: str
                month_num: str
                year, month_num = month.split('-')
                queryset = queryset.filter(
                    date__year=year,
                    date__month=month_num
                )
            except ValueError:
                pass
        
        return queryset
    
    def get_serializer(self, *args: Any, **kwargs: Any) -> TransactionSerializer:
        """Override to specify return type."""
        # Cast the result to TransactionSerializer since we know serializer_class is TransactionSerializer
        return cast(TransactionSerializer, super().get_serializer(*args, **kwargs))
    
    def perform_create(self, serializer: TransactionSerializer) -> None:
        """Override create to let serializer handle profile assignment."""
        # The serializer now handles profile assignment via profile_id
        # We don't need to set profile here anymore
        serializer.save()
    
    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Override create to handle profile_id validation."""
        print(f" Transaction POST data: {request.data}")
        
        data: Dict[str, Any] = request.data.copy()
        if 'category_id' in data and 'category' not in data:
            data['category'] = data.pop('category_id')
    
        # Check if profile_id is provided
        profile_id: Optional[str] = request.data.get('profile_id')
        if not profile_id:
            print(f" No profile_id provided")
            return Response(
                {'error': 'profile_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verify the user owns this profile
        # request.user IS the Profile instance (AUTH_USER_MODEL = 'accounts.Profile')
        user_profile: Profile = request.user  # This is already the Profile
        
        if str(user_profile.id) != str(profile_id):
            print(f" User {user_profile.id} doesn't own profile {profile_id}")
            return Response(
                {'error': 'You can only create transactions for your own profile'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        print(f" User {user_profile.id} is authorized for profile {profile_id}")
        
        try:
            # Get serializer and validate
            serializer: TransactionSerializer = self.get_serializer(data=request.data)
            print(f" Serializer created")
            
            # Check if data is valid
            if not serializer.is_valid():
                print(f" TRANSACTION VALIDATION ERRORS: {serializer.errors}")
                print(f" Raw errors dict: {dict(serializer.errors)}")
                
                # Log each field error in detail
                for field_name, errors in serializer.errors.items():
                    print(f" Field '{field_name}': {errors}")
                
                return Response(
                    serializer.errors,
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            print(f" Transaction data is valid, creating...")
            print(f" Validated data: {serializer.validated_data}")
            
            # If valid, proceed with creation
            self.perform_create(serializer)
            headers: Dict[str, str] = self.get_success_headers(serializer.data)
            print(f" Transaction created successfully!")
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            print(f" EXCEPTION in create method: {str(e)}")
            print(f" Exception type: {type(e)}")
            import traceback
            print(f" Traceback: {traceback.format_exc()}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def bulk_sync(self, request: Request) -> Response:
        """Bulk sync transactions from mobile app - FIXED."""
        import logging
        import json
        import traceback
        
        logger: logging.Logger = logging.getLogger('transactions')
        
        logger.info(f"========== TRANSACTION BULK_SYNC DEBUG ==========")
        logger.info(f"Content-Type: {request.content_type}")
        logger.info(f"Request body type: {type(request.data)}")
        
        try:
            transactions_data: List[Dict[str, Any]] = request.data if isinstance(request.data, list) else []
            logger.info(f" Received {len(transactions_data)} transactions")
            
            if not transactions_data:
                logger.warning(" No transactions data received")
                return Response({
                    'success': False,
                    'error': 'No transactions data provided',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get user profile
            user_profile: Profile = request.user if isinstance(request.user, Profile) else request.user.profile
            logger.info(f"👤 User profile: {user_profile.id}")
            
            created_count: int = 0
            updated_count: int = 0
            errors: List[Dict[str, Any]] = []
            
            for idx, transaction_data in enumerate(transactions_data):
                try:
                    logger.info(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    logger.info(f" Processing transaction {idx + 1}/{len(transactions_data)}")
                    logger.info(f" Raw data: {json.dumps(transaction_data, indent=2, default=str)}")
                    
                    # CRITICAL FIX: Ensure profile is in the data
                    # The serializer needs EITHER 'profile' OR 'profile_id' to validate
                    if 'profile' not in transaction_data and 'profile_id' not in transaction_data:
                        # Add profile as UUID string - serializer will convert to Profile instance
                        transaction_data['profile'] = str(user_profile.id)
                        logger.info(f" Added profile to data: {user_profile.id}")
                    
                    transaction_id: Optional[str] = transaction_data.get('id')
                    
                    if transaction_id:
                        # Try to update existing transaction
                        try:
                            transaction: Transaction = Transaction.objects.get(id=transaction_id, profile=user_profile)
                            logger.info(f" Updating existing transaction: {transaction_id}")
                            
                            serializer: TransactionSerializer = TransactionSerializer(
                                transaction, 
                                data=transaction_data, 
                                partial=True,
                                context={'request': request}
                            )
                            
                            if serializer.is_valid():
                                # FIX: Explicitly set profile
                                serializer.save(profile=user_profile)
                                updated_count += 1
                                logger.info(f" Successfully updated transaction {transaction_id}")
                            else:
                                logger.error(f" Validation failed for transaction {transaction_id}")
                                logger.error(f" Errors: {json.dumps(serializer.errors, indent=2)}")
                                errors.append({
                                    'id': transaction_id,
                                    'errors': serializer.errors,
                                    'data_sent': transaction_data
                                })
                        
                        except Transaction.DoesNotExist:
                            # Create new transaction with this ID
                            logger.info(f"➕ Creating new transaction with ID: {transaction_id}")
                            
                            serializer = TransactionSerializer(
                                data=transaction_data,
                                context={'request': request}
                            )
                            
                            if serializer.is_valid():
                                # FIX: Explicitly set profile
                                serializer.save(profile=user_profile)
                                created_count += 1
                                logger.info(f" Successfully created transaction {transaction_id}")
                            else:
                                logger.error(f" Validation failed for new transaction {transaction_id}")
                                logger.error(f" Errors: {json.dumps(serializer.errors, indent=2)}")
                                errors.append({
                                    'id': transaction_id,
                                    'errors': serializer.errors,
                                    'data_sent': transaction_data
                                })
                    else:
                        # Create completely new transaction (no ID provided)
                        logger.info(f"➕ Creating new transaction (no ID provided)")
                        
                        serializer = TransactionSerializer(
                            data=transaction_data,
                            context={'request': request}
                        )
                        
                        if serializer.is_valid():
                            # FIX: Explicitly set profile
                            serializer.save(profile=user_profile)
                            created_count += 1
                            logger.info(f" Successfully created new transaction")
                        else:
                            logger.error(f" Validation failed for new transaction")
                            logger.error(f" Errors: {json.dumps(serializer.errors, indent=2)}")
                            errors.append({
                                'errors': serializer.errors,
                                'data_sent': transaction_data
                            })
                            
                except Exception as e:
                    logger.exception(f" Exception processing transaction {idx + 1}: {str(e)}")
                    errors.append({
                        'id': transaction_data.get('id'),
                        'error': str(e),
                        'traceback': traceback.format_exc(),
                        'data_sent': transaction_data
                    })
            
            logger.info(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logger.info(f" SYNC COMPLETE")
            logger.info(f" Created: {created_count}")
            logger.info(f" Updated: {updated_count}")
            logger.info(f" Errors: {len(errors)}")
            
            if errors:
                logger.error(f" Detailed errors:")
                for error in errors:
                    logger.error(f"   {json.dumps(error, indent=2, default=str)}")
            
            response_data: Dict[str, Any] = {
                'success': True,
                'created': created_count,
                'updated': updated_count,
                'errors': errors
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f" Fatal error in bulk_sync: {str(e)}")
            return Response({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['get'])
    def summary(self, request: Request) -> Response:
        """Get transaction summary."""
        queryset: QuerySet[Transaction] = self.get_queryset().filter(status=TransactionStatus.COMPLETED)
        
        # Calculate totals by type
        income: float = queryset.filter(type=TransactionType.INCOME).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        expense: float = queryset.filter(type=TransactionType.EXPENSE).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        savings: float = queryset.filter(type=TransactionType.SAVINGS).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        net_flow: float = income - expense
        
        return Response({
            'total_income': income,
            'total_expense': expense,
            'total_savings': savings,
            'net_flow': net_flow,
            'transaction_count': queryset.count()
        })
    
    @action(detail=False, methods=['get'])
    def monthly_summary(self, request: Request) -> Response:
        """Get monthly transaction summary for the last 12 months."""
        from django.db.models.functions import TruncMonth
        
        # Get last 12 months of data
        end_date: datetime = timezone.now()
        start_date: datetime = end_date - timedelta(days=365)
        
        queryset: QuerySet[Transaction] = self.get_queryset().filter(
            status=TransactionStatus.COMPLETED,
            date__gte=start_date,
            date__lte=end_date
        )
        
        # Group by month
        monthly_data: QuerySet = queryset.annotate(
            month=TruncMonth('date')
        ).values('month', 'type').annotate(
            total=Sum('amount')
        ).order_by('month')
        
        # Format response
        summary: Dict[str, Dict[str, float]] = {}
        for item in monthly_data:
            month_str: str = item['month'].strftime('%Y-%m')
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
    
    def get_queryset(self) -> QuerySet[PendingTransaction]:
        """Return pending transactions for current user."""
        # Get user's profile
        try:
            user_profile: Profile = self.request.user.profile
        except (Profile.DoesNotExist, AttributeError):
            return PendingTransaction.objects.none()
        
        queryset: QuerySet[PendingTransaction] = PendingTransaction.objects.filter(profile=user_profile)
        
        # Validate profile_id if provided (must own this profile)
        profile_id: Optional[str] = self.request.query_params.get('profile_id')
        if profile_id:
            # Security: Ensure user owns this profile
            if str(user_profile.id) != str(profile_id):
                return PendingTransaction.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
        
        # Only show pending by default
        only_pending: Optional[str] = self.request.query_params.get('only_pending', 'true')
        if only_pending.lower() == 'true':
            queryset = queryset.filter(status=TransactionStatus.PENDING)
        
        return queryset
    
    def get_serializer(self, *args: Any, **kwargs: Any) -> PendingTransactionSerializer:
        """Override to specify return type."""
        # Cast the result to PendingTransactionSerializer since we know serializer_class is PendingTransactionSerializer
        return cast(PendingTransactionSerializer, super().get_serializer(*args, **kwargs))
    
    def perform_create(self, serializer: PendingTransactionSerializer) -> None:
        """Set profile on create."""
        from rest_framework import serializers
        
        # Get user's profile
        try:
            user_profile: Profile = self.request.user.profile
            serializer.save(profile=user_profile)
        except (Profile.DoesNotExist, AttributeError):
            # If no profile exists, raise validation error
            raise serializers.ValidationError({
                'profile': 'User profile not found'
            })
    
    @action(detail=True, methods=['post'])
    def approve(self, request: Request, pk: Optional[str] = None) -> Response:
        """Approve a pending transaction."""
        pending: PendingTransaction = self.get_object()
        
        if pending.status != TransactionStatus.PENDING:
            return Response({
                'error': 'Only pending transactions can be approved'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer: TransactionApprovalSerializer = TransactionApprovalSerializer(data=request.data)
        
        if serializer.is_valid():
            category_id: Optional[str] = serializer.validated_data.get('category_id')
            category: Optional[Category] = None
            
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
                transaction: Transaction = pending.approve(category=category)
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
    def reject(self, request: Request, pk: Optional[str] = None) -> Response:
        """Reject a pending transaction."""
        pending: PendingTransaction = self.get_object()
        
        try:
            pending.reject()
            return Response({
                'message': 'Transaction rejected'
            }, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
        
        