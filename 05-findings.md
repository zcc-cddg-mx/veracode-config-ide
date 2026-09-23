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
