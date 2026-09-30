#!/bin/sh
# Copia los artefactos de /tmp/tempStaticScanDir/ a un directorio de archivo
# con nombre de proyecto y fecha. Ejecutar justo después de cada Pipeline Scan.
#
# Uso: ./scripts/archive-artifacts.sh <nombre-proyecto> [<filtro>]
#
#   <nombre-proyecto>  Nombre del proyecto (usado como subdirectorio de destino)
#   <filtro>           Patrón de nombre de archivo (grep). Si se omite, copia todo.
#
# Ejemplos:
#   ./scripts/archive-artifacts.sh ov-arizona-restat restat-narayana
#   ./scripts/archive-artifacts.sh ov-arizona-core
#
# Destino: ~/veracode-artifacts/<proyecto>/<fecha>/
#
# Nota: /tmp/tempStaticScanDir/ es acumulativo — la extensión VS Code no lo limpia
# entre proyectos. Sin filtro, el archivo captura todos los artefactos del directorio
# (mezcla de proyectos). Con filtro, solo se copian los archivos que coincidan.

SCAN_DIR="/tmp/tempStaticScanDir"
PROJECT="${1:-}"
FILTER="${2:-}"

if [ -z "$PROJECT" ]; then
  echo "Uso: $0 <nombre-proyecto> [<filtro>]"
  echo "Ej:  $0 ov-arizona-restat restat-narayana"
  echo "Ej:  $0 ov-arizona-core"
  exit 1
fi

DEST="$HOME/veracode-artifacts/$PROJECT/$(date +%Y-%m-%d)"
mkdir -p "$DEST"

COUNT=0
for f in "$SCAN_DIR"/*; do
  [ -f "$f" ] || continue
  if [ -n "$FILTER" ]; then
    echo "$f" | grep -q "$FILTER" || continue
  fi
  cp "$f" "$DEST/"
  COUNT=$((COUNT + 1))
done

if [ "$COUNT" -eq 0 ]; then
  if [ -n "$FILTER" ]; then
    echo "No se encontraron artefactos que coincidan con el filtro '$FILTER' en $SCAN_DIR"
  else
    echo "No se encontraron artefactos en $SCAN_DIR"
  fi
  exit 1
fi

echo "$COUNT artefacto(s) archivados en: $DEST"
ls -lh "$DEST"
