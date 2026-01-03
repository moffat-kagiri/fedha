# backend/categories/views.py
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db.models import Sum, Count
from accounts.models import Profile
from .models import Category, CategoryType
from .serializers import CategorySerializer, CategorySummarySerializer


class CategoryViewSet(viewsets.ModelViewSet):
    """ViewSet for Category model."""
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type', 'is_active']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']
    
    def get_serializer_context(self):
        """Add request to serializer context."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def get_queryset(self):
        """Return categories for current user."""
        try:
            user_profile = self.request.user.profile
        except (Profile.DoesNotExist, AttributeError):
            return Category.objects.none()
        
        queryset = Category.objects.filter(profile=user_profile)
        
        # Validate profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            if str(user_profile.id) != str(profile_id):
                return Category.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
        
        return queryset
    
    def perform_create(self, serializer):
        """Override create to let serializer handle profile assignment."""
        serializer.save()
    
    def create(self, request, *args, **kwargs):
        """Override create to handle profile_id validation."""
        profile_id = request.data.get('profile_id')
        if not profile_id:
            return Response(
                {'error': 'profile_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user_profile = request.user.profile
            if str(user_profile.id) != str(profile_id):
                return Response(
                    {'error': 'You can only create categories for your own profile'},
                    status=status.HTTP_403_FORBIDDEN
                )
        except (Profile.DoesNotExist, AttributeError):
            return Response(
                {'error': 'User profile not found'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return super().create(request, *args, **kwargs)
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync categories from mobile app."""
        categories_data = request.data if isinstance(request.data, list) else []
        
        try:
            user_profile = request.user.profile
        except (Profile.DoesNotExist, AttributeError):
            return Response(
                {'error': 'User profile not found'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        created_count = 0
        updated_count = 0
        errors = []
        
        for category_data in categories_data:
            try:
                category_data['profile_id'] = str(user_profile.id)
                category_id = category_data.get('id')
                
                if category_id:
                    try:
                        category = Category.objects.get(
                            id=category_id,
                            profile=user_profile
                        )
                        serializer = CategorySerializer(
                            category,
                            data=category_data,
                            partial=True,
                            context={'request': request}
                        )
                        if serializer.is_valid():
                            serializer.save()
                            updated_count += 1
                        else:
                            errors.append({
                                'id': category_id,
                                'errors': serializer.errors
                            })
                    except Category.DoesNotExist:
                        serializer = CategorySerializer(
                            data=category_data,
                            context={'request': request}
                        )
                        if serializer.is_valid():
                            serializer.save()
                            created_count += 1
                        else:
                            errors.append({
                                'id': category_id,
                                'errors': serializer.errors
                            })
                else:
                    serializer = CategorySerializer(
                        data=category_data,
                        context={'request': request}
                    )
                    if serializer.is_valid():
                        serializer.save()
                        created_count += 1
                    else:
                        errors.append({
                            'errors': serializer.errors
                        })
            except Exception as e:
                errors.append({
                    'id': category_data.get('id'),
                    'error': str(e)
                })
        
        return Response({
            'success': True,
            'created': created_count,
            'updated': updated_count,
            'errors': errors
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def spending_summary(self, request):
        """Get spending summary by category."""
        from transactions.models import Transaction, TransactionType, TransactionStatus
        
        queryset = self.get_queryset().filter(is_active=True)
        
        # Get date range from query params
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        summary = []
        total_spending = 0
        
        for category in queryset:
            transactions = Transaction.objects.filter(
                profile=request.user.profile,
                category=category,
                type=TransactionType.EXPENSE,
                status=TransactionStatus.COMPLETED
            )
            
            if start_date:
                transactions = transactions.filter(transaction_date__gte=start_date)
            if end_date:
                transactions = transactions.filter(transaction_date__lte=end_date)
            
            total = transactions.aggregate(total=Sum('amount'))['total'] or 0
            count = transactions.count()
            
            if total > 0:
                total_spending += float(total)
                summary.append({
                    'category_id': str(category.id),
                    'category_name': category.name,
                    'category_type': category.type,
                    'total_amount': float(total),
                    'transaction_count': count,
                    'color': category.color,
                    'icon': category.icon,
                })
        
        # Calculate percentages
        for item in summary:
            if total_spending > 0:
                item['percentage'] = round((item['total_amount'] / total_spending) * 100, 2)
            else:
                item['percentage'] = 0
        
        # Sort by total amount descending
        summary.sort(key=lambda x: x['total_amount'], reverse=True)
        
        return Response({
            'summary': summary,
            'total_spending': total_spending,
            'category_count': len(summary)
        })
    
    @action(detail=False, methods=['post'])
    def create_defaults(self, request):
        """Create default categories for user."""
        try:
            user_profile = request.user.profile
            created_categories = Category.get_or_create_default_categories(user_profile)
            
            serializer = CategorySerializer(created_categories, many=True)
            return Response({
                'success': True,
                'created_count': len(created_categories),
                'categories': serializer.data
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
            