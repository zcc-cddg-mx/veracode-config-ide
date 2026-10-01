# Findings: tipos, clasificación y opciones de mitigación

Este documento describe los tipos de findings que Veracode reporta y las opciones
de mitigación disponibles en la plataforma. Los datos concretos son del caso de prueba
de Oficina Virtual y sirven como referencia de lo que se puede encontrar en un proyecto real.

> **Nota:** los findings documentados corresponden a casos de prueba iniciales (2026-09-22).
> Cada proyecto tendrá sus propios findings según su código, dependencias y configuración.

---

## Tipos de findings por origen

Entender el origen de un finding determina qué acción corresponde:

| Origen | Descripción | Acción en plataforma |
|---|---|---|
| **Código propio** | Archivo fuente del proyecto, editable por el equipo | Corregir en el código fuente |
| **Librería de terceros / framework interno** | Bytecode de una dependencia; el equipo no controla el código | "Library: Vendor Notified" |
| **Módulo de pruebas** | Código que no llega a producción | "Not Exploitable" con justificación |
| **Falso positivo documentado** | Veracode detecta un patrón pero el contexto lo hace seguro | "Not Exploitable" con justificación técnica |

---

## Opciones de mitigación en la plataforma

Las mitigaciones se aplican en [https://analysiscenter.veracode.com](https://analysiscenter.veracode.com)
sobre cada finding individual. Una vez aprobadas, persisten en escaneos futuros.

| Mitigación | Cuándo usarla |
|---|---|
| **Not Exploitable** | El contexto hace que el finding no sea explotable (falso positivo, test code, config pública) |
| **Library: Vendor Notified** | Finding en librería de terceros; el equipo ya notificó al proveedor |
| **Mitigate by Design** | La arquitectura del sistema neutraliza el riesgo a nivel superior |
| **Remediated** | El código fue corregido y el fix está en el siguiente scan |

---

## Referencia del caso de prueba — Frontend *(ov-arizona-frontend-ecuador — 2026-09-22)*

**30 findings Medium**

| CWE | Tipo | Cantidad | Origen | Mitigación aplicable |
|---|---|---|---|---|
| CWE-798 | Hard-coded Credentials | 26 | Public keys de servicios (reCAPTCHA, Maps, GTM) | Not Exploitable — claves públicas por diseño |
| CWE-80 | Basic XSS | 3 | `Node.appendChild` | Not Exploitable si el input está sanitizado por el framework |
| CWE-312 | Cleartext Storage | 1 | Variable de configuración | Revisar si es credencial real o identificador de config |

---

## Referencia del caso de prueba — Backend *(ov-arizona-backend-ecuador — 2026-09-22)*

**Score: 98/100 — PCI Did Not Pass** · 5 findings Medium · 0 High / Very High

| CWE | Tipo | Archivo | Módulo | Origen | Mitigación aplicable |
|---|---|---|---|---|---|
| CWE-117 | Log Injection (CRLF) | `ArizonaLoggerImpl.java` | `app-head.jar` | Librería NCDC (no editable) | Library: Vendor Notified |
| CWE-80 | Basic XSS | `AmsZuulConfig.java` | `app-head.jar` | Librería NCDC (no editable) | Library: Vendor Notified |
| CWE-331 | Insufficient Entropy | `ZipkinConfiguration.java` | `app-head.jar` | Librería NCDC (no editable) | Library: Vendor Notified |
| CWE-331 | Insufficient Entropy | `EncryptionUtils.java` | `feign-clients-head.jar` | Código propio | Corrección en código fuente |
| CWE-331 | Insufficient Entropy | `Motor2ndStep.java` | `rest-tests-head.jar` | Módulo de pruebas | Not Exploitable |

> Las librerías NCDC (`eu.ncdc.*`) son un framework interno. El scanner detecta los findings
> en el bytecode compilado pero no puede mapearlos a código fuente local. El equipo del
> proyecto no puede modificarlas directamente.

---

## Referencia del caso de prueba — Backend base *(ov-arizona-core — 2026-09-30)*

Pipeline Scan sobre el monorepo completo del framework. **~27 findings en 13 módulos.**
CWEs detallados pendientes de revisión en VS Code; tabla se actualizará tras inspección.

| Módulo | Findings | Nota |
|---|---|---|
| `app-2.0.4-core-SNAPSHOT.jar` | 4 | Mismo patrón que `app-head.jar` de Ecuador — probable NCDC |
| `exchange-2.0.4-core-SNAPSHOT.jar` | 7 | Módulo de integración — revisar CWEs en VS Code |
| `restat-narayana-bridge-spring-2.0.4-core-SNAPSHOT.jar` | 3 | Bridge de transacciones distribuidas |
| `migration-2.0.4-core-SNAPSHOT.jar` | 2 | Módulo de migración de datos |
| `cryptography-2.0.4-core-SNAPSHOT.jar` | 2 | Módulo de criptografía — revisar prioridad |
| `print-2.0.4-core-SNAPSHOT.jar` | 2 | Módulo de generación de reportes |
| `core-2.0.4-core-SNAPSHOT.jar` | 1 | JAR principal del framework |
| `recaptchav3-2.0.4-core-SNAPSHOT.jar` | 1 | Integración reCAPTCHA |
| `tracing-2.0.4-core-SNAPSHOT.jar` | 1 | Módulo de trazabilidad |
| `rating-structure-2.0.4-core-SNAPSHOT.jar` | 1 | Estructura de tarifas |
| `text-file-io-2.0.4-core-SNAPSHOT.jar` | 1 | I/O de archivos de texto |
| `restat-tx-node-preselection-2.0.4-core-SNAPSHOT.jar` | 1 | Transacciones distribuidas |
| `jpametamodelgenerator-2.0.4-core-SNAPSHOT.jar` | 1 | Generador JPA |

**Contraste con `ov-arizona-backend-ecuador`:** el módulo `feign-clients` tiene 0 findings en el
framework base — el CWE-331 (`EncryptionUtils.java`) es específico de la rama Ecuador, no del core.

---

## Referencia del caso de prueba — Restat *(ov-arizona-restat — 2026-09-30)*

Pipeline Scan: **71 findings** (4 thin JAR + 64 fat JAR + 3 JS).
**Policy Scan (2026-09-30): Score 97/100 — Conditional Pass — 4 findings.**

> **Nota clave:** el Policy Scan no reportó ninguno de los 64 findings del fat JAR thorntail.
> Veracode filtra automáticamente el código de librerías bundleadas en el análisis de plataforma.
> Solo los 4 findings del código propio aparecen en el reporte oficial.

### Policy Scan — findings del reporte oficial

| Flaw ID | Severidad | CWE | Archivo | Línea | Fix by |
|---|---|---|---|---|---|
| 225 | **High** | CWE-80 Basic XSS | `webapp/index.html` | 186 | 29/11/2026 ⚠️ |
| 224 | Medium | CWE-73 Directory Traversal | `WebappResourceProvider.java` | 29 | 30/09/2027 |
| 227 | Medium | CWE-601 Open Redirect | `webapp/index.html` | 40 | 30/09/2027 |
| 226 | Medium | CWE-601 Open Redirect | `webapp/index.html` | 144 | 30/09/2027 |

**Por qué "Conditional Pass":** el High (CWE-80) está dentro del período de gracia hasta 29/11/2026.
Si no se corrige antes de esa fecha, el estado cambia a "Did Not Pass".

**Módulos analizados:** thin JAR + JS zip (2 de 4 módulos). Los otros 2 son variantes de JS dentro del thin JAR, no entry points separados. El thorntail no fue seleccionado como entry point.

### Pipeline Scan — Fat JAR (`restat-narayana-coordinator-thorntail.jar`)

Pipeline Scan reportó **64 findings** — todos en dependencias runtime bundleadas. No aparecen en el Policy Scan.

| Librería bundleada | Origen |
|---|---|
| `org/wildfly/swarm/*` | WildFly Swarm / Thorntail framework |
| `org/jboss/modules/*` | JBoss Modules |
| `org/yaml/snakeyaml/*` | SnakeYAML |
| `__redirected/*` | JBoss JAXP redirects |

Mitigación en plataforma si se suben al Policy Scan: "Library: Vendor Notified".
