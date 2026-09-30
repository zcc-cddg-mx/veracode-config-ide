# Artefactos: qué subir al sandbox

Los artefactos son generados automáticamente por la extensión VS Code en `/tmp/tempStaticScanDir/`
durante el Pipeline Scan. No es necesario compilar manualmente.

> **Nota:** los tamaños, conteos y nombres de artefactos corresponden a casos de prueba
> sobre `ov-arizona-core`. Cada proyecto generará sus propios artefactos.

---

## Estrategia de selección

La extensión puede generar desde decenas hasta más de 100 artefactos (JARs, zips). No es necesario subir todos.

**Criterio general:**
1. Ejecutar el Pipeline Scan local (VS Code extension o `scripts/pipeline-scan.sh`)
2. Identificar qué artefactos tienen findings en el resultado JSON
3. Subir solo esos al sandbox — los artefactos sin findings no aportan al Policy Scan

```bash
# Ver qué módulos tienen findings en el resultado local
cat veracode-backend-results.json | python3 -c "
import json,sys
data=json.load(sys.stdin)
for f in data.get('findings',[]): print(f.get('files',{}).get('source_file',{}).get('package',''))
" | sort -u
```

**Comportamiento esperado durante el empaquetado:**

- **JARs vacíos ignorados:** el GradlePackager omite automáticamente los JARs que no contienen class files (`Skipping jar file does not contain any class files`). No requiere acción.
- **Zips JS/Python pueden fallar:** en proyectos Java puro, el auto-pack de JS/Python puede fallar con "No files found for scanning". Es esperado — no interrumpe el scan ni afecta los resultados Java.
- **Scans paralelos del mismo JAR:** la extensión puede lanzar múltiples Pipeline Scans sobre el mismo artefacto (uno por módulo del workspace que lo referencia). Todos deben completar; los resultados son idénticos.

---

## Referencia del caso de prueba — Frontend *(ov-arizona-frontend-ecuador)*

| Artefacto | Tamaño | Findings | Subir? |
|---|---|---|---|
| `$VERACODE_ARTIFACT_FRONTEND` | ~4.5 MB | 30 | ✅ Sí |

La extensión empaqueta los fuentes JS directamente (no ejecuta `ng build`).
El warning `NpmPackager build/install failed` es esperado — reducción menor de scope,
no afecta la calidad del escaneo.

---

## Referencia del caso de prueba — Backend *(ov-arizona-backend-ecuador — 2026-09-22)*

La extensión generó 59 artefactos; solo 3 tenían findings:

| Artefacto | Tamaño | Findings | Subir? |
|---|---|---|---|
| `app-head.jar` | 73.2 MB | 4 | ✅ Sí |
| `feign-clients-head.jar` | 41.0 KB | 1 | ✅ Sí |
| `rest-tests-head.jar` | 68.8 KB | 1 | ✅ Sí |
| Otros 56 JARs | varios | 0 | No necesario |

**Total mínimo subido para cobertura completa: ~73.3 MB**

---

## Referencia del caso de prueba — Backend base *(ov-arizona-core — 2026-09-30)*

Monorepo completo del framework. La extensión generó **136 artefactos**; 13 tenían findings:

| Artefacto | Tamaño | Findings | Subir? |
|---|---|---|---|
| `app-2.0.4-core-SNAPSHOT.jar` | 72.2 MB | 4 | ✅ Sí |
| `exchange-2.0.4-core-SNAPSHOT.jar` | 202.3 KB | 7 | ✅ Sí |
| `restat-narayana-bridge-spring-2.0.4-core-SNAPSHOT.jar` | 68.4 KB | 3 | ✅ Sí |
| `migration-2.0.4-core-SNAPSHOT.jar` | 52.9 KB | 2 | ✅ Sí |
| `cryptography-2.0.4-core-SNAPSHOT.jar` | 42.8 KB | 2 | ✅ Sí |
| `print-2.0.4-core-SNAPSHOT.jar` | 89.3 KB | 2 | ✅ Sí |
| `core-2.0.4-core-SNAPSHOT.jar` | 7.1 KB | 1 | ✅ Sí |
| `recaptchav3-2.0.4-core-SNAPSHOT.jar` | 9.3 KB | 1 | ✅ Sí |
| `tracing-2.0.4-core-SNAPSHOT.jar` | 3.0 KB | 1 | ✅ Sí |
| `rating-structure-2.0.4-core-SNAPSHOT.jar` | 46.5 KB | 1 | ✅ Sí |
| `text-file-io-2.0.4-core-SNAPSHOT.jar` | 36.7 KB | 1 | ✅ Sí |
| `restat-tx-node-preselection-2.0.4-core-SNAPSHOT.jar` | 9.9 KB | 1 | ✅ Sí |
| `jpametamodelgenerator-2.0.4-core-SNAPSHOT.jar` | 55.2 KB | 1 | ✅ Sí |
| Otros 123 JARs | varios | 0 | No necesario |

**Total mínimo subido: ~73.7 MB** (dominado por `app-2.0.4-core-SNAPSHOT.jar`)

> El naming `-2.0.4-core-SNAPSHOT` refleja la versión Gradle del proyecto en ese branch.
> Cada branch o build puede producir un sufijo diferente (ej. `-head`, `-SNAPSHOT`, `-release`).
> La extensión genera el nombre automáticamente — no hardcodear en scripts.

### Prescan en la plataforma — advertencias "Missing Supporting Files"

Al subir solo los 13 JARs con findings (en lugar de los 136 generados), la plataforma muestra
advertencias de tipo `Missing Supporting Files` en el prescan. Esto es **esperado y no bloquea el scan**.

**Resumen del prescan del caso de prueba (2026-09-30):**

| Módulo | Estado prescan | Dependencias faltantes |
|---|---|---|
| `app-2.0.4-core-SNAPSHOT.jar` | ✅ OK | — |
| `restat-tx-node-preselection-2.0.4-core-SNAPSHOT.jar` | ✅ OK | — |
| `tracing-2.0.4-core-SNAPSHOT.jar` | ✅ OK | — |
| `core-2.0.4-core-SNAPSHOT.jar` | ⚠️ No supporting files | — |
| `cryptography-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 17 files | BouncyCastle/PGP (`name.neuhalfen.*`) |
| `exchange-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 5 files | NCDC framework (`eu.ncdc.arizona.core.*`) |
| `jpametamodelgenerator-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 24 files | JBoss Roaster (`org.jboss.forge.roaster.*`) |
| `migration-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 3 files | NCDC framework |
| `print-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 1 file | NCDC multievaluator |
| `rating-structure-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 8 files | NCDC framework |
| `recaptchav3-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 1 file | NCDC utils |
| `restat-narayana-bridge-spring-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 1 file | Narayana (`me.snowdrop.*`) |
| `text-file-io-2.0.4-core-SNAPSHOT.jar` | ⚠️ Missing - 4 files | NCDC framework |

**Por qué ocurre:** los JARs faltantes son dependencias del framework NCDC (`eu.ncdc.arizona.core.*`)
y librerías de terceros que están entre los 123 JARs con 0 findings — no se subieron porque no
aportarían findings adicionales.

**Impacto:** todas las advertencias son `(Optional)` y `has_fatal_errors="false"`. Veracode reduce
el alcance del análisis cross-module (no puede trazar flujos de datos hacia dependencias no subidas),
pero los findings propios de cada módulo se detectan igualmente. Para un primer scan o revisión
de findings propios, este tradeoff es aceptable.

**Si se necesita cobertura completa de data flow:** subir también los JARs del framework NCDC
(los más referenciados: `eu.ncdc.arizona.core.*`), aunque tengan 0 findings propios.

---

## Referencia del caso de prueba — Restat *(ov-arizona-restat — 2026-09-30)*

Proyecto Thorntail (WildFly Swarm). El GradlePackager requirió corregir `gradle-wrapper.properties`
antes del primer scan exitoso (ver nota al pie). Generó **3 artefactos**:

| Artefacto | Tamaño | Findings | Subir? | Nota |
|---|---|---|---|---|
| `restat-narayana-coordinator-0.0.0-SNAPSHOT.jar` | 20.9 KB | **4** | ✅ Sí | Thin JAR — código propio del proyecto |
| `restat-narayana-coordinator-thorntail.jar` | 93.6 MB | **64** | ✅ Sí | Fat JAR — incluye todas las deps runtime |
| `veracode-auto-pack-ov-arizona-restat-js-no-pm.zip` | 2.8 KB | 3 | ✅ Sí | Archivos JS de configuración |

**Total a subir: ~94.5 MB**

**Estrategia de upload — patrón fat JAR (Thorntail/Spring Boot uber):**

El thin JAR contiene los 4 findings del código propio y es el artefacto prioritario.
El fat JAR empaqueta todas las dependencias runtime (WildFly Swarm, JBoss Modules, SnakeYAML)
y produce ~60 findings adicionales de terceros — todos mitigables como "Library: Vendor Notified".
Subir ambos da cobertura completa; subir solo el thin JAR cubre únicamente el código propio.

> **Nota — gradle-wrapper.properties:** el proyecto tenía `distributionUrl=file:///home/ec2-user/tmp/gradle-5.2-bin.zip`
> (ruta hardcodeada a un servidor EC2). Corregir a `https://services.gradle.org/distributions/gradle-5.2-bin.zip`
> (o la URL comentada en el propio archivo) antes de abrir en VS Code.

**"Cannot locate source file" en VS Code:** los ~60 errors de `org/wildfly/swarm/*` y `org/jboss/*`
son esperados para el fat JAR — la extensión no puede mostrar diagnósticos inline para clases
bundleadas sin fuentes locales. Los 4 findings del thin JAR sí muestran diagnósticos correctamente.

---

## Comportamiento del GradlePackager

Si el build falla en el primer intento, la extensión reintenta automáticamente.
En el segundo intento generalmente tiene éxito porque los JARs ya existen en el workspace.

Si los artefactos no aparecen en `/tmp/tempStaticScanDir/`, abrir el proyecto en VS Code
y esperar a que la extensión complete el scan (~90 min en el caso de prueba del backend).

---

## Verificar integridad de artefactos

```bash
sha256sum /tmp/tempStaticScanDir/<artefacto>.jar
```

Comparar contra los valores de referencia que el equipo registre por build/sprint.
