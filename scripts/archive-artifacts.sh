#!/bin/sh
# Copia los artefactos de /tmp/tempStaticScanDir/ a un directorio de archivo
# con nombre de proyecto y fecha. Ejecutar justo después de cada Pipeline Scan.
#
# Uso: ./scripts/archive-artifacts.sh <nombre-proyecto>
# Ej:  ./scripts/archive-artifacts.sh ov-arizona-restat
#
# Destino: ~/veracode-artifacts/<proyecto>/<fecha>/

SCAN_DIR="/tmp/tempStaticScanDir"
PROJECT="${1:-}"

if [ -z "$PROJECT" ]; then
  echo "Uso: $0 <nombre-proyecto>"
  echo "Ej:  $0 ov-arizona-restat"
  exit 1
fi

DEST="$HOME/veracode-artifacts/$PROJECT/$(date +%Y-%m-%d)"
mkdir -p "$DEST"

COUNT=0
for f in "$SCAN_DIR"/*; do
  [ -f "$f" ] || continue
  cp "$f" "$DEST/"
  COUNT=$((COUNT + 1))
done

if [ "$COUNT" -eq 0 ]; then
  echo "No se encontraron artefactos en $SCAN_DIR"
  exit 1
fi

echo "$COUNT artefacto(s) archivados en: $DEST"
ls -lh "$DEST"
