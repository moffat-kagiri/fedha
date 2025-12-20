# goals/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'', views.GoalViewSet, basename='goal')

urlpatterns = [
    path('', include(router.urls)),
]