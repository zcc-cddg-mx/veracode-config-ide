# Findings conocidos y estrategia de mitigación

> **Nota:** los findings documentados corresponden a casos de prueba iniciales (2026-09-22).
> Los conteos y archivos afectados pueden cambiar con cada nueva versión del código.

## Frontend *(caso de prueba: ov-arizona-frontend-ecuador — 2026-09-22)*

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

## Backend *(caso de prueba: ov-arizona-backend-ecuador — 2026-09-22)*

**Score: 98/100 — PCI Did Not Pass** · 5 findings Medium · 0 High / Very High

| CWE | Tipo | Archivo | Módulo | Código propio |
|---|---|---|---|---|
| CWE-117 | Log Injection (CRLF) | `ArizonaLoggerImpl.java` | `app-head.jar` (NCDC lib) | No |
| CWE-80 | Basic XSS | `AmsZuulConfig.java` | `app-head.jar` (NCDC lib) | No |
| CWE-331 | Insufficient Entropy | `ZipkinConfiguration.java` | `app-head.jar` (NCDC lib) | No |
| CWE-331 | Insufficient Entropy | `EncryptionUtils.java` | `feign-clients-head.jar` | **Sí** |
| CWE-331 | Insufficient Entropy | `Motor2ndStep.java` | `rest-tests-head.jar` (test) | No (test) |

### Findings en librerías NCDC (4 de 5) — no son código del proyecto

`ArizonaLoggerImpl.java`, `AmsZuulConfig.java` y `ZipkinConfiguration.java` pertenecen
al framework interno `eu.ncdc.*`. El scanner los detecta en el bytecode compilado
pero no puede mapearlos a código fuente local ("Cannot locate source file").

**Mitigación recomendada:** "Library: Vendor Notified" o "Not Exploitable".

### CWE-331 — `EncryptionUtils.java` en `feign-clients-head.jar` — código propio

Único finding en código del proyecto. Uso de `Random` en lugar de `SecureRandom`
para generación de valores que requieren entropía criptográfica.

**Mitigación recomendada:** reemplazar `java.util.Random` por `java.security.SecureRandom`
en `EncryptionUtils.java`. Si el contexto no requiere seguridad criptográfica,
documentar y marcar como "Not Exploitable" con justificación.

### CWE-331 — `Motor2ndStep.java` en `rest-tests-head.jar` — módulo de pruebas

Está en el módulo de tests (`ams-tests`). El código de test no llega a producción.

**Mitigación recomendada:** "Not Exploitable" — aplica solo a entorno de pruebas.
