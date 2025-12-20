"""
URL configuration for fedha_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

# fedha_backend/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['GET'])
def health_check(request):
    """Health check endpoint."""
    return Response({
        'status': 'healthy',
        'app': settings.APP_NAME,
        'version': settings.APP_VERSION,
    })

@api_view(['GET'])
def api_root(request):
    """API root endpoint with available endpoints."""
    return Response({
        'message': f'Welcome to {settings.APP_NAME} API',
        'version': settings.APP_VERSION,
        'endpoints': {
            'health': '/api/health/',
            'auth': {
                'register': '/api/auth/register/',
                'login': '/api/auth/login/',
                'logout': '/api/auth/logout/',
                'refresh': '/api/auth/refresh/',
                'profile': '/api/auth/profile/',
            },
            'transactions': '/api/transactions/',
            'goals': '/api/goals/',
            'budgets': '/api/budgets/',
            'invoicing': '/api/invoicing/',
            'sync': '/api/sync/',
        }
    })

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    
    # API Root and Health
    path('api/', api_root, name='api-root'),
    path('api/health/', health_check, name='health-check'),
    
    # App URLs
    path('api/auth/', include('accounts.urls')),
    path('api/transactions/', include('transactions.urls')),
    path('api/goals/', include('goals.urls')),
    path('api/budgets/', include('budgets.urls')),
    path('api/invoicing/', include('invoicing.urls')),
    path('api/sync/', include('sync.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)