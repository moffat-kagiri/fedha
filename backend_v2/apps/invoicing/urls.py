# apps/invoicing/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'invoicing'

router = DefaultRouter()
router.register('clients', views.ClientViewSet, basename='client')
router.register('invoices', views.InvoiceViewSet, basename='invoice')
router.register('loans', views.LoanViewSet, basename='loan')

urlpatterns = [
    path('', include(router.urls)),
]