# backend/api/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Auth endpoints
    path('auth/register/', views.register, name='register'),
    path('auth/login/', views.login, name='login'),
    path('auth/logout/', views.logout, name='logout'),
    
    # Profile endpoints
    path('auth/profile/', views.get_profile, name='get_profile'),
    path('auth/profile/update/', views.update_profile, name='update_profile'),
    path('auth/password/change/', views.change_password, name='change_password'),
    
    # Health check
    path('health/', views.health_check, name='health_check'),
]