import datetime
from django.conf import settings
from django.utils import timezone
from rest_framework.authentication import TokenAuthentication
from rest_framework.exceptions import AuthenticationFailed

class ExpiringTokenAuthentication(TokenAuthentication):
    def authenticate_credentials(self, key):
        model = self.get_model()
        try:
            token = model.objects.select_related("user").get(key=key)
        except model.DoesNotExist:
            raise AuthenticationFailed("Invalid token.")

        if not token.user.is_active:
            raise AuthenticationFailed("User inactive or deleted.")

        # Check if the token is expired
        expires_in = getattr(settings, "TOKEN_EXPIRED_AFTER_HOURS", 24)
        is_expired = token.created < timezone.now() - datetime.timedelta(
            hours=expires_in
        )

        if is_expired:
            token.delete()
            raise AuthenticationFailed("Token has expired.")

        return (token.user, token)
