# Flujo completo: ciclo CAB / pase a producción

El ciclo completo desde desarrollo hasta reporte oficial tarda medio día mínimo.
Lo ideal es que los pasos 1-2 ocurran durante el sprint y no al momento del pase.

## Paso 1 — Pipeline Scan local (VS Code Extension)

**Cuándo:** Durante el desarrollo, antes de hacer PR.

Abrir el proyecto en VS Code → la extensión detecta el workspace y ejecuta automáticamente
el Pipeline Scan al guardar o manualmente desde el panel Veracode.

Los findings aparecen como diagnósticos inline en el editor. Corregir antes de continuar.

**Tiempo estimado:**
- Frontend (Angular, ~4.5MB JS): ~15 min
- Backend (Spring Boot, ~73MB JARs): ~60-90 min

**Nota:** Si el scan se congela en "Found 1 scannable module", es normal — está procesando
el artefacto en los servidores. Esperar.

## Paso 2 — Obtener JSON local (opcional, para análisis)

Si se necesita el JSON con los findings para análisis o reporte HTML:

```bash
# Frontend
VERACODE_API_KEY_ID=$VERACODE_HMAC_CLIENT_ID \
VERACODE_API_KEY_SECRET=$VERACODE_HMAC_CLIENT_SECRET \
$VERACODE_CLI static scan \
  /tmp/tempStaticScanDir/$VERACODE_ARTIFACT_FRONTEND \
  --results-file veracode-frontend-results.json

# Backend (mínimo para cubrir todos los findings)
VERACODE_API_KEY_ID=$VERACODE_HMAC_CLIENT_ID \
VERACODE_API_KEY_SECRET=$VERACODE_HMAC_CLIENT_SECRET \
$VERACODE_CLI static scan \
  /tmp/tempStaticScanDir/app-head.jar \
  /tmp/tempStaticScanDir/feign-clients-head.jar \
  /tmp/tempStaticScanDir/rest-tests-head.jar \
  --results-file veracode-backend-results.json
```

Los artefactos en `/tmp/tempStaticScanDir/` los genera la extensión VS Code automáticamente
durante el paso 1. Están disponibles mientras no se limpie `/tmp/`.

## Paso 3 — Subir artefactos al sandbox (plataforma Veracode)

**Cuándo:** Una vez, antes del CAB.

1. Ir a [https://analysiscenter.veracode.com](https://analysiscenter.veracode.com)
2. Login via SSO Okta EMEA
3. Navegar a: `LATAM_Ecuador_ov-arizona-core` → sandbox correspondiente
4. New Scan → subir artefactos (ver [04-artefactos.md](04-artefactos.md))
5. Iniciar escaneo

## Paso 4 — Esperar Policy Scan

**Tiempo estimado:** 2-4 horas.

El estado se puede monitorear en la plataforma o via API:

```bash
# Verificar estado del build más reciente
python3 -c "
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC
import os, requests
os.environ['VERACODE_API_KEY_ID'] = os.environ['VERACODE_HMAC_CLIENT_ID']
os.environ['VERACODE_API_KEY_SECRET'] = os.environ['VERACODE_HMAC_CLIENT_SECRET']
auth = RequestsAuthPluginVeracodeHMAC()
r = requests.get(
  'https://analysiscenter.veracode.com/api/5.0/getbuildinfo.do',
  params={'app_id': os.environ['VERACODE_APP_GUID'], 'sandbox_id': os.environ['VERACODE_SANDBOX_FRONTEND_GUID']},
  auth=auth, verify='/etc/ssl/certs/ca-certificates.crt'
)
print(r.text)
"
```

## Paso 5 — Descargar reporte y adjuntar en Jira

Una vez completado, descargar el PDF desde la plataforma y adjuntarlo al ticket Jira
correspondiente al CAB técnico.
