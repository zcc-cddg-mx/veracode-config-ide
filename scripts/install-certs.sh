#!/bin/sh
# Instala los certificados SSL corporativos en el CA store del sistema.
# Solicitar los archivos .pem al equipo de infraestructura/seguridad.
#
# Uso: ./scripts/install-certs.sh <cert-firewall>.pem <cert-proxy>.pem

set -e

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <cert-firewall>.pem <cert-proxy>.pem"
  echo ""
  echo "Solicitar los archivos .pem al equipo de infraestructura/seguridad."
  exit 1
fi

CERT_FIREWALL="$1"
CERT_PROXY="$2"

for f in "$CERT_FIREWALL" "$CERT_PROXY"; do
  if [ ! -f "$f" ]; then
    echo "Error: archivo no encontrado: $f"
    exit 1
  fi
done

OS="$(uname -s)"

if [ "$OS" = "Linux" ]; then
  echo "→ Instalando $CERT_FIREWALL → zurich-firewall-root.crt"
  sudo cp "$CERT_FIREWALL" /usr/local/share/ca-certificates/zurich-firewall-root.crt

  echo "→ Instalando $CERT_PROXY → zurich-ssldecrypt-latam.crt"
  sudo cp "$CERT_PROXY" /usr/local/share/ca-certificates/zurich-ssldecrypt-latam.crt

  echo "→ Actualizando CA store..."
  sudo update-ca-certificates

elif [ "$OS" = "Darwin" ]; then
  echo "→ Instalando $CERT_FIREWALL en Keychain del sistema..."
  sudo security add-trusted-cert -d -r trustRoot \
    -k /Library/Keychains/System.keychain "$CERT_FIREWALL"

  echo "→ Instalando $CERT_PROXY en Keychain del sistema..."
  sudo security add-trusted-cert -d -r trustRoot \
    -k /Library/Keychains/System.keychain "$CERT_PROXY"

else
  echo "Sistema no reconocido: $OS"
  exit 1
fi

echo "Certificados instalados. No repetir salvo reinstalación del sistema."
