# invoicing/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'clients', views.ClientViewSet, basename='client')
router.register(r'invoices', views.InvoiceViewSet, basename='invoice')
router.register(r'loans', views.LoanViewSet, basename='loan')

urlpatterns = [
    path('', include(router.urls)),
]