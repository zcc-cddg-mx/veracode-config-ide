# Findings conocidos y estrategia de mitigación

## Frontend — ov-arizona-frontend-ecuador (2026-09-22)

**30 findings Medium**

### CWE-798: Hard-coded Credentials (26 findings)

**Archivos afectados:** `environment.*.ts` — public keys de servicios externos.

**Análisis:** Falsos positivos en contexto Angular. Las claves detectadas son:
- reCAPTCHA site keys (públicas por diseño, van en el HTML del cliente)
- Google Maps API keys (públicas)
- GTM/GA tracking IDs (públicos)

Las claves secretas reales (`environment.secret.ts`) no están en el repositorio
ni en los artefactos de escaneo — son inyectadas por gulp scripts en tiempo de build.

**Mitigación recomendada en plataforma:** "Not Exploitable" — las claves son públicas
por diseño del servicio (reCAPTCHA, Google Maps requieren que el cliente las conozca).

### CWE-80: Basic XSS — Node.appendChild (3 findings)

**Análisis:** Uso de `Node.appendChild` sin sanitizar. Requiere revisión caso por caso
para confirmar si el contenido insertado proviene de fuentes controladas.

**Mitigación:** Revisar el contexto de cada ocurrencia. Si el input está sanitizado
por Angular's DomSanitizer o es contenido estático, marcar como "Not Exploitable".

### CWE-312: Cleartext Storage (1 finding)

**Archivo:** `fnol/app.module.ts` — variable `fnolPassword`.

**Mitigación:** Revisar si es una contraseña real o un identificador de configuración.

---

## Backend — ov-arizona-backend-ecuador (2026-09-22)

**6 findings Medium** (Pipeline Scan, pendiente confirmar con Policy Scan oficial)

### app-head.jar — 4 findings (en dependencias NCDC)

Los 4 findings están en archivos de librerías internas NCDC que no forman parte
del código fuente del repositorio:

| Archivo fuente | Paquete |
|---|---|
| `AmsZuulConfig.java` | `eu.ncdc.arizona.zuul` |
| `SpringTxBridgeManager.java` | `eu.ncdc.restat.tx` |
| `InboundPropagateFilter.java` | `eu.ncdc.restat.integration.feign` |
| `ZipkinConfiguration.java` | `eu.ncdc.arizona.core.configuration` |
| `ArizonaLoggerImpl.java` | `eu.ncdc.arizona.core.common.utils` |
| `LoggedAspect.java` | `eu.ncdc.arizona.core.security` |
| `CachedBodyHttpServletRequest.java` | `eu.ncdc.arizona.zuul` |

**Análisis:** Son dependencias del framework NCDC, no código editable del proyecto.
El scanner detecta los findings en el bytecode compilado pero no puede mapearlos
a código fuente local ("Cannot locate source file").

**Mitigación recomendada:** "Library: Vendor Notified" o "Not Exploitable" —
los findings están en código de terceros (NCDC) fuera del control del equipo.

### feign-clients-head.jar — 1 finding

Pendiente detalle del Policy Scan oficial.

### rest-tests-head.jar — 1 finding

Está en el módulo de pruebas (`ams-tests`). Considerar si aplica mitigación
"Not Exploitable" para código de test que no llega a producción.
