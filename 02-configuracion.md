# Configuración: WSL2, credenciales y herramientas

## Setup inicial

Agregar el contenido de [`env.example.sh`](env.example.sh) al perfil de shell
(`~/.zshrc`, `~/.bashrc`, `~/.profile` u otro) y completar todos los valores.
El archivo contiene las variables, el bloque de gnome-keyring y comentarios de referencia.

## Credenciales

Dos juegos en el perfil de shell:

| Variable | Tipo | Uso |
|---|---|---|
| `VERACODE_HMAC_CLIENT_ID` | HMAC hex | CLI + extensión SAST |
| `VERACODE_HMAC_CLIENT_SECRET` | HMAC hex | CLI + extensión SAST |
| `VERACODE_OA_CLIENT_ID` | OAuth (`veraccid_` prefix) | Login interactivo extensión |
| `VERACODE_OA_CLIENT_SECRET` | OAuth base64url | Login interactivo extensión |
| `VERACODE_CLI` | path absoluto | Ruta al binario CLI (v2.52.1) |
| `VERACODE_APP_GUID` | UUID | GUID de la app en la plataforma |
| `VERACODE_SANDBOX_FRONTEND_GUID` | UUID | GUID del sandbox frontend |
| `VERACODE_SANDBOX_BACKEND_GUID` | UUID | GUID del sandbox backend |
| `VERACODE_ARTIFACT_FRONTEND` | nombre de archivo | Zip JS generado por la extensión en `/tmp/tempStaticScanDir/` |

El archivo `~/.veracode/credentials` replica las credenciales HMAC con claves
`veracode_api_key_id` / `veracode_api_key_secret` (permisos 600).

## CLI

- **Versión:** v2.52.1
- **Ruta:** definida en el perfil de shell como `$VERACODE_CLI`
- **Auth para Pipeline Scan:**

```bash
VERACODE_API_KEY_ID=$VERACODE_HMAC_CLIENT_ID \
VERACODE_API_KEY_SECRET=$VERACODE_HMAC_CLIENT_SECRET \
$VERACODE_CLI static scan <artefacto> \
  --results-file resultados.json
```

## Extensión VS Code

- **ID:** `veracode.veracode-vscode-plugin 1.16.3`
- **Canal de output SAST:** "Language Client" (Output panel)
- **Canal de output SCA:** "vscode-scan" (falla — bug libsecret WSL2)
- **Login:** SSO Okta EMEA → `https://zurich.okta-emea.com/app/zurich_veracodenew_1/exkehngen7CzyaU9p0i7/sso/saml`

## Limitación conocida: SCA en WSL2

El agente SCA (`srcclr`) llama a `secret_password_store_sync()` con schema NULL —
bug de srcclr con libsecret 0.20+. Sin fix desde el lado del usuario.

**Impacto:** Solo afecta SCA (análisis de dependencias). El SAST funciona normalmente.

## Certificados SSL corporativos

El proxy corporativo intercepta SSL. Sin los certificados instalados, VS Code y el CLI
fallan con errores de SSL al conectar a los servicios de Veracode.

**Solicitar los archivos `.pem` / `.crt` al equipo de infraestructura o seguridad.**

Una vez obtenidos, instalar en el CA store del sistema:

```bash
# Linux / WSL2
sudo cp <cert-firewall>.pem /usr/local/share/ca-certificates/zurich-firewall-root.crt
sudo cp <cert-proxy>.pem    /usr/local/share/ca-certificates/zurich-ssldecrypt-latam.crt
sudo update-ca-certificates

# macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain <cert-firewall>.pem
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain <cert-proxy>.pem
```

No repetir salvo reinstalación del sistema — los certs persisten en el CA store.

## gnome-keyring (requerido por la extensión)

El perfil de shell inicia gnome-keyring automáticamente si no está corriendo:

```sh
if [ -S "/run/user/$(id -u)/keyring/control" ]; then
  export GNOME_KEYRING_CONTROL="/run/user/$(id -u)/keyring"
else
  eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
  export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi
```
