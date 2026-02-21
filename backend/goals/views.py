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
        """Return goals for current user (excluding soft-deleted and cancelled)."""
        # ✅ FIX: request.user IS the Profile (custom auth model)
        user_profile = self.request.user if isinstance(self.request.user, Profile) else self.request.user.profile
        
        # ✅ CRITICAL FIX: Filter by profile and exclude soft-deleted AND cancelled goals
        # Cancelled goals should not appear in GET requests to avoid confusion
        queryset = Goal.objects.filter(
            profile=user_profile, 
            is_deleted=False
        ).exclude(status=GoalStatus.CANCELLED)  # ✅ NEW: Exclude cancelled goals
        
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
        """Bulk sync goals with ID and Name-fallback deduplication."""
        import logging
        logger = logging.getLogger('goals')
        
        try:
            goals_data = request.data if isinstance(request.data, list) else []
            if not goals_data:
                return Response({'success': False, 'error': 'No data'}, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = request.user if isinstance(request.user, Profile) else request.user.profile
            
            created_count = 0
            updated_count = 0
            created_ids = []
            updated_ids = []
            errors = []
            
            for goal_data in goals_data:
                try:
                    goal_id = goal_data.get('id')
                    goal_name = goal_data.get('name')
                    goal_instance = None

                    # 1. Try Primary Lookup (Remote ID)
                    if goal_id:
                        goal_instance = Goal.objects.filter(id=goal_id, profile=user_profile).first()

                    # 2. Try Fallback Lookup (Name + Profile)
                    if not goal_instance and goal_name:
                        # We look for active/completed goals with the same name to prevent duplicates
                        goal_instance = Goal.objects.filter(
                            name=goal_name, 
                            profile=user_profile,
                            status__in=['active', 'completed']
                        ).first()

                    if goal_instance:
                        # ✅ UPDATE existing goal
                        serializer = GoalSerializer(goal_instance, data=goal_data, partial=True)
                        if serializer.is_valid():
                            serializer.save()
                            updated_count += 1
                            updated_ids.append(str(goal_instance.id))
                        else:
                            errors.append({'name': goal_name, 'errors': serializer.errors})
                    else:
                        # ✅ CREATE new goal
                        serializer = GoalSerializer(data=goal_data)
                        if serializer.is_valid():
                            new_goal = serializer.save(profile=user_profile)
                            created_count += 1
                            created_ids.append(str(new_goal.id))
                        else:
                            errors.append({'name': goal_name, 'errors': serializer.errors})
                                
                except Exception as e:
                    errors.append({'name': goal_data.get('name'), 'error': str(e)})
            
            return Response({
                'success': True,
                'created': created_count,
                'updated': updated_count,
                'created_ids': created_ids, # Required by Dart code for mapping
                'updated_ids': updated_ids,
                'errors': errors
            }, status=status.HTTP_200_OK)
                
        except Exception as e:
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
    
    @action(detail=False, methods=['post'])
    def batch_sync(self, request):
        """Batch sync goals from mobile app (create/update).
        
        Request format:
        POST /api/goals/batch_sync/
        {
            'goals': [
                {
                    'name': 'Save for vacation',
                    'goal_type': 'savings',
                    'target_amount': 100000,
                    'current_amount': 45000,
                    'target_date': '2026-12-31T23:59:59Z',
                    'status': 'active',
                    'profile_id': 'uuid'
                },
                ...
            ],
            'profile_id': 'uuid'  # Optional, for validation
        }
        
        Response:
        {
            'success': True,
            'created': N,
            'updated': M,
            'created_ids': ['server_id_1', 'server_id_2', ...],  # Server UUIDs for new goals
            'updated_ids': ['id_1', 'id_2', ...],                # IDs that were updated
            'errors': []
        }
        """
        import logging
        logger = logging.getLogger('goals')
        logger.info("========== GOALS BATCH_SYNC ==========")
        
        try:
            # Get goals from request (support both 'goals' and direct list)
            goals_data = request.data.get('goals') if isinstance(request.data, dict) else request.data
            if not isinstance(goals_data, list):
                goals_data = [goals_data] if goals_data else []
            
            logger.info(f"[RECV] Received {len(goals_data)} goals to sync")
            
            if not goals_data:
                return Response({
                    'success': False,
                    'error': 'No goals data provided',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = self.request.user if isinstance(self.request.user, Profile) else self.request.user.profile
            logger.info(f"[USER] Syncing for profile: {user_profile.id}")
            
            created_count = 0
            updated_count = 0
            created_ids = []  # ✅ Track server UUIDs of newly created goals
            updated_ids = []  # ✅ Track IDs of updated goals
            errors = []
            
            for idx, goal_data in enumerate(goals_data):
                try:
                    goal_id = goal_data.get('id')
                    
                    if goal_id:
                        try:
                            # Try to get existing goal
                            goal = Goal.objects.get(id=goal_id, profile=user_profile)
                            
                            # Update existing goal
                            serializer = GoalSerializer(goal, data=goal_data, partial=True)
                            if serializer.is_valid():
                                serializer.save()
                                updated_count += 1
                                updated_ids.append(goal_id)
                                logger.info(f"[OK] Updated goal {goal_id}")
                            else:
                                errors.append({
                                    'id': goal_id,
                                    'error': 'Validation failed',
                                    'details': serializer.errors
                                })
                                logger.error(f"[ERR] Validation error updating {goal_id}: {serializer.errors}")
                        except Goal.DoesNotExist:
                            # Create new goal (even though ID was provided, it doesn't exist)
                            goal_data['profile_id'] = str(user_profile.id)
                            serializer = GoalSerializer(data=goal_data)
                            
                            if serializer.is_valid():
                                goal = serializer.save(profile=user_profile)
                                created_count += 1
                                created_ids.append(str(goal.id))  # ✅ Track server UUID
                                logger.info(f"[OK] Created goal (requested ID {goal_id}, got server ID {goal.id})")
                            else:
                                errors.append({
                                    'id': goal_id,
                                    'error': 'Validation failed',
                                    'details': serializer.errors
                                })
                                logger.error(f"[ERR] Validation error creating {goal_id}: {serializer.errors}")
                    else:
                        # Create new goal without ID (generate new UUID)
                        goal_data['profile_id'] = str(user_profile.id)
                        serializer = GoalSerializer(data=goal_data)
                        
                        if serializer.is_valid():
                            goal = serializer.save(profile=user_profile)
                            created_count += 1
                            created_ids.append(str(goal.id))  # ✅ Track server UUID
                            logger.info(f"[OK] Created new goal: {goal.id}")
                        else:
                            errors.append({
                                'error': 'Validation failed',
                                'details': serializer.errors
                            })
                            logger.error(f"[ERR] Validation error creating new goal: {serializer.errors}")
                            
                except Exception as e:
                    logger.exception(f"[ERR] Exception syncing goal {goal_id}: {str(e)}")
                    errors.append({
                        'id': goal_data.get('id'),
                        'error': str(e)
                    })
            
            response_data = {
                'success': len(errors) == 0,
                'created': created_count,
                'updated': updated_count,
                'created_ids': created_ids,  # ✅ Return server-generated UUIDs for new goals
                'updated_ids': updated_ids,  # ✅ Return IDs of updated goals
                'errors': errors
            }
            
            logger.info(f"[DONE] BATCH_SYNC COMPLETE: created={created_count}, updated={updated_count}, errors={len(errors)}")
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f"[FATAL] Fatal error in batch_sync: {str(e)}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=False, methods=['post'])
    def batch_delete(self, request):
        """Batch delete (soft-delete) goals.
        
        Request format:
        POST /api/goals/batch_delete/
        {
            'goal_ids': ['id1', 'id2', ...],
            'profile_id': 'uuid'  # Optional, for validation
        }
        
        Response:
        {
            'success': True,
            'soft_deleted': N,
            'already_deleted': M,
            'failed': L,
            'errors': [...]
        }
        
        ✅ Uses SOFT DELETE: Sets is_deleted=True, deleted_at=now()
        ✅ Data is preserved for audit trail
        ✅ GET queries automatically exclude soft-deleted
        ✅ Can be synced to frontend as deletion signal
        """
        import logging
        from django.utils import timezone
        
        logger = logging.getLogger('goals')
        logger.info("========== GOALS BATCH_DELETE (SOFT) ==========")
        
        try:
            # Support both 'goal_ids' and 'ids' parameter names
            goal_ids = request.data.get('goal_ids') or request.data.get('ids', [])
            logger.info(f"[RECV] Received request to delete {len(goal_ids)} goals")
            
            if not goal_ids:
                return Response({
                    'success': False,
                    'error': 'No goal IDs provided (use goal_ids or ids)',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            user_profile = self.request.user if isinstance(self.request.user, Profile) else self.request.user.profile
            deleted_count = 0
            already_deleted = 0
            errors = []
            failed_ids = []
            now = timezone.now()
            
            for goal_id in goal_ids:
                try:
                    # ✅ SOFT DELETE: Don't actually delete, just mark as deleted
                    goal = Goal.objects.get(id=goal_id, profile=user_profile)
                    
                    if goal.is_deleted:
                        # Already soft-deleted, count separately
                        already_deleted += 1
                        logger.info(f"[INFO] Goal {goal_id} already soft-deleted")
                        continue
                    
                    # Perform soft delete
                    goal.is_deleted = True
                    goal.deleted_at = now
                    goal.save(update_fields=['is_deleted', 'deleted_at', 'updated_at'])
                    
                    deleted_count += 1
                    logger.info(f"[OK] Soft-deleted goal {goal_id} at {now}")
                    
                except Goal.DoesNotExist:
                    logger.error(f"[ERR] Goal {goal_id} not found")
                    failed_ids.append(goal_id)
                    errors.append({
                        'id': goal_id,
                        'error': 'Goal not found'
                    })
                except Exception as e:
                    logger.exception(f"[ERR] Error deleting goal {goal_id}: {str(e)}")
                    failed_ids.append(goal_id)
                    errors.append({
                        'id': goal_id,
                        'error': str(e)
                    })
            
            logger.info(
                f"[DONE] BATCH_DELETE COMPLETE: "
                f"soft_deleted={deleted_count}, "
                f"already_deleted={already_deleted}, "
                f"failed={len(failed_ids)}, "
                f"errors={len(errors)}"
            )
            
            return Response({
                'success': len(failed_ids) == 0,
                'deleted': deleted_count,
                'soft_deleted': deleted_count,  # ← Clarify it's soft delete
                'already_deleted': already_deleted,
                'failed': len(failed_ids),
                'failed_ids': failed_ids,
                'errors': errors
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.exception(f"[FATAL] Fatal error in batch_delete: {str(e)}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
