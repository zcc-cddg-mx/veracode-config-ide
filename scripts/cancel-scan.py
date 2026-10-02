#!/usr/bin/env python3
"""
Cancela (elimina) el build activo de un sandbox en Veracode.

Uso: python3 scripts/cancel-scan.py [frontend|backend|core|restat]

Requiere: pip install veracode-api-signing requests

Llama a deletebuild.do (XML API v5). Elimina el build en proceso y deja el
sandbox libre para lanzar un scan nuevo. La acción es irreversible.
"""

import os
import sys
import requests
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC

SANDBOX_MAP = {
    "frontend": "VERACODE_SANDBOX_FRONTEND_GUID",
    "backend":  "VERACODE_SANDBOX_BACKEND_GUID",
    "voc":      "VERACODE_SANDBOX_VOC_GUID",
    "core":     "VERACODE_SANDBOX_CORE_GUID",
    "restat":   "VERACODE_SANDBOX_RESTAT_GUID",
}

def get_env(var):
    val = os.environ.get(var, "").strip()
    if not val:
        print(f"Error: {var} no está definida en el entorno.")
        sys.exit(1)
    return val

def resolve_numeric_ids(auth, verify, app_guid, sandbox_guid):
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
        print(f"Error: sandbox GUID {sandbox_guid} no encontrado.")
        sys.exit(1)
    return app_id, sandbox_id

if len(sys.argv) < 2 or sys.argv[1] not in SANDBOX_MAP:
    print(f"Uso: {sys.argv[0]} [frontend|backend|core|restat|voc]")
    sys.exit(1)

target = sys.argv[1]

os.environ["VERACODE_API_KEY_ID"]     = get_env("VERACODE_HMAC_CLIENT_ID")
os.environ["VERACODE_API_KEY_SECRET"] = get_env("VERACODE_HMAC_CLIENT_SECRET")

app_guid     = get_env("VERACODE_APP_GUID")
sandbox_guid = get_env(SANDBOX_MAP[target])
verify       = os.environ.get("SSL_CERT_FILE", True)

auth = RequestsAuthPluginVeracodeHMAC()

print(f"Resolviendo IDs numéricos para sandbox '{target}'...")
app_id, sandbox_id = resolve_numeric_ids(auth, verify, app_guid, sandbox_guid)
print(f"  app_id={app_id}  sandbox_id={sandbox_id}")

# Confirmar antes de eliminar
print(f"\nEsto eliminará el build activo en el sandbox '{target}'.")
print("Esta acción es irreversible. ¿Continuar? [s/N] ", end="", flush=True)
resp = input().strip().lower()
if resp != "s":
    print("Cancelado.")
    sys.exit(0)

r = requests.get(
    "https://analysiscenter.veracode.com/api/5.0/deletebuild.do",
    params={"app_id": app_id, "sandbox_id": sandbox_id},
    auth=auth,
    verify=verify,
)

print(f"\nHTTP {r.status_code}")
print(r.text)

if r.status_code == 200 and "error" not in r.text.lower():
    print("\nBuild eliminado. El sandbox está libre para un nuevo scan.")
else:
    print("\nRevisa la respuesta — puede haber un error.")
