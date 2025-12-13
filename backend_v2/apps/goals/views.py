# apps/goals/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum, Count, Q
from decimal import Decimal

from .models import Goal
from .serializers import GoalSerializer, GoalContributionSerializer


class GoalViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Goal CRUD operations
    Matches Flutter: GoalService
    """
    serializer_class = GoalSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Goal.objects.filter(user=self.request.user)
        
        # Filter by profile_id if provided
        profile_id = self.request.query_params.get('profile_id')
        if profile_id:
            queryset = queryset.filter(profile_id=profile_id)
        
        # Filter by status
        goal_status = self.request.query_params.get('status')
        if goal_status:
            queryset = queryset.filter(status=goal_status)
        
        # Filter by type
        goal_type = self.request.query_params.get('type')
        if goal_type:
            queryset = queryset.filter(goal_type=goal_type)
        
        # Filter by priority
        priority = self.request.query_params.get('priority')
        if priority:
            queryset = queryset.filter(priority=priority)
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """
        Get goals summary/overview
        Matches Flutter: getGoalsSummary()
        """
        queryset = self.get_queryset()
        
        # Calculate aggregates
        summary = queryset.aggregate(
            total_target=Sum('target_amount') or Decimal('0'),
            total_saved=Sum('current_amount') or Decimal('0'),
            goals_count=Count('id'),
            completed_count=Count('id', filter=Q(status='completed')),
            active_count=Count('id', filter=Q(status='active')),
        )
        
        summary['total_remaining'] = summary['total_target'] - summary['total_saved']
        
        if summary['total_target'] > 0:
            summary['overall_progress'] = float(
                (summary['total_saved'] / summary['total_target'] * 100)
            )
        else:
            summary['overall_progress'] = 0.0
        
        # Count overdue goals
        from django.db.models import F
        from datetime import datetime
        summary['overdue_count'] = queryset.filter(
            status='active',
            target_date__lt=datetime.now().date()
        ).count()
        
        # Get all goals with computed fields
        goals = []
        for goal in queryset:
            goal_data = GoalSerializer(goal).data
            goals.append(goal_data)
        
        summary['goals'] = goals
        
        return Response(summary)
    
    @action(detail=True, methods=['post'])
    def add_contribution(self, request, pk=None):
        """
        Add contribution to goal
        Matches Flutter: addContribution()
        """
        goal = self.get_object()
        serializer = GoalContributionSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response({
                'success': False,
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        amount = serializer.validated_data['amount']
        
        try:
            # Use the model's add_contribution method
            updated_goal = goal.add_contribution(float(amount))
            
            goal_serializer = GoalSerializer(updated_goal)
            return Response({
                'success': True,
                'goal': goal_serializer.data
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active goals"""
        goals = self.get_queryset().filter(status='active')
        serializer = self.get_serializer(goals, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def completed(self, request):
        """Get all completed goals"""
        goals = self.get_queryset().filter(status='completed')
        serializer = self.get_serializer(goals, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def overdue(self, request):
        """Get all overdue goals"""
        from datetime import datetime
        goals = self.get_queryset().filter(
            status='active',
            target_date__lt=datetime.now().date()
        )
        serializer = self.get_serializer(goals, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark goal as completed"""
        goal = self.get_object()
        goal.status = 'completed'
        goal.completed_date = datetime.now()
        goal.save()
        
        serializer = self.get_serializer(goal)
        return Response({
            'success': True,
            'goal': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def pause(self, request, pk=None):
        """Pause goal"""
        goal = self.get_object()
        goal.status = 'paused'
        goal.save()
        
        serializer = self.get_serializer(goal)
        return Response({
            'success': True,
            'goal': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def resume(self, request, pk=None):
        """Resume paused goal"""
        goal = self.get_object()
        goal.status = 'active'
        goal.save()
        
        serializer = self.get_serializer(goal)
        return Response({
            'success': True,
            'goal': serializer.data
        })
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """
        Bulk sync goals from Flutter app
        """
        goals_data = request.data
        user = request.user
        
        created = []
        updated = []
        conflicts = []
        
        for goal_data in goals_data:
            goal_id = goal_data.get('id')
            
            try:
                # Check if exists
                existing = Goal.objects.get(id=goal_id, user=user)
                
                # Update existing
                serializer = GoalSerializer(
                    existing, 
                    data=goal_data, 
                    partial=True,
                    context={'request': request}
                )
                if serializer.is_valid():
                    serializer.save()
                    updated.append(serializer.data)
                else:
                    conflicts.append({'id': goal_id, 'errors': serializer.errors})
                    
            except Goal.DoesNotExist:
                # Create new
                serializer = GoalSerializer(
                    data=goal_data,
                    context={'request': request}
                )
                if serializer.is_valid():
                    serializer.save()
                    created.append(serializer.data)
                else:
                    conflicts.append({'id': goal_id, 'errors': serializer.errors})
        
        return Response({
            'success': True,
            'created': len(created),
            'updated': len(updated),
            'conflicts': len(conflicts),
            'data': {
                'created': created,
                'updated': updated,
                'conflicts': conflicts
            }
        })