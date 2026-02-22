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
        """Bulk sync loans from mobile app — upsert with created_ids."""
        import logging
        logger = logging.getLogger('invoicing')
        logger.info("========== LOANS BULK_SYNC ==========")

        loans_data = request.data if isinstance(request.data, list) else []
        user_profile = request.user if isinstance(request.user, Profile) else request.user.profile

        created_count = 0
        updated_count = 0
        errors       = []
        created_ids  = []   # ← was missing; causes infinite re-upload on client

        for loan_data in loans_data:
            try:
                loan_data['profile'] = str(user_profile.id)
                loan_id = loan_data.get('id')

                if loan_id:
                    try:
                        loan = Loan.objects.get(id=loan_id, profile=user_profile, is_deleted=False)
                        serializer = LoanSerializer(loan, data=loan_data, partial=True,
                                                    context={'request': request})
                        if serializer.is_valid():
                            serializer.save()
                            updated_count += 1
                            logger.info(f"[OK] Updated loan: {loan_id}")
                        else:
                            logger.error(f"[ERR] Update validation failed: {serializer.errors}")
                            errors.append({'id': loan_id, 'errors': serializer.errors})
                    except Loan.DoesNotExist:
                        # ID supplied but not found → create with that ID
                        serializer = LoanSerializer(data=loan_data, context={'request': request})
                        if serializer.is_valid():
                            instance = serializer.save(profile=user_profile)
                            created_count += 1
                            created_ids.append(str(instance.id))
                            logger.info(f"[OK] Created loan (supplied id not found): {instance.id}")
                        else:
                            logger.error(f"[ERR] Create validation failed: {serializer.errors}")
                            errors.append({'id': loan_id, 'errors': serializer.errors})
                else:
                    # No ID → always create
                    serializer = LoanSerializer(data=loan_data, context={'request': request})
                    if serializer.is_valid():
                        instance = serializer.save(profile=user_profile)
                        created_count += 1
                        created_ids.append(str(instance.id))
                        logger.info(f"[OK] Created loan: {instance.id}")
                    else:
                        logger.error(f"[ERR] Create validation failed: {serializer.errors}")
                        errors.append({'errors': serializer.errors, 'data': loan_data})

            except Exception as e:
                logger.exception(f"[ERR] Exception syncing loan: {str(e)}")
                errors.append({'id': loan_data.get('id'), 'error': str(e)})

        logger.info(f"[DONE] created={created_count}, updated={updated_count}, errors={len(errors)}")
        return Response({
            'success': len(errors) == 0,
            'created': created_count,
            'updated': updated_count,
            'created_ids': created_ids,   # ← now returned
            'errors': errors,
        }, status=status.HTTP_200_OK)

    # ── ADD batch_update (was completely missing) ─────────────────────────
    @action(detail=False, methods=['post'])
    def batch_update(self, request):
        """Batch update existing loans from mobile app.

        Request body: JSON array of loan objects, each with an 'id' field.
        Response: { success, updated, failed_count, failed_ids, errors }
        """
        import logging
        logger = logging.getLogger('invoicing')
        logger.info("========== LOANS BATCH_UPDATE ==========")

        loans_data = request.data if isinstance(request.data, list) else []
        if not loans_data:
            return Response({'success': False, 'error': 'No loan data provided'},
                            status=status.HTTP_400_BAD_REQUEST)

        user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
        updated_count = 0
        failed_ids    = []
        errors        = []

        for loan_data in loans_data:
            loan_id = loan_data.get('id')
            if not loan_id:
                errors.append({'error': 'Missing id field', 'data': loan_data})
                continue
            try:
                loan = Loan.objects.get(id=loan_id, profile=user_profile, is_deleted=False)
                serializer = LoanSerializer(loan, data=loan_data, partial=True,
                                            context={'request': request})
                if serializer.is_valid():
                    serializer.save(updated_at=timezone.now())
                    updated_count += 1
                    logger.info(f"[OK] Updated loan {loan_id}")
                else:
                    logger.error(f"[ERR] Validation failed for {loan_id}: {serializer.errors}")
                    failed_ids.append(loan_id)
                    errors.append({'id': loan_id, 'errors': serializer.errors})
            except Loan.DoesNotExist:
                logger.error(f"[ERR] Loan not found: {loan_id}")
                failed_ids.append(loan_id)
                errors.append({'id': loan_id, 'error': 'Loan not found or already deleted'})
            except Exception as e:
                logger.exception(f"[ERR] Exception updating loan {loan_id}: {e}")
                failed_ids.append(loan_id)
                errors.append({'id': loan_id, 'error': str(e)})

        logger.info(f"[DONE] updated={updated_count}, failed={len(failed_ids)}")
        return Response({
            'success': len(failed_ids) == 0,
            'updated': updated_count,
            'failed_count': len(failed_ids),
            'failed_ids': failed_ids,
            'errors': errors if errors else None,
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def batch_delete(self, request):
        """Batch soft-delete loans.

        Accepts: { 'ids': [...] }  OR  { 'loan_ids': [...] }
        """
        import logging
        from django.utils import timezone as tz
        logger = logging.getLogger('invoicing')
        logger.info("========== LOANS BATCH_DELETE (SOFT) ==========")

        # Accept both key names so old and new client versions work
        loan_ids = (request.data.get('ids') or
                    request.data.get('loan_ids') or [])

        if not loan_ids:
            return Response({'success': False, 'error': 'No loan IDs provided'},
                            status=status.HTTP_400_BAD_REQUEST)

        user_profile  = request.user if isinstance(request.user, Profile) else request.user.profile
        deleted_count = 0
        already_deleted = 0
        failed_ids    = []
        errors        = []
        now           = tz.now()

        for loan_id in loan_ids:
            try:
                loan = Loan.objects.get(id=loan_id, profile=user_profile)
                if loan.is_deleted:
                    already_deleted += 1
                    continue
                loan.is_deleted = True
                loan.deleted_at = now
                loan.save(update_fields=['is_deleted', 'deleted_at', 'updated_at'])
                deleted_count += 1
                logger.info(f"[OK] Soft-deleted loan {loan_id}")
            except Loan.DoesNotExist:
                logger.error(f"[ERR] Loan not found: {loan_id}")
                failed_ids.append(loan_id)
                errors.append({'id': loan_id, 'error': 'Loan not found'})
            except Exception as e:
                logger.exception(f"[ERR] Exception deleting loan {loan_id}: {e}")
                failed_ids.append(loan_id)
                errors.append({'id': loan_id, 'error': str(e)})

        logger.info(f"[DONE] deleted={deleted_count}, already_deleted={already_deleted}, "
                    f"failed={len(failed_ids)}")
        return Response({
            'success': len(failed_ids) == 0,
            'deleted': deleted_count,
            'soft_deleted': deleted_count,
            'already_deleted': already_deleted,
            'failed_count': len(failed_ids),
            'failed_ids': failed_ids,
            'errors': errors if errors else None,
            'note': 'Loans are soft-deleted (data preserved)',
        }, status=status.HTTP_200_OK)
    