from .base import *
import os, dj_database_url

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
            'level': os.getenv('DJANGO_LOG_LEVEL', 'INFO'),
        },
    },
}

# 旧 django_heroku.settings(locals()) が行っていた設定を明示的に書いたもの
# （django-heroku は保守終了で、Django 5.1 で廃止された STATICFILES_STORAGE を使うため外した）。
if 'DATABASE_URL' in os.environ:
    DATABASES = {
        'default': dj_database_url.config(conn_max_age=600, ssl_require=True),
    }

STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
MIDDLEWARE = ['whitenoise.middleware.WhiteNoiseMiddleware', *MIDDLEWARE]
STORAGES = {
    'default': {'BACKEND': 'django.core.files.storage.FileSystemStorage'},
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}

if 'SECRET_KEY' in os.environ:
    SECRET_KEY = os.environ['SECRET_KEY']

ALLOWED_HOSTS = [h for h in os.environ.get('ALLOWED_HOSTS', '').split(',') if h]

CORS_ALLOWED_ORIGINS = [
    o for o in os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',') if o
]
