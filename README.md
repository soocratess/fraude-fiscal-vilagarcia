# Análisis de contratos menores — Vilagarcía de Arousa

Pipeline de datos end-to-end sobre los contratos menores publicados por el Ayuntamiento de Vilagarcía de Arousa. Parte de un Excel de la sede electrónica y acaba en un informe de Power BI.

## Pipeline

1. **Extracción** (`notebooks/01_extraccion.ipynb`): descarga del Excel desde la sede del ayuntamiento.
2. **Transformación** (`notebooks/02_transformacion.ipynb`): limpieza, validación de NIF/CIF, conversión de importes en formato español a float, filtrado a contratos menores.
3. **Carga** (`notebooks/03_carga_snowflake.ipynb`): carga en Snowflake con un esquema en estrella.
4. **Análisis SQL** (`sql/analisis.sql`): 10 consultas sobre volumen, tipos, fragmentación, NIFs inválidos, etc.
5. **Visualización**: informe en Power BI conectado por DirectQuery/Import a Snowflake.

## Stack

- Python 3.11 (pandas, openpyxl, snowflake-connector-python, python-dotenv)
- Snowflake como warehouse
- Power BI Desktop para el informe

## Estructura

```
.
├── data/
│   ├── raw/           # Excel descargado sin tocar
│   └── processed/     # CSV limpio producido por el notebook 02
├── notebooks/         # los tres notebooks del ETL
├── sql/               # consultas analíticas
└── requirements.txt
```

## Modelo de datos

Esquema en estrella con una tabla de hechos y dos dimensiones:

- `FACT_CONTRATOS` — una fila por contrato con las métricas económicas.
- `DIM_CONTRATISTA` — empresas y autónomos, incluye validación de NIF/CIF.
- `DIM_FECHA` — calendario continuo (un día por fila).

No se crearon dimensiones para `entidad_contratante` (1 único valor) ni para `tipo_contrato` (4 valores sin atributos adicionales): se dejaron como columnas en la fact.

## Decisiones y supuestos

- **Fechas**: la columna `fecha_formalizacion` del Excel está vacía en el 96 % de los registros. Se mantiene como está, pero se genera una columna adicional `fecha` rellena al 100 %: si existe la fecha real se usa esa, si no se genera una fecha aleatoria dentro del año del contrato (semilla fija para reproducibilidad). El año de cada contrato es recuperable porque aparece siempre en el número de referencia.
- **NIF/CIF**: se valida con el algoritmo oficial de la AEAT (checksum). Se distingue entre NIF, NIE y CIF.
- **Contratos mayores**: el Excel mezcla contratos menores y mayores. Se filtran los mayores porque el alcance del proyecto son exclusivamente los menores.
- **Columnas eliminadas**: tras el filtro quedan columnas constantes (`tipo_contratacion`, `tipo_procedimiento`, `sistema_contratacion`, `tramitacion`, `codigo_cpv` con 100 % nulos). Se eliminan por no aportar información.
- **Flag de límite legal**: se marca cada contrato según si está por debajo, cerca (>90 %) o por encima del umbral legal (15.000 € servicios/suministros, 40.000 € obras).

## Limitaciones

- **Sin desglose por área municipal**: el Excel publica un único valor en `entidad_contratante` para todas las filas (todo consta como "Ayuntamiento Vilagarcía de Arousa", sin subdivisión por concejalía o área). Por eso el pipeline no responde la pregunta "qué áreas gastan más" del brief — no hay datos.
- La fecha estimada es sintética. Sirve para visualizaciones temporales, pero no debe usarse para afirmar en qué mes concreto se firmó un contrato que no tiene fecha real.
- El dataset cubre 2021-2023 principalmente; hay pocos contratos de años anteriores.

## Ejecución

1. Crear `.env` en la raíz con las credenciales de Snowflake:
   ```
   SNOWFLAKE_ACCOUNT=...
   SNOWFLAKE_USER=...
   SNOWFLAKE_PASSWORD=...
   SNOWFLAKE_WAREHOUSE=...
   SNOWFLAKE_DATABASE=...
   SNOWFLAKE_SCHEMA=...
   ```
2. Instalar dependencias: `pip install -r requirements.txt`
3. Ejecutar los notebooks en orden: 01 → 02 → 03.
4. Las queries de `sql/analisis.sql` se lanzan desde Snowsight.
5. Conectar Power BI a Snowflake e importar las tres tablas.
