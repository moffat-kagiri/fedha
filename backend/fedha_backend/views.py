#backend/fedha_backend/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db import connection
from datetime import datetime

@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """Public health check endpoint - no authentication required"""
    health_data = {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0',
    }
    
    # Check database connection
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        health_data['database'] = 'connected'
    except Exception as e:
        health_data['database'] = 'disconnected'
        health_data['database_error'] = str(e)
        health_data['status'] = 'unhealthy'
    
    if health_data['status'] == 'healthy':
        return Response(health_data, status=status.HTTP_200_OK)
    else:
        return Response(health_data, status=status.HTTP_503_SERVICE_UNAVAILABLE)

