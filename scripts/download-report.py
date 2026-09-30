#!/usr/bin/env python3
"""
Descarga el reporte PDF del Policy Scan más reciente desde la plataforma Veracode.

Uso: python3 scripts/download-report.py [frontend|backend|core] [--output archivo.pdf]

Requiere: pip install veracode-api-signing requests
"""

import os
import sys
import argparse
import xml.etree.ElementTree as ET
import requests
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC

SANDBOX_MAP = {
    "frontend": "VERACODE_SANDBOX_FRONTEND_GUID",
    "backend":  "VERACODE_SANDBOX_BACKEND_GUID",
    "core":     "VERACODE_SANDBOX_CORE_GUID",
}

CA_CERT = os.environ.get("SSL_CERT_FILE", True)

def get_env(var):
    val = os.environ.get(var)
    if not val:
        print(f"Error: {var} no está definida en el entorno.")
        sys.exit(1)
    return val

def resolve_numeric_ids(auth, app_guid, sandbox_guid):
    """Convierte GUIDs a IDs numéricos que requiere el XML API v5."""
    r = requests.get(
        f"https://api.veracode.com/appsec/v1/applications/{app_guid}",
        auth=auth, verify=CA_CERT,
    )
    r.raise_for_status()
    app_id = r.json()["id"]

    r2 = requests.get(
        f"https://api.veracode.com/appsec/v1/applications/{app_guid}/sandboxes",
        auth=auth, verify=CA_CERT,
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

def get_build_id(auth, app_id, sandbox_id):
    r = requests.get(
        "https://analysiscenter.veracode.com/api/5.0/getbuildinfo.do",
        params={"app_id": app_id, "sandbox_id": sandbox_id},
        auth=auth,
        verify=CA_CERT,
    )
    r.raise_for_status()
    root = ET.fromstring(r.text)
    build = (
        root.find(".//{https://analysiscenter.veracode.com/schema/4.0/buildinfo}build")
        or root.find(".//build")
    )
    if build is None:
        print("Error: no se encontró información de build.")
        print("¿El Policy Scan está completo? Verificar estado en la plataforma.")
        sys.exit(1)
    return build.attrib["build_id"]

def download_pdf(auth, build_id, output_path):
    r = requests.get(
        "https://analysiscenter.veracode.com/api/5.0/detailedreportpdf.do",
        params={"build_id": build_id},
        auth=auth,
        verify=CA_CERT,
    )
    r.raise_for_status()
    with open(output_path, "wb") as f:
        f.write(r.content)

parser = argparse.ArgumentParser(
    description="Descarga el reporte PDF del Policy Scan desde Veracode."
)
parser.add_argument(
    "target",
    choices=["frontend", "backend", "core"],
    nargs="?",
    default="frontend",
    help="Sandbox a consultar (default: frontend)",
)
parser.add_argument(
    "--output",
    default=None,
    metavar="archivo.pdf",
    help="Nombre del archivo de salida (default: veracode-report-<target>.pdf)",
)
args = parser.parse_args()

output = args.output or f"veracode-report-{args.target}.pdf"

os.environ["VERACODE_API_KEY_ID"]     = get_env("VERACODE_HMAC_CLIENT_ID")
os.environ["VERACODE_API_KEY_SECRET"] = get_env("VERACODE_HMAC_CLIENT_SECRET")

app_guid     = get_env("VERACODE_APP_GUID")
sandbox_guid = get_env(SANDBOX_MAP[args.target])

auth = RequestsAuthPluginVeracodeHMAC()

print(f"→ Resolviendo IDs numéricos para sandbox '{args.target}'...")
app_id, sandbox_id = resolve_numeric_ids(auth, app_guid, sandbox_guid)

print(f"→ Consultando build más reciente...")
build_id = get_build_id(auth, app_id, sandbox_id)
print(f"  build_id: {build_id}")

print(f"→ Descargando reporte PDF...")
download_pdf(auth, build_id, output)
print(f"Reporte guardado: {output}")
