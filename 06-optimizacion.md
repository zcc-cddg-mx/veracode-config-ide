# Optimización del flujo Veracode

---

## Estado actual (casos de prueba 2026-09-22)

| Proyecto | Score | PCI | Findings abiertos |
|---|---|---|---|
| Frontend | — | Pendiente Policy Scan oficial | 30 Medium (mayoría falsos positivos) |
| Backend | 98/100 | **Did Not Pass** | 5 Medium · 0 High / Very High |

El score de 98/100 indica que el proyecto está muy cerca de pasar. La barrera son
5 findings Medium, de los cuales **solo 1 requiere un cambio de código**.

---

## Plan para pasar PCI — por esfuerzo

### Acción 1 — Corrección de código (1 archivo, alto impacto)

**`EncryptionUtils.java` en `feign-clients-head.jar`** — CWE-331 Insufficient Entropy.

Reemplazar `java.util.Random` por `java.security.SecureRandom`. Es el único finding
en código propio del proyecto. Una vez corregido y re-escaneado, desaparece del reporte.

```java
// Antes
Random random = new Random();

// Después
SecureRandom random = new SecureRandom();
```

### Acción 2 — Mitigaciones en plataforma (sin cambios de código)

Aplicar en [https://analysiscenter.veracode.com](https://analysiscenter.veracode.com)
una vez aprobado el cambio de `EncryptionUtils.java`:

| Finding | Mitigación | Justificación |
|---|---|---|
| CWE-117 `ArizonaLoggerImpl.java` | Library: Vendor Notified | Librería NCDC, no código del proyecto |
| CWE-80 `AmsZuulConfig.java` | Library: Vendor Notified | Librería NCDC, no código del proyecto |
| CWE-331 `ZipkinConfiguration.java` | Library: Vendor Notified | Librería NCDC, no código del proyecto |
| CWE-331 `Motor2ndStep.java` | Not Exploitable | Módulo de pruebas, no llega a producción |
| CWE-798 frontend (26 findings) | Not Exploitable | Public keys por diseño (reCAPTCHA, Maps, GTM) |
| CWE-80 frontend (3 findings) | Not Exploitable | Revisar si el input está sanitizado por DomSanitizer |
| CWE-312 `fnol/app.module.ts` | Not Exploitable | Revisar si `fnolPassword` es credencial real o config |

Una vez aprobadas estas mitigaciones, los findings no aparecen en reportes futuros.

### Resultado esperado tras Acción 1 + Acción 2

- Backend: 0 findings abiertos → PCI **Pass**
- Frontend: 0 findings abiertos → PCI **Pass**

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

**Problema:** todo el ciclo cae sobre el momento del pase a producción.
Resultado: bloqueo de último minuto.

---

## Scripts disponibles para el flujo manual

| Script | Cuándo usarlo |
|---|---|
| `./scripts/verify-setup.sh` | Antes del primer scan — confirma entorno y variables |
| `./scripts/prepare-artifacts.sh` | Antes de subir al sandbox — verifica artefactos disponibles |
| `./scripts/pipeline-scan.sh [frontend\|backend]` | Obtener JSON de findings localmente |
| `./scripts/check-build-status.py [frontend\|backend]` | Monitorear el Policy Scan via API |
| `./scripts/download-report.py [frontend\|backend]` | Descargar el reporte PDF oficial |

---

## Flujo ideal — integración en pipeline (largo plazo)

El lugar correcto para el escaneo Veracode es el pipeline de despliegue, no la
máquina del desarrollador:

- **Consistencia** — se escanea el mismo artefacto que va a producción
- **Sin dependencia del desarrollador** — el flujo actual requiere VS Code, WSL2, gnome-keyring, certs instalados
- **Trazabilidad automática** — el reporte queda ligado al commit SHA y versión exacta
- **No bloquea el CAB de último minuto** — el scan corre en paralelo al proceso de release

```
PR mergeado a `desarrollo`
        │
        ▼
Pipeline build (compila artefactos: JS zip / JARs)
        │
        ▼
Pipeline Scan Veracode  ◄── automático, ~15-90 min (ref. casos de prueba)
(credenciales HMAC como secrets del pipeline)
        │
        ├─ findings Very High / High ──► bloquea merge / notifica
        └─ findings Medium o menos ──► continúa
        │
        ▼
Release aprobado → Policy Scan en sandbox  ◄── automático
        │
        ▼
Reporte oficial disponible antes del CAB (sin intervención manual)
```

### Coordinación necesaria con el equipo de release

| Item | Detalle |
|---|---|
| Credenciales | HMAC ID + Secret como secrets del pipeline (no en código) |
| Threshold | `Very High` / `High` bloquea — `Medium` solo notifica |
| Sandbox target | Un sandbox por ambiente (`dev`, `uat`, `prod`) o uno por componente |
| Artefactos | Frontend: `$VERACODE_ARTIFACT_FRONTEND`. Backend: `app-head.jar` + `feign-clients-head.jar` + `rest-tests-head.jar` |
| Pipeline | Pendiente confirmar si es Azure DevOps o GitHub Actions |

---

## Recomendación priorizada

| Prioridad | Acción | Esfuerzo | Estado |
|---|---|---|---|
| 1 | Fix `EncryptionUtils.java`: `Random` → `SecureRandom` | Muy bajo (1 línea) | **Pendiente** |
| 2 | Mitigaciones permanentes en plataforma (NCDC libs + falsos positivos) | Bajo | **Pendiente** |
| 3 | Proponer integración en pipeline al equipo de release | Medio | Pendiente |
| 4 | Pipeline Scan automático en cada PR | Alto | Pendiente |
| — | Scripts de flujo manual (`scripts/`) | — | ✅ Disponible |
