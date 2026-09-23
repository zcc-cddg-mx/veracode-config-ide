# Optimización del flujo Veracode

El flujo documentado en [03-flujo-completo.md](03-flujo-completo.md) es funcional pero
completamente manual. Este documento describe cómo reducir la fricción y automatizar
cada etapa del ciclo SAST.

---

## Problema del flujo manual

```
Dev → VS Code Extension → Pipeline Scan local
        │
        ▼ (manual: abrir navegador, subir artefactos)
Dev → Plataforma Veracode → Policy Scan en sandbox
        │
        ▼ (manual: esperar, descargar PDF)
Dev → Jira → adjuntar reporte → CAB
```

**Consecuencias:**
- El ciclo completo depende de la máquina y entorno del desarrollador (VS Code, WSL2, certs, gnome-keyring)
- El scan ocurre al momento del pase, no durante el sprint → bloqueo de último minuto
- Sin visibilidad automática: hay que monitorear manualmente el estado del Policy Scan

---

## Optimización 1 — Scripts para el flujo manual (disponible ahora)

Antes de automatizar, reducir la fricción del flujo actual con los scripts incluidos:

| Script | Qué resuelve |
|---|---|
| `./scripts/verify-setup.sh` | Valida el entorno antes del primer scan — evita errores de variables o dependencias faltantes |
| `./scripts/prepare-artifacts.sh` | Confirma que los artefactos están listos antes de subir al sandbox |
| `./scripts/pipeline-scan.sh [frontend\|backend]` | Lanza el Pipeline Scan desde CLI sin depender de VS Code |
| `./scripts/check-build-status.py [frontend\|backend]` | Monitorea el estado del Policy Scan via API en lugar de recargar el navegador |
| `./scripts/download-report.py [frontend\|backend]` | Descarga el PDF automáticamente cuando el scan termina |

Flujo con scripts:

```bash
./scripts/verify-setup.sh
./scripts/prepare-artifacts.sh
./scripts/pipeline-scan.sh backend        # feedback rápido, local
# ... subir artefactos al sandbox manualmente ...
./scripts/check-build-status.py backend   # monitorear via API
./scripts/download-report.py backend      # descargar PDF cuando termine
```

---

## Optimización 2 — Integración en pipeline CI/CD (largo plazo)

El lugar correcto para el escaneo Veracode es el pipeline de despliegue, no la
máquina del desarrollador.

**Beneficios:**
- Se escanea el mismo artefacto que va a producción — sin derivaciones
- Sin dependencia del entorno local del desarrollador
- El reporte queda ligado al commit SHA y versión exacta
- El scan corre en paralelo al proceso de release → no bloquea el CAB

```
PR mergeado a `desarrollo`
        │
        ▼
Pipeline build (compila artefactos: JS zip / JARs)
        │
        ▼
Pipeline Scan Veracode  ◄── automático, credenciales HMAC como secrets del pipeline
        │
        ├─ findings Very High / High ──► bloquea merge / notifica al equipo
        └─ findings Medium o menos ──► continúa
        │
        ▼
Release aprobado → Policy Scan en sandbox  ◄── automático
        │
        ▼
Reporte oficial disponible antes del CAB (sin intervención manual)
```

**Elementos necesarios para la integración:**

| Item | Detalle |
|---|---|
| Credenciales | `VERACODE_HMAC_CLIENT_ID` / `VERACODE_HMAC_CLIENT_SECRET` como secrets del pipeline |
| Threshold | Very High / High bloquea · Medium solo notifica |
| Sandbox target | Un sandbox por ambiente (`dev`, `uat`, `prod`) o uno por componente |
| Artefactos | Generados en el step de build; rutas como variables del pipeline |
| Plataforma | Confirmar si es Azure DevOps, GitHub Actions u otro |

---

## Optimización 3 — Resolución de findings (ciclo continuo)

La optimización del flujo no reemplaza la resolución de findings — son complementarias.
Un pipeline automatizado sin findings resueltos sigue bloqueando el CAB.

Criterio general para resolver findings:

| Tipo de finding | Acción recomendada |
|---|---|
| Código propio del proyecto | Corregir en el fuente antes del siguiente scan |
| Librería de terceros / framework interno | "Library: Vendor Notified" en la plataforma si el equipo no controla el código |
| Módulos de prueba (no llegan a producción) | "Not Exploitable" con justificación |
| Falsos positivos documentados | "Not Exploitable" con justificación técnica |

Las mitigaciones aprobadas en plataforma persisten en escaneos futuros — no hay que
reaplicarlas en cada ciclo.

> Los findings específicos del caso de prueba están documentados en [05-findings.md](05-findings.md).

---

## Prioridad de implementación

| Prioridad | Acción | Esfuerzo | Estado |
|---|---|---|---|
| 1 | Usar scripts del flujo manual (evitar pasos manuales repetitivos) | Muy bajo | ✅ Disponible |
| 2 | Resolver findings en código propio del proyecto | Bajo–Medio | Pendiente (por proyecto) |
| 3 | Aplicar mitigaciones en plataforma para librerías y falsos positivos | Bajo | Pendiente (por proyecto) |
| 4 | Proponer integración en pipeline al equipo de release | Medio | Pendiente |
| 5 | Pipeline Scan automático en cada PR | Alto | Pendiente |
