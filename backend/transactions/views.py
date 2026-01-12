# transactions/views.py
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
    
    def get_queryset(self):
        """Return transactions for current user with date filtering."""
        # Get user's profile
        try:
            user_profile = self.request.user.profile
        except (Profile.DoesNotExist, AttributeError):
            # If no profile exists, return empty queryset
            return Transaction.objects.none()
        
        queryset = Transaction.objects.filter(profile=user_profile)
        
        # Validate profile_id if provided (must own this profile)
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            # Security: Ensure user owns this profile
            if str(user_profile.id) != str(profile_id):
                return Transaction.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
        
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
        print(f"📥 Transaction POST data: {request.data}")
        
        data = request.data.copy()
        if 'category_id' in data and 'category' not in data:
            data['category'] = data.pop('category_id')
    
        serializer = self.get_serializer(data=data)
        # Check if profile_id is provided
        profile_id = request.data.get('profile_id')
        if not profile_id:
            print(f"❌ No profile_id provided")
            return Response(
                {'error': 'profile_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verify the user owns this profile
        # request.user IS the Profile instance (AUTH_USER_MODEL = 'accounts.Profile')
        user_profile = request.user  # This is already the Profile
        
        if str(user_profile.id) != str(profile_id):
            print(f"❌ User {user_profile.id} doesn't own profile {profile_id}")
            return Response(
                {'error': 'You can only create transactions for your own profile'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        print(f"✅ User {user_profile.id} is authorized for profile {profile_id}")
        
        try:
            # Get serializer and validate
            serializer = self.get_serializer(data=request.data)
            print(f"✅ Serializer created")
            
            # Check if data is valid
            if not serializer.is_valid():
                print(f"❌❌❌ TRANSACTION VALIDATION ERRORS: {serializer.errors}")
                print(f"❌❌❌ Raw errors dict: {dict(serializer.errors)}")
                
                # Log each field error in detail
                for field_name, errors in serializer.errors.items():
                    print(f"❌ Field '{field_name}': {errors}")
                
                return Response(
                    serializer.errors,
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            print(f"✅ Transaction data is valid, creating...")
            print(f"✅ Validated data: {serializer.validated_data}")
            
            # If valid, proceed with creation
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            print(f"✅ Transaction created successfully!")
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            print(f"❌❌❌ EXCEPTION in create method: {str(e)}")
            print(f"❌❌❌ Exception type: {type(e)}")
            import traceback
            print(f"❌❌❌ Traceback: {traceback.format_exc()}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync transactions from mobile app."""
        import logging
        import json
        logger = logging.getLogger('transactions')
        
        # Log the incoming request
        #logger.info(f"========== TRANSACTION BULK_SYNC DEBUG ==========")
        #logger.info(f"Content-Type: {request.content_type}")
        #logger.info(f"Request body type: {type(request.data)}")
        #logger.info(f"Request body: {json.dumps(request.data, indent=2, default=str)}")
        
        try:
            transactions_data = request.data if isinstance(request.data, list) else []
            logger.info(f"Parsed transactions_data: {len(transactions_data)} items")
            
            if not transactions_data:
                logger.warning("No transactions data received")
                return Response({
                    'success': False,
                    'error': 'No transactions data provided',
                    'received_type': str(type(request.data)),
                    'received_data': request.data
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            # logger.info(f"User profile: {user_profile.id}")
            
            created_count = 0
            updated_count = 0
            errors = []
            
            for idx, transaction_data in enumerate(transactions_data):
                try:
                    #logger.info(f"Processing transaction {idx + 1}: {json.dumps(transaction_data, indent=2, default=str)}")
                    
                    # Add profile to data
                    transaction_data['profile'] = str(user_profile.id)
                    transaction_id = transaction_data.get('id')
                    
                    if transaction_id:
                        try:
                            transaction = Transaction.objects.get(id=transaction_id, profile=user_profile)
                            serializer = TransactionSerializer(transaction, data=transaction_data, partial=True)
                            
                            if serializer.is_valid():
                                serializer.save()
                                updated_count += 1
                                logger.info(f"✅ Updated transaction {transaction_id}")
                            else:
                                # logger.error(f"❌ Validation errors for transaction {transaction_id}: {serializer.errors}")
                                errors.append({
                                    'id': transaction_id,
                                    'errors': serializer.errors,
                                    'data_sent': transaction_data
                                })
                        except Transaction.DoesNotExist:
                            # logger.info(f"Transaction {transaction_id} not found, creating new...")
                            serializer = TransactionSerializer(data=transaction_data)
                            
                            if serializer.is_valid():
                                serializer.save(profile=user_profile)
                                created_count += 1
                                # logger.info(f"✅ Created transaction {transaction_id}")
                            else:
                                # logger.error(f"❌ Validation errors for new transaction: {serializer.errors}")
                                errors.append({
                                    'id': transaction_id,
                                    'errors': serializer.errors,
                                    'data_sent': transaction_data
                                })
                    else:
                        # logger.info(f"Creating transaction without ID...")
                        serializer = TransactionSerializer(data=transaction_data)
                        
                        if serializer.is_valid():
                            serializer.save(profile=user_profile)
                            created_count += 1
                            # logger.info(f"✅ Created new transaction")
                        else:
                            # logger.error(f"❌ Validation errors: {serializer.errors}")
                            errors.append({
                                'errors': serializer.errors,
                                'data_sent': transaction_data
                            })
                            
                except Exception as e:
                    # logger.exception(f"❌ Exception processing transaction {idx + 1}: {str(e)}")
                    errors.append({
                        'id': transaction_data.get('id'),
                        'error': str(e),
                        'data_sent': transaction_data
                    })
            
            response_data = {
                'success': True,
                'created': created_count,
                'updated': updated_count,
                'errors': errors
            }
            
            # logger.info(f"========== SYNC COMPLETE ==========")
            # logger.info(f"Response: {json.dumps(response_data, indent=2, default=str)}")
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            # logger.exception(f"❌ Fatal error in bulk_sync: {str(e)}")
            return Response({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
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
        # Get user's profile
        try:
            user_profile = self.request.user.profile
            serializer.save(profile=user_profile)
        except (Profile.DoesNotExist, AttributeError):
            # If no profile exists, raise validation error
            raise serializers.ValidationError({
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
            