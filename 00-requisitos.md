# Requisitos: instalación de herramientas

Instalar lo siguiente antes de seguir cualquier otro paso de esta documentación.

---

## 1. VS Code

Descargar e instalar desde [https://code.visualstudio.com](https://code.visualstudio.com).

---

## 2. Extensión Veracode para VS Code

En VS Code abrir el panel de extensiones (`Ctrl+Shift+X`), buscar **Veracode** e instalar
`veracode.veracode-vscode-plugin`. Versión de referencia: **1.16.3**.

O desde la terminal:

```bash
code --install-extension veracode.veracode-vscode-plugin
```

---

## 3. Veracode CLI

El binario se descarga desde la plataforma Veracode (sección *Downloads*) o se solicita
al equipo. Tras descargarlo, dar permisos de ejecución y definir `$VERACODE_CLI` en el
perfil de shell apuntando a la ruta del binario (ver [`env.example.sh`](env.example.sh)).

```bash
chmod +x <ruta-descarga>/veracode
```

---

## 4. Python y librería de autenticación Veracode

Requerido para el script de verificación de estado del Policy Scan
([03-flujo-completo.md](03-flujo-completo.md), Paso 4). Si no se usa ese script, es opcional.

```bash
pip install veracode-api-signing requests
```

---

## 5. gnome-keyring — solo Linux / WSL2

La extensión VS Code lo requiere para almacenar tokens de sesión.

```bash
sudo apt install gnome-keyring
```

El bloque de inicio automático ya está incluido en [`env.example.sh`](env.example.sh).
No es necesario en macOS (usa el Keychain del sistema).

---

## 6. Certificados SSL corporativos

El proxy corporativo intercepta SSL. Sin los certificados, el CLI y la extensión fallan
al conectar con los servicios Veracode.

**Solicitar los archivos `.pem` al equipo de infraestructura/seguridad.**
Ver instrucciones de instalación en [02-configuracion.md](02-configuracion.md).
