#!/bin/sh
# Instala las dependencias del sistema necesarias para el flujo Veracode SAST.
# Ejecutar una vez por máquina/entorno, no por proyecto.

set -e

OS="$(uname -s)"

# ── Extensión VS Code ─────────────────────────────────────────────────────────
if command -v code >/dev/null 2>&1; then
  echo "→ Instalando extensión Veracode para VS Code..."
  code --install-extension veracode.veracode-vscode-plugin
else
  echo "! VS Code no encontrado en PATH."
  echo "  Instalar la extensión manualmente: buscar 'veracode.veracode-vscode-plugin'"
  echo "  en el panel de extensiones (Ctrl+Shift+X)."
fi

# ── Python: librería de autenticación Veracode ────────────────────────────────
echo "→ Instalando librerías Python..."
pip install veracode-api-signing requests

# ── gnome-keyring (solo Linux / WSL2) ─────────────────────────────────────────
if [ "$OS" = "Linux" ]; then
  echo "→ Instalando gnome-keyring..."
  sudo apt install -y gnome-keyring
else
  echo "→ macOS detectado — Keychain del sistema cubre gnome-keyring, no se instala."
fi

echo ""
echo "Dependencias instaladas. Pasos manuales pendientes:"
echo "  1. Descargar el binario Veracode CLI y definir VERACODE_CLI en el perfil de shell."
echo "  2. Ejecutar scripts/install-certs.sh con los archivos .pem corporativos."
echo "  3. Completar las variables en el perfil de shell (ver env.example.sh)."
echo "  4. Ejecutar scripts/verify-setup.sh para confirmar que todo está en orden."
