# goals/views.py
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from django.shortcuts import render
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from accounts.models import Profile
from .models import Goal, GoalStatus, GoalType
from .serializers import (
    GoalSerializer, GoalContributionSerializer, BulkGoalSerializer
)


class GoalViewSet(viewsets.ModelViewSet):
    """ViewSet for Goal model."""
    serializer_class = GoalSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'goal_type']
    search_fields = ['name', 'description']
    ordering_fields = ['created_at', 'target_date', 'target_amount', 'current_amount']
    ordering = ['-created_at']
    
    def get_serializer_context(self):
        """Add request to serializer context."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def get_queryset(self):
        """Return goals for current user."""
        # Get user's profile
        try:
            user_profile = self.request.user.profile
        except (Profile.DoesNotExist, AttributeError):
            # If no profile exists, return empty queryset
            return Goal.objects.none()
        
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
        """Override create to let serializer handle profile assignment."""
        # The serializer now handles profile assignment via profile_id
        # We don't need to set profile here anymore
        serializer.save()
    
    def create(self, request, *args, **kwargs):
        """Override create to handle profile_id validation."""
        print(f"Goal POST data: {request.data}")
        
        # Check if profile_id is provided
        profile_id = request.data.get('profile_id')
        if not profile_id:
            return Response(
                {'error': 'profile_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verify the user owns this profile
        # request.user IS the Profile instance
        user_profile = request.user
        
        if str(user_profile.id) != str(profile_id):
            print(f"❌ User {user_profile.id} doesn't own profile {profile_id}")
            return Response(
                {'error': 'You can only create goals for your own profile'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        print(f"✅ User {user_profile.id} is authorized for profile {profile_id}")
        
        # Continue with normal create but add error logging
        serializer = self.get_serializer(data=request.data)
        
        # Log validation errors
        if not serializer.is_valid():
            print(f"❌❌❌ GOAL VALIDATION ERRORS: {serializer.errors}")
            print(f"❌❌❌ Raw errors dict: {dict(serializer.errors)}")
            
            for field_name, errors in serializer.errors.items():
                print(f"❌ Field '{field_name}': {errors}")
            
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        print(f"✅ Goal data is valid, creating...")
        
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

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
                    'goal': GoalSerializer(goal, context={'request': request}).data
                }, status=status.HTTP_200_OK)
            except ValueError as e:
                return Response({
                    'error': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'])
    def bulk_sync(self, request):
        """Bulk sync goals from mobile app."""
        import logging
        import json
        logger = logging.getLogger('goals')
        
        # logger.info(f"========== GOALS BULK_SYNC DEBUG ==========")
        # logger.info(f"Content-Type: {request.content_type}")
        # logger.info(f"Request body type: {type(request.data)}")
        # logger.info(f"Request body: {json.dumps(request.data, indent=2, default=str)}")
        
        try:
            goals_data = request.data if isinstance(request.data, list) else []
            # logger.info(f"Parsed goals_data: {len(goals_data)} items")
            
            if not goals_data:
                # logger.warning("No goals data received")
                return Response({
                    'success': False,
                    'error': 'No goals data provided',
                    'received_type': str(type(request.data)),
                    'received_data': request.data
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            # logger.info(f"User profile: {user_profile.id}")
            
            created_count = 0
            updated_count = 0
            errors = []
            
            for idx, goal_data in enumerate(goals_data):
                try:
                    # logger.info(f"Processing goal {idx + 1}: {json.dumps(goal_data, indent=2, default=str)}")
                    
                    goal_data['profile'] = str(user_profile.id)
                    goal_id = goal_data.get('id')
                    
                    if goal_id:
                        try:
                            goal = Goal.objects.get(id=goal_id, profile=user_profile)
                            serializer = GoalSerializer(goal, data=goal_data, partial=True)
                            
                            if serializer.is_valid():
                                serializer.save()
                                updated_count += 1
                                # logger.info(f"✅ Updated goal {goal_id}")
                            else:
                                # logger.error(f"❌ Validation errors for goal {goal_id}: {serializer.errors}")
                                errors.append({
                                    'id': goal_id,
                                    'errors': serializer.errors,
                                    'data_sent': goal_data
                                })
                        except Goal.DoesNotExist:
                            # logger.info(f"Goal {goal_id} not found, creating new...")
                            serializer = GoalSerializer(data=goal_data)
                            
                            if serializer.is_valid():
                                serializer.save(profile=user_profile)
                                created_count += 1
                                # logger.info(f"✅ Created goal {goal_id}")
                            else:
                                # logger.error(f"❌ Validation errors for new goal: {serializer.errors}")
                                errors.append({
                                    'id': goal_id,
                                    'errors': serializer.errors,
                                    'data_sent': goal_data
                                })
                    else:
                        # logger.info(f"Creating goal without ID...")
                        serializer = GoalSerializer(data=goal_data)
                        
                        if serializer.is_valid():
                            serializer.save(profile=user_profile)
                            created_count += 1
                            # logger.info(f"✅ Created new goal")
                        else:
                            # logger.error(f"❌ Validation errors: {serializer.errors}")
                            errors.append({
                                'errors': serializer.errors,
                                'data_sent': goal_data
                            })
                            
                except Exception as e:
                    # logger.exception(f"❌ Exception processing goal {idx + 1}: {str(e)}")
                    errors.append({
                        'id': goal_data.get('id'),
                        'error': str(e),
                        'data_sent': goal_data
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
    
    @action(detail=True, methods=['patch'])
    def complete(self, request, pk=None):
        """Mark a goal as completed."""
        goal = self.get_object()
        
        try:
            goal.mark_completed()
            return Response({
                'message': 'Goal marked as completed',
                'goal': GoalSerializer(goal, context={'request': request}).data
            }, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['patch'])
    def update_progress(self, request, pk=None):
        """Update goal progress manually."""
        goal = self.get_object()
        
        current_amount = request.data.get('current_amount')
        if current_amount is None:
            return Response(
                {'error': 'current_amount is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            goal.current_amount = float(current_amount)
            if goal.current_amount >= goal.target_amount:
                goal.status = GoalStatus.COMPLETED
            goal.save()
            
            return Response({
                'message': 'Progress updated successfully',
                'goal': GoalSerializer(goal, context={'request': request}).data
            }, status=status.HTTP_200_OK)
        except (ValueError, TypeError) as e:
            return Response({
                'error': 'Invalid amount value'
            }, status=status.HTTP_400_BAD_REQUEST)
            