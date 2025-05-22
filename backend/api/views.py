from django.shortcuts import render

# Create your views here.
# backend/api/views.py
from rest_framework import generics, permissions
from .models import Profile
from .serializers import ProfileSerializer

class ProfileListCreateView(generics.ListCreateAPIView):
    queryset = Profile.objects.filter(is_active=True)
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Hash PIN before saving
        pin = self.request.data.get('pin')
        if pin:
            serializer.save(pin_hash=Profile.hash_pin(pin))

class ProfileDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save()