# Reportes PDF Veracode

El reporte PDF es el entregable oficial del Policy Scan. Es el único documento válido
para el CAB técnico y auditorías de seguridad.

> **Nota:** el reporte solo está disponible una vez que el Policy Scan ha finalizado
> (estado `Results Ready` en la plataforma). Ver [03-flujo-completo.md](03-flujo-completo.md) — Paso 4.

---

## Tipos de reporte

| Tipo | Formato | Contenido | Cuándo usarlo |
|---|---|---|---|
| **Detailed Report** | PDF / XML | Findings completos con línea de código, CWE, severidad, mitigaciones | CAB, auditoría, análisis interno |
| **Summary Report** | PDF / XML | Resumen ejecutivo: política, estado Pass/Fail, conteo por severidad | Comunicación a stakeholders |

---

## Descargar desde la plataforma (manual)

1. Ir a [https://analysiscenter.veracode.com](https://analysiscenter.veracode.com)
2. Login via SSO Okta EMEA
3. Navegar a `LATAM_Ecuador_ov-arizona-core` → sandbox correspondiente → build más reciente
4. Pestaña **Reports** → **Download PDF**

---

## Descargar via script (automático)

```bash
python3 scripts/download-report.py frontend   # → veracode-report-frontend.pdf
python3 scripts/download-report.py backend    # → veracode-report-backend.pdf

# Nombre de archivo personalizado
python3 scripts/download-report.py frontend --output cab-2026-10-frontend.pdf
```

Ver [`scripts/download-report.py`](scripts/download-report.py).

---

## Contenido del Detailed Report (referencia para el CAB)

| Sección | Qué revisar |
|---|---|
| **Policy Compliance** | Estado global: `Pass` o `Fail`. Si es `Fail`, el CAB requiere justificación |
| **Findings** | Lista de hallazgos con severidad, CWE, archivo y línea |
| **Mitigations** | Findings mitigados (Not Exploitable, Library: Vendor Notified, etc.) |
| **Sandbox info** | Nombre del sandbox, fecha del scan, versión del build |

---

## Estados de Policy

| Estado | Significado | Acción |
|---|---|---|
| `Pass` | Ningún finding abierto supera el threshold de la política | Adjuntar PDF al ticket Jira → CAB |
| `Fail` | Hay findings que superan el threshold | Revisar [05-findings.md](05-findings.md), aplicar mitigaciones y re-scanear, o justificar en CAB |
| `Results Ready` | Scan completado, reporte disponible | Descargar PDF |
| `Incomplete` / `In Progress` | Scan aún en curso | Esperar y volver a consultar |
