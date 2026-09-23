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
Pipeline Scan Veracode  ◄── automático, ~15-90 min (referencia, casos de prueba)
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
Dev → VS Code Extension → Pipeline Scan local (~15-90 min, ref. casos de prueba)
        │
        ▼ (manual)
Dev → Navegador Veracode → Subir artefactos al sandbox
        │
        ▼
Policy Scan en plataforma (~2-4 horas, ref. casos de prueba)
        │
        ▼
Dev → Descargar PDF → Adjuntar en Jira → CAB
```

**Problema:** todo el ciclo cae sobre el momento del pase a producción porque
el equipo no ejecuta el Pipeline Scan durante el sprint. Resultado: bloqueo de último minuto.

---

## Opción de corto plazo — Scripts disponibles

Mientras no se integra en el pipeline, los siguientes scripts cubren el flujo manual:

| Script | Cuándo usarlo |
|---|---|
| `./scripts/verify-setup.sh` | Antes del primer scan — confirma entorno y variables |
| `./scripts/prepare-artifacts.sh` | Antes de subir al sandbox — verifica artefactos disponibles |
| `./scripts/pipeline-scan.sh [frontend\|backend]` | Para obtener JSON de findings localmente |
| `./scripts/check-build-status.py [frontend\|backend]` | Para monitorear el Policy Scan via API |

Ver el directorio [`scripts/`](scripts/) para el detalle de cada uno.

## Opción de mediano plazo — Mitigaciones permanentes en la plataforma

Para los findings recurrentes que son falsos positivos (CWE-798 en Angular,
findings en librerías NCDC), crear mitigaciones permanentes en la plataforma Veracode.
Una vez aprobadas, no aparecen en futuros reportes como findings abiertos.

**Impacto:** Los próximos reportes del CAB serán más limpios sin trabajo adicional.
Ver detalle en [05-findings.md](05-findings.md).

## Recomendación priorizada

| Prioridad | Acción | Esfuerzo | Estado |
|---|---|---|---|
| 1 | Mitigaciones permanentes (falsos positivos conocidos) | Bajo | Pendiente |
| 2 | Scripts de flujo manual (`scripts/`) | Bajo | ✅ Disponible |
| 3 | Proponer al equipo de release integración en pipeline | Medio | Pendiente |
| 4 | Pipeline Scan automático en cada PR | Alto | Pendiente |
