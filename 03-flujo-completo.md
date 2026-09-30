# Flujo completo: ciclo CAB / pase a producción

El ciclo completo desde desarrollo hasta reporte oficial tarda medio día mínimo.
Lo ideal es que los pasos 1-2 ocurran durante el sprint y no al momento del pase.

> **Nota sobre tiempos:** los valores indicados en este documento corresponden a
> casos de prueba iniciales y pueden variar según carga de los servidores Veracode,
> tamaño real de los artefactos y condiciones de red.

## Paso 1 — Pipeline Scan local (VS Code Extension)

**Cuándo:** Durante el desarrollo, antes de hacer PR.

Abrir el proyecto en VS Code → la extensión detecta el workspace y ejecuta automáticamente
el Pipeline Scan al guardar o manualmente desde el panel Veracode.

Los findings aparecen como diagnósticos inline en el editor. Corregir antes de continuar.

**Tiempo de referencia** (casos de prueba):
- Frontend (Angular, ~4.5MB JS): ~15 min
- Backend (Spring Boot, ~73MB JARs): ~60-90 min

**Nota:** Si el scan se congela en "Found 1 scannable module", es normal — está procesando
el artefacto en los servidores. Esperar.

## Paso 1b — Archivar artefactos (inmediatamente después del scan)

**Cuándo:** Justo al terminar el Pipeline Scan, antes de abrir otro proyecto.

`/tmp/tempStaticScanDir/` es **acumulativo** — la extensión nunca lo limpia entre proyectos.
Si se abre un segundo proyecto y se escanea, los artefactos del primero siguen ahí mezclados.
Archivar inmediatamente garantiza una copia limpia asociada al proyecto correcto.

```bash
# Sin filtro — copia todo el contenido de /tmp/tempStaticScanDir/ (snapshot completo)
./scripts/archive-artifacts.sh ov-arizona-restat

# Con filtro — copia solo los artefactos del proyecto (recomendado si hay mezcla)
./scripts/archive-artifacts.sh ov-arizona-restat restat-narayana
```

Destino: `~/veracode-artifacts/<proyecto>/<fecha>/`

Para subir al sandbox en el Paso 3, usar los artefactos del archivo en lugar del `/tmp/`
(más seguro — no depende del estado actual del directorio temporal).

## Paso 2 — Obtener JSON local (opcional, para análisis)

Si se necesita el JSON con los findings para análisis o reporte HTML:

```bash
./scripts/pipeline-scan.sh frontend   # genera veracode-frontend-results.json
./scripts/pipeline-scan.sh backend    # genera veracode-backend-results.json
```

Los artefactos en `/tmp/tempStaticScanDir/` los genera la extensión VS Code automáticamente
durante el paso 1. Están disponibles mientras no se limpie `/tmp/`.
Ver [`scripts/pipeline-scan.sh`](scripts/pipeline-scan.sh).

## Paso 3 — Subir artefactos al sandbox (plataforma Veracode)

**Cuándo:** Una vez, antes del CAB.

1. Ir a [https://analysiscenter.veracode.com](https://analysiscenter.veracode.com)
2. Login via SSO Okta EMEA
3. Navegar a tu aplicación (caso de prueba: `LATAM_Ecuador_ov-arizona-core`) → sandbox correspondiente
4. New Scan → subir artefactos (ver [04-artefactos.md](04-artefactos.md))
5. Iniciar escaneo

## Paso 4 — Esperar Policy Scan

**Tiempo de referencia** (casos de prueba): 2-4 horas.

El estado se puede monitorear en la plataforma o via API:

```bash
python3 scripts/check-build-status.py frontend
python3 scripts/check-build-status.py backend
```

Ver [`scripts/check-build-status.py`](scripts/check-build-status.py).

## Paso 5 — Descargar reporte y adjuntar en Jira

```bash
python3 scripts/download-report.py frontend   # → veracode-report-frontend.pdf
python3 scripts/download-report.py backend    # → veracode-report-backend.pdf
```

O descargar manualmente desde la plataforma: sandbox → build → pestaña **Reports** → **Download PDF**.

Adjuntar el PDF al ticket Jira del CAB técnico. Ver [07-reportes.md](07-reportes.md) para
referencia sobre tipos de reporte y estados de Policy.
