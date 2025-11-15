import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-your-secret-key-here'  # Change this in production!

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '192.168.100.6',  # Your local network IP (removed port number)
    'place-jd-telecom-hi.trycloudflare.com',  # Cloudflare tunnel domain
]

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',  # Add CORS headers app
    'rest_framework',  # Assuming you're using DRF for your API
    # Add your apps here
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Add CORS middleware first
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

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# CORS Settings
CORS_ALLOW_ALL_ORIGINS = True  # For development - restrict in production
CORS_ALLOW_CREDENTIALS = True
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
    'x-llm-provider',  # NEW: Allow LLM provider header from client
]

FEDHA_PIN_SALT = 'fedha-secure-salt-2025'  # Change in production
FEDHA_PIN_HASH_ITERATIONS = 100000

# UUID Generation Settings
FEDHA_BUSINESS_PREFIX = 'B'
FEDHA_PERSONAL_PREFIX = 'P'

# Temporary PIN Settings
FEDHA_TEMP_PIN_EXPIRY_HOURS = 24

# =============================================================================
# LLM / AI PARSING CONFIGURATION
# =============================================================================

# Default LLM provider used by backend for SMS parsing and AI features.
# Options: 'claude_haiku_4.5', 'openai_gpt_4o', 'local_fallback'
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
    'llm_fallback_to_rule_based': True,  # Fall back to rule-based parsing on LLM failure
    'llm_cache_enabled': True,
    'llm_batch_processing': False,  # Set to True for high-volume deployments
}

# API Keys and Configuration (load from environment in production)
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')

# LLM Request Timeouts
LLM_REQUEST_TIMEOUT_SECONDS = 10
LLM_MAX_RETRIES = 2