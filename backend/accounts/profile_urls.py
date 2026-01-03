# backend/accounts/profile_urls.py

from django.urls import path
from .views import ProfileView

app_name = 'profile'

urlpatterns = [
    # Profile endpoint - REQUIRES AUTH
    path('', ProfileView.as_view(), name='profile-detail'),
]