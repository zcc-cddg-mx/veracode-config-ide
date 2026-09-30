#!/usr/bin/env python3
"""
Lista los sandboxes de la aplicación Veracode y sus GUIDs.

Uso: python3 scripts/list-sandboxes.py

Requiere: pip install veracode-api-signing requests
"""

import os
import sys
import requests
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC

def get_env(var):
    val = os.environ.get(var)
    if not val:
        print(f"Error: {var} no está definida en el entorno.")
        sys.exit(1)
    return val

os.environ["VERACODE_API_KEY_ID"]     = get_env("VERACODE_HMAC_CLIENT_ID")
os.environ["VERACODE_API_KEY_SECRET"] = get_env("VERACODE_HMAC_CLIENT_SECRET")

app_guid = get_env("VERACODE_APP_GUID")
auth     = RequestsAuthPluginVeracodeHMAC()
verify   = os.environ.get("SSL_CERT_FILE", True)

r = requests.get(
    f"https://api.veracode.com/appsec/v1/applications/{app_guid}/sandboxes",
    auth=auth,
    verify=verify,
)
r.raise_for_status()
data = r.json()

sandboxes = data.get("_embedded", {}).get("sandboxes", [])

if not sandboxes:
    print("No se encontraron sandboxes para esta aplicación.")
    sys.exit(0)

print(f"{'Nombre':<45} {'GUID'}")
print("-" * 90)
for sb in sandboxes:
    name = sb.get("name", "—")
    guid = sb.get("guid", "—")
    print(f"{name:<45} {guid}")
