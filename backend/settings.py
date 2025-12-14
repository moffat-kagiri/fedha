import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-your-secret-key-here'  # Change this in production!

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

# =============================================================================
# HOST CONFIGURATION - Aligned with Flutter ApiConfig
# =============================================================================

ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '192.168.100.6',
    
    # Development hosts (from ApiConfig.development() and ApiConfig.local())
    '192.168.100.6',
    '10.0.2.2',  # Android emulator loopback
    
    # Cloudflare tunnel hosts
    'place-jd-telecom-hi.trycloudflare.com',
    'lake-consistently-affects-applications.trycloudflare.com',
    
    # Production hosts (from ApiConfig.production() and ApiConfig.staging())
    'api.fedha.app',
    'staging-api.fedha.app',
    'staging-backup.fedha.app',
]

# CORS settings aligned with Flutter app
CORS_ALLOW_ALL_ORIGINS = True  # For development - restrict in production
CORS_ALLOW_CREDENTIALS = True

# Specific CORS origins for production (align with Flutter app domains)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://192.168.100.6:3000",  # Local network Flutter web
    "https://fedha.app",  # Production Flutter web
    "https://staging.fedha.app",  # Staging Flutter web
]

CORS_ALLOW_METHODS = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
]

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'x-client-version',
    'x-client-platform',
    'x-environment',
    'x-llm-provider',
]

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'rest_framework',
    'rest_framework.authtoken',
    'api',  # Your app
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'fedha.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'fedha.wsgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# =============================================================================
# SECURITY & PASSWORD VALIDATION
# =============================================================================

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {
            'min_length': 8,
        }
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# =============================================================================
# REST FRAMEWORK CONFIGURATION - Aligned with Flutter Timeouts
# =============================================================================

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
        'rest_framework.parsers.FormParser',
        'rest_framework.parsers.MultiPartParser',
    ],
    'EXCEPTION_HANDLER': 'api.utils.custom_exception_handler',
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/day',
        'user': '1000/day'
    },
    # Timeout settings aligned with Flutter ApiConfig
    'DEFAULT_TIMEOUT': 30,  # Matches Flutter's connectionTimeout
}

# =============================================================================
# API VERSIONING - Aligned with Flutter ApiConfig
# =============================================================================

# API Version (matches Flutter ApiConfig.apiVersion)
API_VERSION = 'v1'

# Base API path
API_BASE_PATH = f'api/{API_VERSION}/'

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs/api.log',
            'formatter': 'verbose',
        },
        'security_file': {
            'level': 'WARNING',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs/security.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': True,
        },
        'api': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': True,
        },
        'api.security': {
            'handlers': ['security_file'],
            'level': 'WARNING',
            'propagate': False,
        },
    },
}

# Ensure logs directory exists
LOG_DIR = BASE_DIR / 'logs'
LOG_DIR.mkdir(exist_ok=True)

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# =============================================================================
# FEDHA APPLICATION SPECIFIC SETTINGS
# =============================================================================

# Security settings for PIN/password handling
FEDHA_PIN_SALT = 'fedha-secure-salt-2025'  # Change in production
FEDHA_PIN_HASH_ITERATIONS = 100000

# UUID Generation Settings
FEDHA_BUSINESS_PREFIX = 'B'
FEDHA_PERSONAL_PREFIX = 'P'

# Temporary PIN Settings
FEDHA_TEMP_PIN_EXPIRY_HOURS = 24

# Profile type configuration
PROFILE_TYPE_MAPPINGS = {
    'business': {
        'code': 'BIZ',
        'label': 'Business',
        'description': 'For business owners, freelancers, and SMEs.',
        'dashboard_url': '/dashboard/business',
    },
    'personal': {
        'code': 'PERS',
        'label': 'Personal',
        'description': 'For personal finance management and budgeting.',
        'dashboard_url': '/dashboard/personal',
    }
}

# Currency and timezone defaults
DEFAULT_SETTINGS = {
    'currency': 'KES',
    'timezone': 'UTC',
    'currencies': ['KES', 'USD', 'EUR', 'GBP', 'JPY']
}

# Response messages for consistent API responses
RESPONSE_MESSAGES = {
    'registration_success': 'Account created successfully',
    'login_success': 'Login successful',
    'profile_not_found': 'Profile not found',
    'invalid_credentials': 'Invalid email or password',
    'missing_fields': 'Missing required fields',
}

# =============================================================================
# ENVIRONMENT DETECTION
# =============================================================================

# Detect environment based on host or environment variable
def get_environment():
    env = os.getenv('FEDHA_ENVIRONMENT', 'development')
    
    # Auto-detect based on ALLOWED_HOSTS if current host is known
    from django.http import HttpRequest
    try:
        request = HttpRequest()
        # This would be set by middleware in a real request
        # For now, use environment variable
        return env
    except:
        return env

CURRENT_ENVIRONMENT = get_environment()

# Environment-specific settings
if CURRENT_ENVIRONMENT == 'production':
    DEBUG = False
    CORS_ALLOW_ALL_ORIGINS = False
    # Production-specific settings
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
elif CURRENT_ENVIRONMENT == 'staging':
    DEBUG = True
    CORS_ALLOW_ALL_ORIGINS = True
elif CURRENT_ENVIRONMENT == 'cloudflare':
    DEBUG = True
    CORS_ALLOW_ALL_ORIGINS = True
else:  # development/local
    DEBUG = True
    CORS_ALLOW_ALL_ORIGINS = True

# =============================================================================
# LLM / AI PARSING CONFIGURATION
# =============================================================================

# Default LLM provider used by backend for SMS parsing and AI features.
LLM_DEFAULT_PROVIDER = 'claude_haiku_4.5'

ALLOWED_LLM_PROVIDERS = [
    'claude_haiku_4.5',
    'openai_gpt_4o',
    'local_fallback'
]

# Feature flags for LLM and AI capabilities
FEATURE_FLAGS = {
    'enable_llm_parsing': True,
    'default_llm_provider': LLM_DEFAULT_PROVIDER,
    'llm_fallback_to_rule_based': True,
    'llm_cache_enabled': True,
    'llm_batch_processing': False,
}

# API Keys and Configuration (load from environment in production)
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')

# LLM Request Timeouts (aligned with Flutter timeouts)
LLM_REQUEST_TIMEOUT_SECONDS = 10
LLM_MAX_RETRIES = 2

# =============================================================================
# EMAIL CONFIGURATION
# =============================================================================

EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'  # Development

# For production, use:
# EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST = 'smtp.your-email-provider.com'
# EMAIL_PORT = 587
# EMAIL_USE_TLS = True
# EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', '')
# EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', '')
# DEFAULT_FROM_EMAIL = 'noreply@fedha.app'

# =============================================================================
# ENCRYPTION SETTINGS
# =============================================================================

MASTER_ENCRYPTION_KEY = os.getenv('MASTER_ENCRYPTION_KEY', '')
ENCRYPTION_KEY_ALGORITHM = 'A256GCM'
ENCRYPTION_KEY_BYTES = 32

# =============================================================================
# HEALTH CHECK CONFIGURATION
# =============================================================================

# Health check endpoint (aligned with Flutter ApiConfig.apiHealthEndpoint)
HEALTH_CHECK_ENDPOINT = 'api/health/'