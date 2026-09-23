# Artefactos: qué subir al sandbox

Los artefactos son generados automáticamente por la extensión VS Code en `/tmp/tempStaticScanDir/`
durante el Pipeline Scan. No es necesario compilar manualmente.

> **Nota:** los tamaños, conteos y nombres de artefactos corresponden a casos de prueba
> sobre `ov-arizona-core`. Cada proyecto generará sus propios artefactos.

---

## Estrategia de selección

La extensión puede generar decenas de artefactos (JARs, zips). No es necesario subir todos.

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

---

## Referencia del caso de prueba — Frontend *(ov-arizona-frontend-ecuador)*

| Artefacto | Tamaño | Findings | Subir? |
|---|---|---|---|
| `$VERACODE_ARTIFACT_FRONTEND` | ~4.5 MB | 30 | ✅ Sí |

La extensión empaqueta los fuentes JS directamente (no ejecuta `ng build`).
El warning `NpmPackager build/install failed` es esperado — reducción menor de scope,
no afecta la calidad del escaneo.

---

## Referencia del caso de prueba — Backend *(ov-arizona-backend-ecuador)*

La extensión generó 59 artefactos; solo 3 tenían findings:

| Artefacto | Tamaño | Findings | Subir? |
|---|---|---|---|
| `app-head.jar` | 73.2 MB | 4 | ✅ Sí |
| `feign-clients-head.jar` | 41.0 KB | 1 | ✅ Sí |
| `rest-tests-head.jar` | 68.8 KB | 1 | ✅ Sí |
| Otros 56 JARs | varios | 0 | No necesario |

**Total mínimo subido para cobertura completa: ~73.3 MB**

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
