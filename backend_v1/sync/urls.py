# sync/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'queue', views.SyncQueueViewSet, basename='sync-queue')

urlpatterns = [
    path('', include(router.urls)),
    path('bulk/', views.bulk_sync, name='bulk-sync'),
    path('resolve_conflicts/', views.resolve_conflicts, name='resolve-conflicts'),
]