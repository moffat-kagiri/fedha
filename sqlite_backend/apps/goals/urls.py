# apps/goals/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'goals'

router = DefaultRouter()
router.register('', views.GoalViewSet, basename='goal')

urlpatterns = [
    path('', include(router.urls)),
]