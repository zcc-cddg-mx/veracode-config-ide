# Artefactos: qué subir por proyecto

Los artefactos son generados automáticamente por la extensión VS Code en `/tmp/tempStaticScanDir/`
durante el Pipeline Scan (Paso 1 del flujo). No es necesario compilar manualmente.

> **Nota:** los tamaños, conteos de findings y número de artefactos generados corresponden
> a casos de prueba iniciales. Pueden variar según la versión del código y el estado del build.

## Frontend *(caso de prueba: ov-arizona-frontend-ecuador)*

| Artefacto | Tamaño | Findings | Subir? |
|---|---|---|---|
| `$VERACODE_ARTIFACT_FRONTEND` | ~4.5MB | 30 | ✅ Sí |

**Nota:** La extensión empaqueta los fuentes JS directamente (no ejecuta `ng build`).
El warning `NpmPackager build/install failed` es esperado — reducción menor de scope,
no afecta la calidad del escaneo.

## Backend *(caso de prueba: ov-arizona-backend-ecuador)*

La extensión genera 59 artefactos pero solo 3 tienen findings:

| Artefacto | Tamaño | Findings | Subir? |
|---|---|---|---|
| `app-head.jar` | 73.2 MB | 4 | ✅ Sí (obligatorio) |
| `feign-clients-head.jar` | 41.0 KB | 1 | ✅ Sí |
| `rest-tests-head.jar` | 68.8 KB | 1 | ✅ Sí |
| `flyway-head.jar` | 10.7 MB | 0 | Opcional |
| `common-model-head.jar` | 639.1 KB | 0 | Opcional |
| 54 JARs restantes | varios | 0 | No necesario |
| JS zip (no-pm) | 171.4 KB | 0 (falla) | No |
| SQL zip | 250.7 KB | 0 | No |

**Total mínimo para cobertura completa de findings: ~73.3 MB** (los 3 JARs con findings)

## Comportamiento del GradlePackager

La extensión intenta compilar el proyecto con Gradle antes de empaquetar.
Si el build falla en el primer intento, reintenta automáticamente. En el segundo intento
generalmente tiene éxito porque los JARs ya existen en el workspace.

Si los artefactos no están en `/tmp/tempStaticScanDir/`, abrir el proyecto backend en VS Code
y esperar a que la extensión ejecute el scan completo (~90 min en casos de prueba).

## Verificar integridad de artefactos

Para confirmar que los artefactos generados coinciden con el build esperado:

```bash
sha256sum /tmp/tempStaticScanDir/app-head.jar
sha256sum /tmp/tempStaticScanDir/flyway-head.jar
```

Comparar contra los valores de referencia que el equipo registre por build/sprint.
