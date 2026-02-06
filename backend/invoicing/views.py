# invoicing/views.py
from django.shortcuts import render
from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.utils import timezone
from accounts.models import Profile
from .models import Client, Invoice, Loan
from .serializers import ClientSerializer, InvoiceSerializer, LoanSerializer


class ClientViewSet(viewsets.ModelViewSet):
    """ViewSet for Client model."""
    serializer_class = ClientSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_active']
    search_fields = ['name', 'email', 'phone']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']
    
    def get_queryset(self):
        """Return clients for current user."""
        # Handle both User and Profile objects
        if isinstance(self.request.user, Profile):
            user_profile = self.request.user
        else:
            user_profile = self.request.user.profile
        return Client.objects.filter(profile=user_profile)
    
    def perform_create(self, serializer):
        """Set profile on create."""
        # Handle both User and Profile objects
        if isinstance(self.request.user, Profile):
            profile = self.request.user
        else:
            profile = self.request.user.profile
        serializer.save(profile=profile)


class InvoiceViewSet(viewsets.ModelViewSet):
    """ViewSet for Invoice model."""
    serializer_class = InvoiceSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'client', 'is_active']
    search_fields = ['invoice_number', 'description']
    ordering_fields = ['issue_date', 'due_date', 'amount']
    ordering = ['-issue_date']
    
    def get_queryset(self):
        """Return invoices for current user."""
        # Handle both User and Profile objects
        if isinstance(self.request.user, Profile):
            user_profile = self.request.user
        else:
            user_profile = self.request.user.profile
        queryset = Invoice.objects.filter(profile=user_profile)
        
        # Filter overdue invoices
        overdue_only = self.request.query_params.get('overdue_only')
        if overdue_only and overdue_only.lower() == 'true':
            now = timezone.now()
            queryset = queryset.filter(
                due_date__lt=now
            ).exclude(status__in=['paid', 'cancelled'])
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        # Handle both User and Profile objects
        if isinstance(self.request.user, Profile):
            profile = self.request.user
        else:
            profile = self.request.user.profile
        serializer.save(profile=profile)


class LoanViewSet(viewsets.ModelViewSet):
    """ViewSet for Loan model."""
    serializer_class = LoanSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['interest_model']
    search_fields = ['name']
    ordering_fields = ['start_date', 'principal_amount']
    ordering = ['-start_date']
    
    def get_queryset(self):
        """Return loans for current user (excluding soft-deleted)."""
        # Handle both User and Profile objects (authentication may set user to profile directly)
        if isinstance(self.request.user, Profile):
            user_profile = self.request.user
        else:
            user_profile = self.request.user.profile
        queryset = Loan.objects.filter(profile=user_profile, is_deleted=False)
        
        # Validate profile_id if provided (must own this profile)
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            # Security: Ensure user owns this profile
            if str(user_profile.id) != str(profile_id):
                return Loan.objects.none()
            queryset = queryset.filter(profile_id=profile_id, is_deleted=False)
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        # Handle both User and Profile objects
        if isinstance(self.request.user, Profile):
            profile = self.request.user
        else:
            profile = self.request.user.profile
        serializer.save(profile=profile)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get currently active loans."""
        now = timezone.now()
        active_loans = self.get_queryset().filter(
            start_date__lte=now,
            end_date__gte=now
        )
        
        serializer = self.get_serializer(active_loans, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync loans from mobile app."""
        loans_data = request.data if isinstance(request.data, list) else []
        user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
        
        created_count = 0
        updated_count = 0
        errors = []
        
        for loan_data in loans_data:
            try:
                loan_data['profile'] = str(user_profile.id)
                loan_id = loan_data.get('id')
                
                if loan_id:
                    try:
                        loan = Loan.objects.get(id=loan_id, profile=user_profile)
                        serializer = LoanSerializer(loan, data=loan_data, partial=True)
                        if serializer.is_valid():
                            serializer.save()
                            updated_count += 1
                        else:
                            errors.append({'id': loan_id, 'errors': serializer.errors})
                    except Loan.DoesNotExist:
                        serializer = LoanSerializer(data=loan_data)
                        if serializer.is_valid():
                            serializer.save(profile=user_profile)
                            created_count += 1
                        else:
                            errors.append({'id': loan_id, 'errors': serializer.errors})
                else:
                    serializer = LoanSerializer(data=loan_data)
                    if serializer.is_valid():
                        serializer.save(profile=user_profile)
                        created_count += 1
                    else:
                        errors.append({'errors': serializer.errors})
            except Exception as e:
                errors.append({'id': loan_data.get('id'), 'error': str(e)})
        
        return Response({
            'success': True,
            'created': created_count,
            'updated': updated_count,
            'errors': errors
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def batch_delete(self, request):
        """Batch soft-delete loans (mark as deleted, preserve data)."""
        loan_ids = request.data.get('ids', []) if isinstance(request.data, dict) else []
        user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
        
        if not loan_ids:
            return Response({
                'success': False,
                'error': 'No loan IDs provided',
            }, status=status.HTTP_400_BAD_REQUEST)
        
        from django.utils import timezone
        
        deleted_count = 0
        errors = []
        
        for loan_id in loan_ids:
            try:
                loan = Loan.objects.get(id=loan_id, profile=user_profile)
                loan.is_deleted = True
                loan.deleted_at = timezone.now()
                loan.save()
                deleted_count += 1
            except Loan.DoesNotExist:
                errors.append({'id': loan_id, 'error': 'Loan not found'})
            except Exception as e:
                errors.append({'id': loan_id, 'error': str(e)})
        
        return Response({
            'success': True,
            'deleted': deleted_count,
            'errors': errors
        }, status=status.HTTP_200_OK)


