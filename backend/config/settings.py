"""
Django settings for VisiMed backend.
"""

import os
import sys
from pathlib import Path

from django.core.exceptions import ImproperlyConfigured

BASE_DIR = Path(__file__).resolve().parent.parent


def _env_bool(name: str, default: bool) -> bool:
    return os.environ.get(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


SECRET_KEY = os.environ.get(
    "DJANGO_SECRET_KEY",
    "django-insecure-dev-only-change-in-production",
)

DEBUG = _env_bool("DJANGO_DEBUG", False)

_TESTING = "test" in sys.argv or "pytest" in sys.modules

# Are we about to serve real traffic (as opposed to a manage.py command / tests)?
_SERVING = any(cmd in sys.argv for cmd in ("runserver", "gunicorn")) or (
    "config.wsgi" in " ".join(sys.argv)
)
if _SERVING and not DEBUG and SECRET_KEY.startswith("django-insecure-"):
    raise ImproperlyConfigured(
        "Refusing to serve with DEBUG=false and the built-in insecure "
        "DJANGO_SECRET_KEY. Set a real DJANGO_SECRET_KEY in the environment."
    )

ALLOWED_HOSTS = [
    h.strip()
    for h in os.environ.get(
        "DJANGO_ALLOWED_HOSTS", "*" if DEBUG else ""
    ).split(",")
    if h.strip()
] or (["*"] if DEBUG else [])

# Hosts allowed to POST (needed for the Django admin / any session auth behind a
# proxy that terminates TLS). Space/comma-separated full origins.
CSRF_TRUSTED_ORIGINS = [
    o.strip()
    for o in os.environ.get("DJANGO_CSRF_TRUSTED_ORIGINS", "").replace(",", " ").split()
    if o.strip()
]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework.authtoken",
    "corsheaders",
    "visimed",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

if os.environ.get("POSTGRES_NAME"):
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.environ["POSTGRES_NAME"],
            "USER": os.environ.get("POSTGRES_USER", ""),
            "PASSWORD": os.environ.get("POSTGRES_PASSWORD", ""),
            "HOST": os.environ.get("POSTGRES_HOST", "localhost"),
            "PORT": os.environ.get("POSTGRES_PORT", "5432"),
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

AUTH_USER_MODEL = "visimed.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "fr-dz"
TIME_ZONE = "Africa/Algiers"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "visimed.authentication.ExpiringTokenAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 100,
    # Brute-force protection. `login` is applied explicitly on the token view;
    # `user`/`anon` are safety nets for everything else.
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.ScopedRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "login": os.environ.get("THROTTLE_LOGIN", "10/min"),
    },
}

# CORS: permissive in DEBUG (keeps tunnel/dev workflows working), locked down
# otherwise. In production set CORS_ALLOWED_ORIGINS to the web app's origin,
# e.g. "https://visimed.netlify.app".
CORS_ALLOW_ALL_ORIGINS = _env_bool("CORS_ALLOW_ALL", DEBUG)
CORS_ALLOWED_ORIGINS = [
    o.strip()
    for o in os.environ.get("CORS_ALLOWED_ORIGINS", "").replace(",", " ").split()
    if o.strip()
]
CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
    "bypass-tunnel-reminder",   # required to bypass localtunnel reminder page
]
# ── Transport security ──────────────────────────────────────────────────────
# Behind a TLS-terminating proxy (Render, Fly, Railway, a tunnel) tell Django
# the original scheme so it knows the request was HTTPS.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
# Redirect HTTP→HTTPS in production; opt out with DJANGO_SECURE_SSL=false for
# environments (local tunnels) that can't terminate TLS.
SECURE_SSL_REDIRECT = _env_bool("DJANGO_SECURE_SSL", not DEBUG)
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_HSTS_SECONDS = 0 if DEBUG else int(os.environ.get("SECURE_HSTS_SECONDS", 2592000))
SECURE_HSTS_INCLUDE_SUBDOMAINS = not DEBUG
SECURE_HSTS_PRELOAD = not DEBUG

TOKEN_EXPIRED_AFTER_HOURS = int(os.environ.get("TOKEN_EXPIRED_AFTER_HOURS", 24))

# ── Demo gap-filling ───────────────────────────────────────────────────────
# When on, the analytics endpoints synthesise *empty* fields (no objective
# set, zero orders/coverage, blank contact info) with deterministic, mutually
# consistent values so a showcase deployment isn't full of "—" / 0. Never
# alters stored rows. Leave OFF for a real dataset. See visimed/mock.py.
DEMO_MOCK = _env_bool("DEMO_MOCK", False)

# ── Test-run overrides ─────────────────────────────────────────────────────
# Keep the suite deterministic: no HTTPS redirect and no rate-limiting.
if _TESTING:
    SECURE_SSL_REDIRECT = False
    SECURE_HSTS_SECONDS = 0
    REST_FRAMEWORK["DEFAULT_THROTTLE_CLASSES"] = []
    REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {}
