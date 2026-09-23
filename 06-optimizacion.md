# Optimización del flujo Veracode

El ciclo actual (Pipeline Scan + Policy Scan manual) tarda medio día mínimo
y requiere intervención manual en la plataforma. Estas son las opciones para optimizarlo.

---

## Flujo ideal — gestión por equipo de release / pipeline

El lugar correcto para el escaneo Veracode es el pipeline de despliegue, no la
máquina del desarrollador. Razones:

- **Consistencia** — se escanea el mismo artefacto que va a producción, no lo que
  tenía el dev en su máquina ese día
- **Sin dependencia del desarrollador** — el flujo actual requiere VS Code, WSL2,
  gnome-keyring, certs instalados... es frágil y no reproducible
- **Trazabilidad automática** — el build del pipeline tiene número de versión,
  commit SHA y fecha; el reporte Veracode queda ligado a ese artefacto exacto
- **No bloquea el CAB de último minuto** — el scan corre en paralelo al proceso
  de release, no como paso adicional que alguien recuerda el día anterior

### Flujo propuesto

```
PR mergeado a `desarrollo`
        │
        ▼
Pipeline build
(compila artefactos: JS zip / JARs)
        │
        ▼
Pipeline Scan Veracode  ◄── automático, ~15-90 min
(credenciales HMAC como secrets del pipeline)
        │
        ├─ findings Very High / High ──► bloquea merge / notifica
        │
        └─ findings Medium o menos ──► continúa
        │
        ▼
Release aprobado → Policy Scan en sandbox  ◄── automático
(Upload & Scan API con app-id + sandbox target)
        │
        ▼
Reporte oficial disponible antes del CAB
(sin intervención manual)
```

### Lo que habría que coordinar con el equipo de release

| Item | Detalle |
|---|---|
| Credenciales | HMAC ID + Secret como secrets del pipeline (no en código) |
| Threshold | Definir qué severidad bloquea (`Very High`, `High`) y qué solo notifica (`Medium`) |
| Sandbox target | Un sandbox por ambiente (`dev`, `uat`, `prod`) o uno por componente |
| Artefactos | Frontend: JS zip. Backend: `app-head.jar` + `feign-clients-head.jar` + `rest-tests-head.jar` |
| Pipeline | Pendiente confirmar si es Azure DevOps o GitHub Actions |

---

## Flujo actual (referencia)

```
Dev → VS Code Extension → Pipeline Scan local (~15-90 min)
        │
        ▼ (manual)
Dev → Navegador Veracode → Subir artefactos al sandbox
        │
        ▼
Policy Scan en plataforma (~2-4 horas)
        │
        ▼
Dev → Descargar PDF → Adjuntar en Jira → CAB
```

**Problema:** todo el ciclo cae sobre el momento del pase a producción porque
el equipo no ejecuta el Pipeline Scan durante el sprint. Resultado: bloqueo de último minuto.

---

## Opción de corto plazo — Script de preparación de artefactos

Mientras no se integra en el pipeline, un script reduce errores manuales
(subir el artefacto equivocado, olvidar un JAR):

```bash
#!/bin/bash
# prepare-veracode-artifacts.sh

SCAN_DIR="/tmp/tempStaticScanDir"

echo "=== Frontend ==="
ls -lh $SCAN_DIR/$VERACODE_ARTIFACT_FRONTEND 2>/dev/null \
  || echo "FALTA: ejecutar scan en VS Code del frontend"

echo "=== Backend (mínimo — solo JARs con findings) ==="
for jar in app-head.jar feign-clients-head.jar rest-tests-head.jar; do
  ls -lh $SCAN_DIR/$jar 2>/dev/null \
    || echo "FALTA: $jar — ejecutar scan en VS Code del backend"
done
```

## Opción de mediano plazo — Mitigaciones permanentes en la plataforma

Para los findings recurrentes que son falsos positivos (CWE-798 en Angular,
findings en librerías NCDC), crear mitigaciones permanentes en la plataforma Veracode.
Una vez aprobadas, no aparecen en futuros reportes como findings abiertos.

**Impacto:** Los próximos reportes del CAB serán más limpios sin trabajo adicional.
Ver detalle en [05-findings.md](05-findings.md).

## Recomendación priorizada

| Prioridad | Acción | Esfuerzo | Impacto |
|---|---|---|---|
| 1 | Mitigaciones permanentes (falsos positivos conocidos) | Bajo | Alto |
| 2 | Script de preparación de artefactos | Bajo | Medio |
| 3 | Proponer al equipo de release integración en pipeline | Medio | Muy alto |
| 4 | Pipeline Scan automático en cada PR | Alto | Muy alto |
