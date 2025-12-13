# apps/invoicing/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum, Count, Q
from .models import Client, Invoice, Loan
from .serializers import ClientSerializer, InvoiceSerializer, LoanSerializer

class ClientViewSet(viewsets.ModelViewSet):
    """ViewSet for Client CRUD operations"""
    serializer_class = ClientSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Client.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get active clients"""
        clients = self.get_queryset().filter(is_active=True)
        serializer = self.get_serializer(clients, many=True)
        return Response(serializer.data)


class InvoiceViewSet(viewsets.ModelViewSet):
    """ViewSet for Invoice CRUD operations"""
    serializer_class = InvoiceSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Invoice.objects.filter(user=self.request.user)
        
        # Filter by client
        client_id = self.request.query_params.get('client_id')
        if client_id:
            queryset = queryset.filter(client_id=client_id)
        
        # Filter by status
        invoice_status = self.request.query_params.get('status')
        if invoice_status:
            queryset = queryset.filter(status=invoice_status)
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def overdue(self, request):
        """Get overdue invoices"""
        from datetime import datetime
        invoices = self.get_queryset().filter(
            status__in=['sent', 'overdue'],
            due_date__lt=datetime.now().date()
        )
        serializer = self.get_serializer(invoices, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get invoice summary"""
        queryset = self.get_queryset()
        
        summary = queryset.aggregate(
            total_invoiced=Sum('amount') or 0,
            paid_total=Sum('amount', filter=Q(status='paid')) or 0,
            pending_total=Sum('amount', filter=Q(status='sent')) or 0,
            overdue_total=Sum('amount', filter=Q(status='overdue')) or 0,
            total_count=Count('id'),
            paid_count=Count('id', filter=Q(status='paid')),
            pending_count=Count('id', filter=Q(status='sent')),
            overdue_count=Count('id', filter=Q(status='overdue')),
        )
        
        return Response(summary)
    
    @action(detail=True, methods=['post'])
    def mark_paid(self, request, pk=None):
        """Mark invoice as paid"""
        invoice = self.get_object()
        invoice.status = 'paid'
        invoice.save()
        
        serializer = self.get_serializer(invoice)
        return Response({
            'success': True,
            'invoice': serializer.data
        })


class LoanViewSet(viewsets.ModelViewSet):
    """ViewSet for Loan CRUD operations"""
    serializer_class = LoanSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Loan.objects.filter(user=self.request.user)
        
        # Filter by profile_id
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get active loans (not past end date)"""
        from datetime import datetime
        loans = self.get_queryset().filter(end_date__gte=datetime.now().date())
        serializer = self.get_serializer(loans, many=True)
        return Response(serializer.data)
