# Middleware for adding CORS headers to health endpoint responses
from django.utils.deprecation import MiddlewareMixin

class CorsMiddleware(MiddlewareMixin):
    def process_response(self, request, response):
        # Check if the request is for the health endpoint
        if request.path.endswith('/api/health/'):
            response["Access-Control-Allow-Origin"] = "*"  # Allow all origins for health endpoint
            response["Access-Control-Allow-Methods"] = "GET, OPTIONS"
            response["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        return response
