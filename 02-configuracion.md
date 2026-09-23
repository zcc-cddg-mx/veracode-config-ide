# Configuración: WSL2, credenciales y herramientas

## Setup inicial

Copiar [`env.example.zshrc`](env.example.zshrc) al `~/.zshrc` y completar todos los valores.
El archivo contiene las variables, el bloque de gnome-keyring y comentarios de referencia.

## Credenciales

Dos juegos en `~/.zshrc`:

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
| `VERACODE_SSO_URL` | URL | Endpoint SSO Okta EMEA para login |
| `VERACODE_ARTIFACT_FRONTEND` | nombre de archivo | Zip JS generado por la extensión en `/tmp/tempStaticScanDir/` |

El archivo `~/.veracode/credentials` replica las credenciales HMAC con claves
`veracode_api_key_id` / `veracode_api_key_secret` (permisos 600).

## CLI

- **Versión:** v2.52.1
- **Ruta:** definida en `~/.zshrc` como `$VERACODE_CLI`
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
- **Login:** SSO Okta EMEA → `$VERACODE_SSO_URL`

## Limitación conocida: SCA en WSL2

El agente SCA (`srcclr`) llama a `secret_password_store_sync()` con schema NULL —
bug de srcclr con libsecret 0.20+. Sin fix desde el lado del usuario.

**Impacto:** Solo afecta SCA (análisis de dependencias). El SAST funciona normalmente.

## Certificados SSL corporativos (Zurich LATAM)

El proxy corporativo intercepta SSL en VS Code. Los certs están instalados en el CA store:

```bash
# Ya ejecutado — no repetir salvo reinstalación del sistema
sudo cp ~/dev/claude/certs/firewall_root.pem /usr/local/share/ca-certificates/zurich-firewall-root.crt
sudo cp ~/dev/claude/certs/zurich-ssl-ca.pem /usr/local/share/ca-certificates/zurich-ssldecrypt-latam.crt
sudo update-ca-certificates
```

Certs: `firewall_root.pem` (CN=firewall_root, válido hasta 2039) y
`zurich-ssl-ca.pem` (CN=ssldecrypt.latam.zurich.com, válido hasta 2031).

## gnome-keyring (requerido por la extensión)

El `.zshrc` inicia gnome-keyring automáticamente si no está corriendo:

```zsh
if [ -S "/run/user/$(id -u)/keyring/control" ]; then
  export GNOME_KEYRING_CONTROL="/run/user/$(id -u)/keyring"
else
  eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
  export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi
```
