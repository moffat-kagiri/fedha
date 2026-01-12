# apps/transactions/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'transactions'

router = DefaultRouter()
router.register('', views.TransactionViewSet, basename='transaction')
router.register('categories', views.CategoryViewSet, basename='category')
router.register('candidates', views.TransactionCandidateViewSet, basename='candidate')

urlpatterns = [
    path('', include(router.urls)),
]