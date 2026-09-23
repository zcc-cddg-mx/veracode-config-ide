# Veracode — Variables de entorno
# Agregar al perfil de shell (~/.zshrc, ~/.bashrc, ~/.profile, u otro según el sistema).
# Solicitar los valores a quien administra el acceso Veracode en el proyecto.

# ── Credenciales HMAC (CLI + extensión SAST) ──────────────────────────────────
export VERACODE_HMAC_CLIENT_ID=""
export VERACODE_HMAC_CLIENT_SECRET=""

# ── Credenciales OAuth (login interactivo en la extensión VS Code) ────────────
export VERACODE_OA_CLIENT_ID=""        # prefijo: veraccid_
export VERACODE_OA_CLIENT_SECRET=""    # formato: base64url

# ── CLI ───────────────────────────────────────────────────────────────────────
export VERACODE_CLI=""                 # ej: /home/<usuario>/tools/veracode

# ── Identificadores de la aplicación en la plataforma ────────────────────────
export VERACODE_APP_GUID=""
export VERACODE_SANDBOX_FRONTEND_GUID=""
export VERACODE_SANDBOX_BACKEND_GUID=""

# ── Artefacto frontend ────────────────────────────────────────────────────────
# Nombre del zip generado por la extensión VS Code en /tmp/tempStaticScanDir/
# El nombre lo determina la extensión a partir del nombre del workspace del proyecto.
export VERACODE_ARTIFACT_FRONTEND=""   # ej: veracode-auto-pack-<proyecto>-js.zip

# ── gnome-keyring (requerido por la extensión VS Code en WSL2) ────────────────
if [ -S "/run/user/$(id -u)/keyring/control" ]; then
  export GNOME_KEYRING_CONTROL="/run/user/$(id -u)/keyring"
else
  eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
  export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi
