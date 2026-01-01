# transactions/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'pending', views.PendingTransactionViewSet, basename='pending-transaction')
router.register(r'', views.TransactionViewSet, basename='transaction')

urlpatterns = [
    path('', include(router.urls)),
]