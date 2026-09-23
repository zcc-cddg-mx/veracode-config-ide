# Veracode — Blueprint de flujo SAST

Blueprint reutilizable del proceso de análisis de seguridad estático (SAST) con Veracode
en VS Code / WSL. Sirve como punto de partida para cualquier equipo que necesite integrar
Veracode en su flujo de desarrollo.

> **Importante — naturaleza del blueprint:**
> Este repositorio documenta un ciclo completo: configuración, escaneo, findings y reporte.
> Los ejemplos concretos (tiempos, findings, artefactos, GUIDs) provienen de casos de prueba
> sobre el proyecto **Oficina Virtual** (`ov-arizona-core`) y son solo referencia —
> los valores reales variarán según proyecto, versión de código y carga de servidores.
>
> **El flujo manual documentado aquí funciona, pero no es sostenible a largo plazo.**
> Se recomienda encarecidamente avanzar hacia la optimización descrita en
> [06-optimizacion.md](06-optimizacion.md): un fix de código, mitigaciones en plataforma
> e integración en el pipeline de release eliminan la intervención manual y garantizan
> reportes limpios antes de cada CAB.

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
- [07-reportes.md](07-reportes.md) — Tipos de reporte PDF, descarga manual y via script, estados de Policy

## Estado del caso de prueba (Oficina Virtual — 2026-09-22)

> Resultados obtenidos sobre `ov-arizona-core`. Tu proyecto tendrá sus propios valores.

| Proyecto | Score | PCI | Acción pendiente |
|---|---|---|---|
| Backend (`ov-arizona-backend-ecuador`) | 98/100 | Did Not Pass | Fix `EncryptionUtils.java` + mitigaciones en plataforma → ver [06-optimizacion.md](06-optimizacion.md) |
| Frontend (`ov-arizona-frontend-ecuador`) | — | Pendiente Policy Scan | Mitigaciones en plataforma (26 falsos positivos CWE-798) |

## Aplicación registrada en Veracode (caso de prueba)

> Reemplaza estos valores con los GUIDs de tu propia aplicación. Ver `env.example.sh`.

| Campo | Valor |
|---|---|
| App | `LATAM_Ecuador_ov-arizona-core` *(caso de prueba)* |
| App GUID | `$VERACODE_APP_GUID` |
| Sandbox Frontend | `ov-arizona-frontend-ecuador` (GUID: `$VERACODE_SANDBOX_FRONTEND_GUID`) |
| Sandbox Backend | `ov-arizona-backend-ecuador` (GUID: `$VERACODE_SANDBOX_BACKEND_GUID`) |
