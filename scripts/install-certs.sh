#!/bin/sh
# Instala certificados SSL corporativos en el CA store del sistema.
# Solicitar los archivos .pem al equipo de infraestructura/seguridad.
#
# Uso: ./scripts/install-certs.sh <cert1.pem> [<cert2.pem> ...]

set -e

if [ "$#" -eq 0 ]; then
  echo "Uso: $0 <cert1.pem> [<cert2.pem> ...]"
  echo ""
  echo "Solicitar los archivos .pem al equipo de infraestructura/seguridad."
  exit 1
fi

OS="$(uname -s)"

for cert in "$@"; do
  if [ ! -f "$cert" ]; then
    echo "Error: archivo no encontrado: $cert"
    exit 1
  fi

  name="$(basename "$cert" .pem).crt"

  if [ "$OS" = "Linux" ]; then
    echo "→ Instalando $cert → /usr/local/share/ca-certificates/$name"
    sudo cp "$cert" "/usr/local/share/ca-certificates/$name"
  elif [ "$OS" = "Darwin" ]; then
    echo "→ Instalando $cert en Keychain del sistema..."
    sudo security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain "$cert"
  else
    echo "Sistema no reconocido: $OS"
    exit 1
  fi
done

if [ "$OS" = "Linux" ]; then
  echo "→ Actualizando CA store..."
  sudo update-ca-certificates
fi

echo "Certificados instalados. No repetir salvo reinstalación del sistema."
