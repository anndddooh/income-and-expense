from .base import *
import os, django_heroku

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

# Honor the 'X-Forwarded-Proto' header for request.is_secure()
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': os.getenv('DJANGO_LOG_LEVEL', 'DEBUG'),
        },
    },
}

django_heroku.settings(locals())

ALLOWED_HOSTS = [h for h in os.environ.get('ALLOWED_HOSTS', '').split(',') if h]

CORS_ALLOWED_ORIGINS = [
    o for o in os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',') if o
]
