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
