from django.http import JsonResponse
from django.utils import timezone
from django.views.decorators.http import require_GET
from django.db import connection

@require_GET
def health_check(request):
    """
    Standard health check endpoint that verifies:
    1. API is accessible (by the fact that this endpoint is responding)
    2. Database connection is working
    3. Returns version and environment information
    """
    # Check database connection
    db_healthy = True
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    except Exception as e:
        db_healthy = False
    
    # Get version and environment from settings
    from django.conf import settings
    
    api_version = getattr(settings, 'API_VERSION', 'v1')
    environment = getattr(settings, 'ENVIRONMENT', 'development')
    
    response_data = {
        "status": "healthy" if db_healthy else "degraded",
        "version": api_version,
        "environment": environment,
        "database": "connected" if db_healthy else "disconnected",
        "timestamp": timezone.now().isoformat()
    }
    
    # If not healthy, return 503 status
    status_code = 200 if db_healthy else 503
    
    return JsonResponse(response_data, status=status_code)
