# Veracode — Flujo SAST para ov-arizona-core
Configuracion de Veracode en VSCode - WSL

Documentación del proceso de análisis de seguridad estático (SAST) para los proyectos
`ov-arizona-frontend-ecuador` y `ov-arizona-backend-ecuador`.

## Setup inicial

```bash
# 1. Instalar dependencias del sistema
./scripts/install-deps.sh

# 2. Instalar certificados SSL corporativos (solicitar .pem al equipo de infraestructura)
./scripts/install-certs.sh <cert-firewall>.pem <cert-proxy>.pem

# 3. Configurar variables de entorno
#    Copiar env.example.sh al perfil de shell (~/.zshrc, ~/.bashrc, ~/.profile u otro)
#    y completar los valores. Solicitar credenciales y GUIDs al equipo.

# 4. Verificar que el entorno está listo
./scripts/verify-setup.sh
```

## Contenido

- [00-requisitos.md](00-requisitos.md) — Instalación de VS Code, extensión, CLI, Python, gnome-keyring
- [01-conceptos.md](01-conceptos.md) — Pipeline Scan vs Policy Scan, cuándo usar cada uno
- [02-configuracion.md](02-configuracion.md) — Variables de entorno, credenciales, certificados
- [03-flujo-completo.md](03-flujo-completo.md) — Proceso paso a paso para un ciclo CAB/producción
- [04-artefactos.md](04-artefactos.md) — Qué subir por proyecto (frontend/backend), tamaños, ubicaciones
- [05-findings.md](05-findings.md) — Findings conocidos, clasificación y estrategia de mitigación
- [06-optimizacion.md](06-optimizacion.md) — Scripts disponibles, opciones de automatización e integración en pipeline

## Aplicación registrada en Veracode

| Campo | Valor |
|---|---|
| App | `LATAM_Ecuador_ov-arizona-core` |
| App GUID | `$VERACODE_APP_GUID` |
| Sandbox Frontend | `ov-arizona-frontend-ecuador` (GUID: `$VERACODE_SANDBOX_FRONTEND_GUID`) |
| Sandbox Backend | `ov-arizona-backend-ecuador` (GUID: `$VERACODE_SANDBOX_BACKEND_GUID`) |
