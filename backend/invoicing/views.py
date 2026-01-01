# invoicing/views.py
from django.shortcuts import render
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.utils import timezone
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
        return Client.objects.filter(profile=self.request.user.profile)
    
    def perform_create(self, serializer):
        """Set profile on create."""
        serializer.save(profile=self.request.user.profile)


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
        queryset = Invoice.objects.filter(profile=self.request.user.profile)
        
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
        serializer.save(profile=self.request.user.profile)


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
        """Return loans for current user."""
        user_profile = self.request.user.profile
        queryset = Loan.objects.filter(profile=user_profile)
        
        # Validate profile_id if provided (must own this profile)
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            # Security: Ensure user owns this profile
            if str(user_profile.id) != str(profile_id):
                return Loan.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        serializer.save(profile=self.request.user.profile)
    
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

