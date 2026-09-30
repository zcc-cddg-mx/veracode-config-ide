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
echo "Backend Ecuador (JARs con findings — caso de prueba, ajustar según proyecto):"
for jar in $BACKEND_JARS; do
  if ls -lh "$SCAN_DIR/$jar" 2>/dev/null; then
    :
  else
    echo "  ✗ FALTA: $jar"
    echo "    Ejecutar Pipeline Scan del backend en VS Code y volver a intentar."
    ERRORS=$((ERRORS + 1))
  fi
done

# CASO DE PRUEBA: lista de JARs de ov-arizona-core (2026-09-30).
# Reemplazar con los artefactos con findings de tu propio proyecto.
# Puedes sobreescribir via: export VERACODE_ARTIFACT_CORE_JARS="jar1.jar jar2.jar"
CORE_JARS="${VERACODE_ARTIFACT_CORE_JARS:-app-2.0.4-core-SNAPSHOT.jar exchange-2.0.4-core-SNAPSHOT.jar restat-narayana-bridge-spring-2.0.4-core-SNAPSHOT.jar migration-2.0.4-core-SNAPSHOT.jar cryptography-2.0.4-core-SNAPSHOT.jar print-2.0.4-core-SNAPSHOT.jar core-2.0.4-core-SNAPSHOT.jar recaptchav3-2.0.4-core-SNAPSHOT.jar tracing-2.0.4-core-SNAPSHOT.jar rating-structure-2.0.4-core-SNAPSHOT.jar text-file-io-2.0.4-core-SNAPSHOT.jar restat-tx-node-preselection-2.0.4-core-SNAPSHOT.jar jpametamodelgenerator-2.0.4-core-SNAPSHOT.jar}"

echo ""
echo "Backend Core (JARs con findings — caso de prueba, ajustar según proyecto):"
for jar in $CORE_JARS; do
  if ls -lh "$SCAN_DIR/$jar" 2>/dev/null; then
    :
  else
    echo "  ✗ FALTA: $jar"
    echo "    Ejecutar Pipeline Scan del backend en VS Code y volver a intentar."
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
RESTAT_JARS="${VERACODE_ARTIFACT_RESTAT_JARS:-restat-narayana-coordinator-0.0.0-SNAPSHOT.jar restat-narayana-coordinator-thorntail.jar}"

echo ""
echo "Restat (thin + fat JAR — caso de prueba, ajustar según proyecto):"
for jar in $RESTAT_JARS; do
  if ls -lh "$SCAN_DIR/$jar" 2>/dev/null; then
    :
  else
    echo "  ✗ FALTA: $jar"
    echo "    Ejecutar Pipeline Scan del restat en VS Code y volver a intentar."
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
