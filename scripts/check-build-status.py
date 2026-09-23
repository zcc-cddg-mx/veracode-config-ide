#!/usr/bin/env python3
"""
Consulta el estado del Policy Scan más reciente en la plataforma Veracode.

Uso: python3 scripts/check-build-status.py [frontend|backend]

Requiere: pip install veracode-api-signing requests
"""

import os
import sys
import requests
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC

SANDBOX_MAP = {
    "frontend": "VERACODE_SANDBOX_FRONTEND_GUID",
    "backend":  "VERACODE_SANDBOX_BACKEND_GUID",
}

def get_env(var):
    val = os.environ.get(var)
    if not val:
        print(f"Error: {var} no está definida en el entorno.")
        sys.exit(1)
    return val

target = sys.argv[1] if len(sys.argv) > 1 else "frontend"

if target not in SANDBOX_MAP:
    print(f"Uso: {sys.argv[0]} [frontend|backend]")
    sys.exit(1)

os.environ["VERACODE_API_KEY_ID"]     = get_env("VERACODE_HMAC_CLIENT_ID")
os.environ["VERACODE_API_KEY_SECRET"] = get_env("VERACODE_HMAC_CLIENT_SECRET")

app_guid     = get_env("VERACODE_APP_GUID")
sandbox_guid = get_env(SANDBOX_MAP[target])

auth = RequestsAuthPluginVeracodeHMAC()
response = requests.get(
    "https://analysiscenter.veracode.com/api/5.0/getbuildinfo.do",
    params={"app_id": app_guid, "sandbox_id": sandbox_guid},
    auth=auth,
    verify=os.environ.get("SSL_CERT_FILE", True),
)

print(response.text)
