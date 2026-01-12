# apps/budgets/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'budgets'

router = DefaultRouter()
router.register('', views.BudgetViewSet, basename='budget')

urlpatterns = [
    path('', include(router.urls)),
]