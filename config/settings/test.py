"""テスト実行用設定。高速な in-memory SQLite を利用する。"""
from .base import *  # noqa: F401,F403

DEBUG = False
ALLOWED_HOSTS = ['*']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

PASSWORD_HASHERS = ['django.contrib.auth.hashers.MD5PasswordHasher']

TEMPLATES[0]['OPTIONS']['debug'] = False  # noqa: F405

LANGUAGE_CODE = 'en-us'
USE_I18N = False
USE_L10N = False
