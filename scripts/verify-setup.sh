#!/bin/sh
# Verifica que el entorno Veracode está correctamente configurado.
# Ejecutar antes del primer scan o para diagnosticar problemas.

ERRORS=0

check_var() {
  if [ -z "$(eval echo \$$1)" ]; then
    echo "  ✗ $1 — no definida"
    ERRORS=$((ERRORS + 1))
  else
    echo "  ✓ $1"
  fi
}

echo "Variables de entorno:"
check_var VERACODE_HMAC_CLIENT_ID
check_var VERACODE_HMAC_CLIENT_SECRET
check_var VERACODE_OA_CLIENT_ID
check_var VERACODE_OA_CLIENT_SECRET
check_var VERACODE_CLI
check_var VERACODE_APP_GUID
check_var VERACODE_SANDBOX_FRONTEND_GUID
check_var VERACODE_SANDBOX_BACKEND_GUID
check_var VERACODE_SSO_URL
check_var VERACODE_ARTIFACT_FRONTEND

echo ""
echo "Herramientas:"

if [ -n "$VERACODE_CLI" ]; then
  if [ -x "$VERACODE_CLI" ]; then
    echo "  ✓ Veracode CLI ($VERACODE_CLI)"
  else
    echo "  ✗ Veracode CLI no ejecutable: $VERACODE_CLI"
    ERRORS=$((ERRORS + 1))
  fi
fi

if command -v python3 >/dev/null 2>&1; then
  echo "  ✓ python3 ($(python3 --version 2>&1))"
else
  echo "  ✗ python3 — no encontrado"
  ERRORS=$((ERRORS + 1))
fi

if python3 -c "import veracode_api_signing" 2>/dev/null; then
  echo "  ✓ veracode-api-signing"
else
  echo "  ✗ veracode-api-signing — instalar con: pip install veracode-api-signing requests"
  ERRORS=$((ERRORS + 1))
fi

if command -v code >/dev/null 2>&1; then
  if code --list-extensions 2>/dev/null | grep -q "veracode.veracode-vscode-plugin"; then
    echo "  ✓ extensión VS Code Veracode"
  else
    echo "  ✗ extensión VS Code Veracode no instalada — ver 00-requisitos.md"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ! VS Code no encontrado en PATH — verificar extensión manualmente"
fi

if [ "$(uname -s)" = "Linux" ]; then
  if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    echo "  ✓ gnome-keyring-daemon"
  else
    echo "  ✗ gnome-keyring-daemon — instalar con: sudo apt install gnome-keyring"
    ERRORS=$((ERRORS + 1))
  fi
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "Entorno listo."
else
  echo "$ERRORS problema(s) encontrado(s). Revisar 00-requisitos.md y 02-configuracion.md."
  exit 1
fi
