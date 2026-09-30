#!/usr/bin/env python3
"""
Consulta el estado del Policy Scan más reciente en la plataforma Veracode.

Uso: python3 scripts/check-build-status.py [frontend|backend|core]

Requiere: pip install veracode-api-signing requests
"""

import os
import sys
import requests
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC

SANDBOX_MAP = {
    "frontend": "VERACODE_SANDBOX_FRONTEND_GUID",
    "backend":  "VERACODE_SANDBOX_BACKEND_GUID",
    "core":     "VERACODE_SANDBOX_CORE_GUID",
    "restat":   "VERACODE_SANDBOX_RESTAT_GUID",
}

def get_env(var):
    val = os.environ.get(var)
    if not val:
        print(f"Error: {var} no está definida en el entorno.")
        sys.exit(1)
    return val

def resolve_numeric_ids(auth, verify, app_guid, sandbox_guid):
    """Convierte GUIDs a IDs numéricos que requiere el XML API v5."""
    r = requests.get(
        f"https://api.veracode.com/appsec/v1/applications/{app_guid}",
        auth=auth, verify=verify,
    )
    r.raise_for_status()
    app_id = r.json()["id"]

    r2 = requests.get(
        f"https://api.veracode.com/appsec/v1/applications/{app_guid}/sandboxes",
        auth=auth, verify=verify,
    )
    r2.raise_for_status()
    sandboxes = r2.json().get("_embedded", {}).get("sandboxes", [])
    sandbox_id = next(
        (sb["id"] for sb in sandboxes if sb.get("guid") == sandbox_guid), None
    )
    if not sandbox_id:
        print(f"Error: sandbox GUID {sandbox_guid} no encontrado en la aplicación.")
        sys.exit(1)
    return app_id, sandbox_id

target = sys.argv[1] if len(sys.argv) > 1 else "frontend"

if target not in SANDBOX_MAP:
    print(f"Uso: {sys.argv[0]} [frontend|backend|core|restat]")
    sys.exit(1)

os.environ["VERACODE_API_KEY_ID"]     = get_env("VERACODE_HMAC_CLIENT_ID")
os.environ["VERACODE_API_KEY_SECRET"] = get_env("VERACODE_HMAC_CLIENT_SECRET")

app_guid     = get_env("VERACODE_APP_GUID")
sandbox_guid = get_env(SANDBOX_MAP[target])
verify       = os.environ.get("SSL_CERT_FILE", True)

auth = RequestsAuthPluginVeracodeHMAC()
app_id, sandbox_id = resolve_numeric_ids(auth, verify, app_guid, sandbox_guid)

response = requests.get(
    "https://analysiscenter.veracode.com/api/5.0/getbuildinfo.do",
    params={"app_id": app_id, "sandbox_id": sandbox_id},
    auth=auth,
    verify=verify,
)
print(response.text)
