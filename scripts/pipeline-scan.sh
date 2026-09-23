#!/bin/sh
# Ejecuta el Pipeline Scan via CLI y guarda los resultados en JSON.
# Requiere que los artefactos existan en /tmp/tempStaticScanDir/ (generados por la extensión VS Code).
#
# Uso: ./scripts/pipeline-scan.sh [frontend|backend]

set -e

TARGET="${1:-frontend}"
SCAN_DIR="/tmp/tempStaticScanDir"

if [ -z "$VERACODE_HMAC_CLIENT_ID" ] || [ -z "$VERACODE_HMAC_CLIENT_SECRET" ]; then
  echo "Error: VERACODE_HMAC_CLIENT_ID y VERACODE_HMAC_CLIENT_SECRET deben estar definidas."
  exit 1
fi

if [ -z "$VERACODE_CLI" ] || [ ! -x "$VERACODE_CLI" ]; then
  echo "Error: VERACODE_CLI no definida o no ejecutable."
  exit 1
fi

export VERACODE_API_KEY_ID="$VERACODE_HMAC_CLIENT_ID"
export VERACODE_API_KEY_SECRET="$VERACODE_HMAC_CLIENT_SECRET"

case "$TARGET" in
  frontend)
    if [ -z "$VERACODE_ARTIFACT_FRONTEND" ]; then
      echo "Error: VERACODE_ARTIFACT_FRONTEND no definida."
      exit 1
    fi
    echo "→ Pipeline Scan: frontend ($VERACODE_ARTIFACT_FRONTEND)"
    "$VERACODE_CLI" static scan \
      "$SCAN_DIR/$VERACODE_ARTIFACT_FRONTEND" \
      --results-file veracode-frontend-results.json
    echo "Resultados: veracode-frontend-results.json"
    ;;

  backend)
    # CASO DE PRUEBA: estos JARs corresponden a ov-arizona-backend-ecuador.
    # Reemplazar con los artefactos con findings de tu propio proyecto
    # (identificarlos ejecutando el Pipeline Scan local y revisando el JSON resultante).
    BACKEND_JARS="${VERACODE_ARTIFACT_BACKEND_JARS:-app-head.jar feign-clients-head.jar rest-tests-head.jar}"
    echo "→ Pipeline Scan: backend ($BACKEND_JARS)"
    # shellcheck disable=SC2086
    "$VERACODE_CLI" static scan \
      $(for j in $BACKEND_JARS; do echo "$SCAN_DIR/$j"; done) \
      --results-file veracode-backend-results.json
    echo "Resultados: veracode-backend-results.json"
    ;;

  *)
    echo "Uso: $0 [frontend|backend]"
    exit 1
    ;;
esac
