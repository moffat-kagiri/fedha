# backend/fedha_backend/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from .views import health_check

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    
    # Health check - NO AUTH REQUIRED
    path('api/health/', health_check, name='health-check'),
    
    # Authentication - NO AUTH REQUIRED
    path('api/auth/', include('accounts.urls')),
    
    # Profile - REQUIRES AUTH
    path('api/profile/', include('accounts.profile_urls')),
    
    # App endpoints - REQUIRE AUTH
    path('api/transactions/', include('transactions.urls')),
    path('api/budgets/', include('budgets.urls')),
    path('api/goals/', include('goals.urls')),
    path('api/invoicing/', include('invoicing.urls')),
    path('api/sync/', include('sync.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
