# Conceptos: Pipeline Scan vs Policy Scan

## Los dos tipos de escaneo

Veracode ofrece dos modalidades de análisis estático con propósitos distintos.

### Pipeline Scan (local)

- Se ejecuta desde la extensión VS Code o el CLI
- **No se registra** en la plataforma Veracode
- Resultados efímeros: se muestran en el editor o en un JSON local, luego se descartan
- Rápido para artefactos pequeños (~15 min para 4.5MB JS), más lento para JARs grandes (~60 min para 73MB)
- Útil durante el desarrollo para corregir findings antes del pase

```
Dev → VS Code Extension → Pipeline Scan API → Diagnósticos inline (no persistidos)
```

### Policy Scan / Sandbox Scan (plataforma)

- Se ejecuta subiendo artefactos al sandbox en la plataforma Veracode
- **Queda registrado**: número de build, fecha, estado de policy, historial
- Genera reporte PDF descargable
- Tarda 2-4 horas (procesamiento en servidores Veracode)
- Es el reporte válido para CAB técnico y auditorías

```
Dev → Subir artefactos al sandbox → Policy Scan → Reporte oficial PDF
```

## Cuándo usar cada uno

| Situación | Pipeline Scan | Policy Scan |
|---|---|---|
| Feedback durante desarrollo | ✅ | ❌ (muy lento) |
| Verificar un fix puntual | ✅ | ❌ |
| CAB técnico / pase a producción | ❌ (no válido) | ✅ |
| Auditoría de seguridad | ❌ | ✅ |
| Generar JSON para análisis local | ✅ (con `--results-file`) | ❌ |

## Por qué la extensión VS Code no registra en la plataforma

La extensión usa exclusivamente el Pipeline Scan API, que es intencionalmente stateless.
Para registrar en la plataforma se necesita el Upload & Scan API con un `app-id` configurado,
que la extensión actual (v1.16.3) no implementa.

Para un ciclo completo se requieren ambos pasos: la extensión para feedback rápido
y la subida manual (o automatizada) al sandbox para el reporte oficial.
