# backend_v2/config/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('apps.accounts.urls')),
    path('api/transactions/', include('apps.transactions.urls')),
    path('api/budgets/', include('apps.budgets.urls')),
    path('api/goals/', include('apps.goals.urls')),
    path('api/invoicing/', include('apps.invoicing.urls')),
]