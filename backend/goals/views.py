# goals/views.py
# Create your views here.
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from django.shortcuts import render
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from .models import Goal, GoalStatus, GoalType
from .serializers import (
    GoalSerializer, GoalContributionSerializer, BulkGoalSerializer
)


class GoalViewSet(viewsets.ModelViewSet):
    """ViewSet for Goal model."""
    serializer_class = GoalSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'goal_type', 'priority']
    search_fields = ['name', 'description']
    ordering_fields = ['created_at', 'target_date', 'target_amount', 'current_amount']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Return goals for current user."""
        user_profile = self.request.user.profile
        queryset = Goal.objects.filter(profile=user_profile)
        
        # Validate profile_id if provided (must own this profile)
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            # Security: Ensure user owns this profile
            if str(user_profile.id) != str(profile_id):
                return Goal.objects.none()
            queryset = queryset.filter(profile_id=profile_id)
        
        # Filter active goals
        active_only = self.request.query_params.get('active_only')
        if active_only and active_only.lower() == 'true':
            queryset = queryset.filter(status=GoalStatus.ACTIVE)
        
        return queryset
    
    def perform_create(self, serializer):
        """Set profile on create."""
        serializer.save(profile=self.request.user.profile)
    
    @action(detail=True, methods=['post'])
    def contribute(self, request, pk=None):
        """Add a contribution to a goal."""
        goal = self.get_object()
        serializer = GoalContributionSerializer(data=request.data)
        
        if serializer.is_valid():
            amount = serializer.validated_data['amount']
            
            try:
                goal.add_contribution(amount)
                return Response({
                    'message': 'Contribution added successfully',
                    'goal': GoalSerializer(goal).data
                }, status=status.HTTP_200_OK)
            except ValueError as e:
                return Response({
                    'error': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync goals from mobile app."""
        # Expect array of goals directly
        goals_data = request.data if isinstance(request.data, list) else []
        user_profile = request.user.profile
        
        created_count = 0
        updated_count = 0
        errors = []
        
        for goal_data in goals_data:
            try:
                # Ensure profile is set
                goal_data['profile'] = str(user_profile.id)
                
                goal_id = goal_data.get('id')
                
                if goal_id:
                    # Try to update existing goal
                    try:
                        goal = Goal.objects.get(id=goal_id, profile=user_profile)
                        serializer = GoalSerializer(goal, data=goal_data, partial=True)
                        if serializer.is_valid():
                            serializer.save()
                            updated_count += 1
                        else:
                            errors.append({
                                'id': goal_id,
                                'errors': serializer.errors
                            })
                    except Goal.DoesNotExist:
                        # Create new goal with specified ID
                        serializer = GoalSerializer(data=goal_data)
                        if serializer.is_valid():
                            serializer.save(profile=user_profile)
                            created_count += 1
                        else:
                            errors.append({
                                'id': goal_id,
                                'errors': serializer.errors
                            })
                else:
                    # Create new goal
                    serializer = GoalSerializer(data=goal_data)
                    if serializer.is_valid():
                        serializer.save(profile=user_profile)
                        created_count += 1
                    else:
                        errors.append({
                            'errors': serializer.errors
                        })
            except Exception as e:
                errors.append({
                    'id': goal_data.get('id'),
                    'error': str(e)
                })
        
        return Response({
            'success': True,
            'created': created_count,
            'updated': updated_count,
            'errors': errors
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get summary of all goals."""
        goals = self.get_queryset()
        
        total_goals = goals.count()
        active_goals = goals.filter(status=GoalStatus.ACTIVE).count()
        completed_goals = goals.filter(status=GoalStatus.COMPLETED).count()
        
        total_target = sum(g.target_amount for g in goals)
        total_current = sum(g.current_amount for g in goals)
        overall_progress = (total_current / total_target * 100) if total_target > 0 else 0
        
        return Response({
            'total_goals': total_goals,
            'active_goals': active_goals,
            'completed_goals': completed_goals,
            'total_target_amount': total_target,
            'total_current_amount': total_current,
            'overall_progress': round(overall_progress, 2)
        })

