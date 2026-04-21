# Reto práctico de datos

## Análisis de Contratos Menores del Ayuntamiento de tu municipio

---

## Municipio: Vilagarcía de Arousa

**Dataset de Contratos Menores — Fuente oficial:**

```
https://sede.vilagarcia.gal/dcsv/C0G6N1Z26P99PL6H
```

---

## Contexto

Desde la entrada en vigo de la Ley de Contratos del Sector Público en 2017, los **contratos menores** se han convertido en una herramienta común para la administración local, permitiendo adjudicaciones rápidas para servicios o suministros de bajo importe.
Los ayuntamientos publican una relación de contratos menores realizados, pero esta información suele estar dispersa y en formatos no estructurados, lo que dificulta su análisis. En ocasiones son ficheros Excel, a veces PDFs, y en otros casos simplemente listados en la web.
Para referencia, los contratos menores se definen como aquellos cuyo importe no supera los 15.000 euros para suministros y servicios, o 40.000 euros para obras.

Estos documentos contienen información relevante sobre:

- Gasto público
- Empresas adjudicatarias
- Áreas municipales
- Tipos de contratos
- Importes y fechas

El objetivo de este reto es construir un **proyecto completo de datos**, desde la extracción de la información hasta su análisis y visualización, utilizando herramientas habituales en proyectos reales.

Fuente de datos: (A determinar por el municipio de cada participante en el programa formativo, se recomienda buscar en la sección de transparencia o contratación pública del sitio web del ayuntamiento).

---

## Objetivo general

Desarrollar una **pipeline de datos end-to-end** que incluya:

1. Extracción automática de los documentos.
2. Transformación y limpieza de los datos.
3. Carga de la información en Snowflake.
4. Modelado y análisis mediante SQL.
5. Visualización y análisis en Power BI.
6. Publicación del proyecto en GitHub.

---

## Alcance temporal

⏱️ **Duración estimada del reto: 5 días**

No se espera perfección, sino demostrar:

- Capacidad de razonamiento y resolución de problemas
- Criterio técnico en la toma de decisiones
- Organización
- Comunicación de resultados

---

## 1️⃣ Extracción de datos (ETL – Extract)

### Requisitos mínimos

- Crear un proceso en **Python** (script o notebook Jupyter) que:
  - Acceda a la página web donde se recoja la infomación. En caso de que no sea posible se puede omitir este paso explicándolo razonadamente.
  - Detecte y descargue automáticamente los documentos disponibles.
  - Evite la descarga duplicada de documentos si el proceso se ejecuta varias veces (idempotencia).

### Consideraciones técnicas

- Se pueden usar librerías como:
  - `requests`, `beautifulsoup`, `selenium`, `scrapy` para la extracción web.
  - Librerías de lectura de PDF (`pdfplumber`, `camelot`, `tabula`, etc.)
  - Librerías de lectura de Excel (`pandas`, `openpyxl`, etc.)
  - Librerías de manejo de archivos (`os`, `pathlib`, etc.)
- Los PDFs, Excel y otros documentos deben guardarse de forma organizada (por fecha, año o identificador).

---

## 2️⃣ Transformación y limpieza (ETL – Transform)

### Objetivo

Convertir la información contenida en los documentos (no estructurada) en **datos tabulares** analizables.

### Campos mínimos esperados (si están disponibles)

- Número de expediente
- Fecha del contrato
- Área o departamento
- Objeto del contrato
- Empresa adjudicataria
- Importe (€)
- Tipo de contrato (obra, servicio, suministro, etc.)

### Requisitos de transformación y limpieza

- Normalización de fechas e importes.
- Manejo de valores nulos o inconsistentes.
- Documentar supuestos y decisiones tomadas durante la limpieza.

📌 *Se valora el criterio y la justificación, no la perfección del dato.*

---

## 3️⃣ Carga de datos en Snowflake (ETL – Load)

### Requisitos de carga

- Cargar los datos en Snowflake mediante `SQL` o `Python`
- Verificar:
  - Número de registros cargados
  - Tipos de datos correctos
  - Ausencia de duplicados evidentes

---

## 4️⃣ Modelado analítico y SQL

### Requisitos de modelado

- Diseñar un modelo mínimo que incluya:
  - Una **tabla de hechos** (`fact_contratos`).
  - Tablas de **dimensiones** si procede (empresa, fecha, área, tipo de contrato, etc.).

- Crear al menos **5 consultas SQL** relevantes y bien documentadas que respondan a las siguientes preguntas:
  - ¿Cuántos contratos se han realizado por año?
  - ¿Cuál es el importe total y el importe medio?
  - ¿Qué empresas concentran mayor volumen de gasto?
  - ¿Qué áreas municipales gastan más?

---

## 5️⃣ Visualización en Power BI

### Requisitos mínimos del informe

- KPIs principales:
  - Número total de contratos
  - Importe total adjudicado
  - Importe medio por contrato
- Visualizaciones:
  - Evolución temporal del gasto
  - Top empresas por importe
  - Distribución por tipo de contrato
  - Gasto por área o departamento
- Uso de segmentación de datos (año, empresa, tipo de contrato).

🎯 El informe debe estar orientado a **usuarios no técnicos**.

---

## 6️⃣ Análisis y conclusiones

Incluir una sección final con:

- Principales hallazgos.
- Patrones relevantes detectados.
- Posibles anomalías (empresas recurrentes, importes cercanos al límite legal, etc.).
- Preguntas abiertas o posibles líneas de mejora.

---

## 7️⃣ Control de versiones y despliegue en GitHub

### Requisitos

- Todo el proyecto debe estar versionado en un **repositorio de GitHub** (público o privado). Si es privado, se debe compartir el acceso con el equipo formativo.
- El repositorio debe incluir:
  - Código de extracción y transformación.
  - Scripts SQL.
  - Notebooks (si aplica).
  - `.gitignore` adecuado.
  - Un `README.md` claro y estructurado.

### Contenido mínimo del README

- Descripción del proyecto.
- Arquitectura general del pipeline.
- Tecnologías utilizadas.
- Estructura del repositorio.
- Pasos para ejecutar el proyecto desde cero.
- Supuestos y limitaciones.

### Buenas prácticas valoradas

- Commits frecuentes y descriptivos.
- Estructura clara de carpetas, por ejemplo:

  ```text
  ├── data/
  │   ├── raw/
  │   └── processed/
  ├── notebooks/
  ├── src/
  ├── sql/
  ├── powerbi/
  └── README.md
  