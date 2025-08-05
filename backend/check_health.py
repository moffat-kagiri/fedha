from django.http import JsonResponse
from django.views.decorators.http import require_GET
from django.utils import timezone

@require_GET
def health_check(request):
    """Simple health check endpoint for testing connectivity."""
    return JsonResponse({
        'status': 'healthy',
        'timestamp': timezone.now().isoformat(),
        'message': 'Fedha API is operational',
        'environment': 'development'
    })
