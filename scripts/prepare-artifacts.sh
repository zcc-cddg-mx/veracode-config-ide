#!/bin/sh
# Verifica que los artefactos generados por la extensión VS Code están disponibles
# antes de subirlos al sandbox de Veracode para el Policy Scan.
#
# Los artefactos se generan automáticamente en /tmp/tempStaticScanDir/ al ejecutar
# el Pipeline Scan desde la extensión. Ejecutar ese scan antes de correr este script.

SCAN_DIR="/tmp/tempStaticScanDir"
ERRORS=0

echo "Frontend:"
if [ -z "$VERACODE_ARTIFACT_FRONTEND" ]; then
  echo "  ✗ VERACODE_ARTIFACT_FRONTEND no está definida — ver env.example.sh"
  ERRORS=$((ERRORS + 1))
elif ls -lh "$SCAN_DIR/$VERACODE_ARTIFACT_FRONTEND" 2>/dev/null; then
  :
else
  echo "  ✗ FALTA: $VERACODE_ARTIFACT_FRONTEND"
  echo "    Ejecutar Pipeline Scan del frontend en VS Code y volver a intentar."
  ERRORS=$((ERRORS + 1))
fi

# CASO DE PRUEBA: lista de JARs de ov-arizona-backend-ecuador.
# Reemplazar con los artefactos con findings de tu propio proyecto.
# Puedes sobreescribir via: export VERACODE_ARTIFACT_BACKEND_JARS="jar1.jar jar2.jar"
BACKEND_JARS="${VERACODE_ARTIFACT_BACKEND_JARS:-app-head.jar feign-clients-head.jar rest-tests-head.jar}"

echo ""
echo "Backend (JARs con findings — caso de prueba, ajustar según proyecto):"
for jar in $BACKEND_JARS; do
  if ls -lh "$SCAN_DIR/$jar" 2>/dev/null; then
    :
  else
    echo "  ✗ FALTA: $jar"
    echo "    Ejecutar Pipeline Scan del backend en VS Code y volver a intentar."
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "Todos los artefactos disponibles. Listos para subir al sandbox."
  echo "Ver 03-flujo-completo.md — Paso 3."
else
  echo "$ERRORS artefacto(s) faltante(s)."
  exit 1
fi
