"""WARNING: This file is intended for corporate intranet environments only.

Relax OpenSSL X.509 strict verification for corporate MITM CA certificates.

OpenSSL 3.4+ (Debian 13/trixie) rejects CA certificates missing the
Authority Key Identifier extension.  Older corporate MITM CAs lack this extension.

This patches both ssl.create_default_context and
ssl._create_default_https_context (used by urllib/http.client) to clear
the VERIFY_X509_STRICT flag on every SSL context created at runtime.
"""

import ssl

_original_create_default_context = ssl.create_default_context


def _patched_create_default_context(purpose=ssl.Purpose.SERVER_AUTH, **kwargs):
    ctx = _original_create_default_context(purpose, **kwargs)
    ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT
    return ctx


ssl.create_default_context = _patched_create_default_context
ssl._create_default_https_context = _patched_create_default_context
