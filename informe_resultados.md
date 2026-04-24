# Informe de resultados — Contratos menores de Vilagarcía de Arousa

Análisis de la contratación menor publicada por el Ayuntamiento de Vilagarcía de Arousa. Datos extraídos del portal abierto, limpiados con Python y explotados en Snowflake + Power BI. Los importes se expresan con IVA incluido salvo que se indique lo contrario.

## 1. Resumen ejecutivo

El dataset analizado contiene **607 contratos menores** publicados entre 2021 y 2023, con un gasto acumulado de **2,74 M€ (IVA incluido)** y un importe medio por contrato de **4.521 €**. Contratan **334 empresas distintas**, con una concentración moderada (el top 10 acumula el 23,9 % del gasto).

Como señales a revisar destacan:

- **33 contratos (5,4 %) están cerca del límite legal** del contrato menor, por un total de 636.321 € sin IVA. Es un volumen compatible con uso legítimo, pero merece una mirada caso a caso.
- **16 contratos figuran con NIF/CIF inválido** (por checksum incorrecto, longitud anómala o formato desconocido), por un total de 50 k€.
- El dataset está fuertemente concentrado en **2023** (550 de 607 contratos, el 90 %), lo que limita el análisis de tendencia temporal.

## 2. Volumen y distribución

### 2.1 Totales generales

| Métrica | Valor |
|---|---|
| Total de contratos | 607 |
| Gasto total (con IVA) | 2.744.003 € |
| Gasto medio | 4.521 € |
| Gasto mediano | 1.734 € |
| Empresas distintas | 334 |
| Periodo cubierto | 2021 – 2023 |

La distancia entre media (4.521 €) y mediana (1.734 €) indica que la distribución está sesgada por una minoría de contratos grandes que tiran del promedio hacia arriba.

### 2.2 Distribución por tipo de contrato

| Tipo | Contratos | Importe (€) | % del total |
|---|---:|---:|---:|
| Servicios | 301 | 1.168.310 | 42,6 % |
| Obras | 42 | 790.321 | 28,8 % |
| Suministros | 210 | 690.725 | 25,2 % |
| Privado | 54 | 94.647 | 3,4 % |

Servicios y Suministros dominan en **número** de contratos. Obras tiene pocas unidades pero importe medio muy superior, como es esperable.

### 2.3 Distribución por año

| Año | Contratos | Importe (€) |
|---|---:|---:|
| 2021 | 3 | 104.594 |
| 2022 | 54 | 369.934 |
| 2023 | 550 | 2.269.475 |

La concentración en 2023 es casi absoluta. Puede deberse a que el portal abierto del Ayuntamiento empezó a publicar con normalidad a partir de esa fecha, más que a un incremento real del gasto.

## 3. Concentración de proveedores

El top 10 de empresas por importe adjudicado acumula el **23,9 %** del gasto total.

| Empresa | Importe (€) |
|---|---:|
| GALSUR PROYECTOS Y OBRAS S.L.U. | 94.416 |
| MICROASFALT SL | 93.928 |
| Montajes J.M. Iglesias, S.L. | 88.923 |
| PRISCILA T. RETAMOZO RAMOS | 71.300 |
| MOVIMIENTO DE ARIDOS Y CONSTRUCCIONES DE AROSA S.L. | 64.077 |
| MONCOSA OHS, S.A. | 61.883 |
| SCHINDLER S.A. | 48.378 |
| Serviplustotal S.L. | 48.221 |
| REFORMAS TREBOL S.L. | 44.817 |
| ECOPLANIN XESTION E INFORMACION AMBIENTAL S.L. | 41.139 |

No se observa concentración extrema (ninguna empresa supera el 4 % del gasto total), pero sí un patrón reconocible de proveedores recurrentes en obras y servicios técnicos.

## 4. Señales de posible fraude

### 4.1 Contratos cerca del límite legal

Se marcan como "cerca del límite" los contratos cuyo importe supera el 90 % del umbral legal del tipo correspondiente (15.000 € para servicios y suministros, 40.000 € para obras). Superar ese umbral obligaría a licitar por procedimiento abierto, por lo que aproximarse repetidamente al techo es un indicio clásico de **fraccionamiento artificial**.

| | Valor |
|---|---|
| Contratos cerca del límite | 33 |
| % sobre el total | 5,4 % |
| Importe acumulado (sin IVA) | 636.321 € |
| Importe acumulado (con IVA) | 769.936 € |
| Empresas distintas implicadas (por NIF) | 30 |

*El importe sin IVA es el que aparece en la tabla del dashboard de Power BI (columna `IMPORTE_SIN_IVA_EUR`); el con IVA es el comparable con el Gasto Total del resto del informe.*

Empresas con **más de un contrato** cerca del límite (identificadas por NIF, merecen revisión individualizada):

- MICROASFALT SL — CIF B15894587 — 2 contratos (38.391 € y 39.235 €, ambos de obras y muy próximos al techo de 40.000 €).
- GALSUR PROYECTOS Y OBRAS S.L.U. — CIF B94101946 — 2 contratos (39.612 € y 14.400 €).
- MOVIMIENTO DE ARIDOS Y CONSTRUCCIONES DE AROSA S.L. — CIF B36533537 — 2 contratos (14.998 € y 14.994 €, ambos de suministros y pegados al techo de 15.000 €).

El resto (27 empresas identificadas por NIF) tienen un único contrato cerca del límite cada una.

> **Nota sobre calidad del dato**: el tercer caso (MOVIMIENTO DE ARIDOS) solo emerge al agrupar por NIF; si se agrupa por nombre pasa desapercibido porque los dos contratos están publicados con grafías distintas ("MOVIMIENTO DE ARIDOS Y CONSTRUCCIONES DE AROSA, S.L." y "MOVIMENTO DE ARIDOS Y CONSTRUCCIONES DE AROSA S.L."). Esto refuerza la recomendación de analizar este tipo de señales por identificador fiscal y no por razón social.

### 4.2 NIF/CIF inválidos

Se valida la identificación fiscal con el algoritmo oficial de la AEAT (NIF, NIE y CIF). Un NIF inválido en un contrato público es, como mínimo, un error de captura o publicación; en algunos casos puede apuntar a una contratación con datos erróneos o falseados.

| | Valor |
|---|---|
| Contratos con NIF inválido | 16 |
| Empresas distintas afectadas | 15 |
| Importe acumulado | 50.260 € |

Motivos de invalidez detectados:

| Motivo | Nº contratos |
|---|---:|
| Checksum incorrecto | 6 |
| Longitud corta | 6 |
| Longitud larga | 3 |
| Formato desconocido | 1 |

La mayoría de los casos son errores tipográficos evidentes (longitud incorrecta) o registros con checksum mal calculado. No es un volumen alto, pero idealmente deberían ser cero en una publicación oficial.

> La diferencia entre 16 contratos y 15 empresas se explica porque un mismo NIF inválido (`5248378Q`, MARA CRUZ LPEZ MARTNEZ) aparece en dos contratos distintos. La tabla del dashboard muestra 15 filas porque agrupa por NIF; el KPI de contratos cuenta 16 porque suma los registros individuales.

## 5. Respuesta al brief

| Pregunta del brief | Respuesta |
|---|---|
| Número total de contratos | 607 |
| Importe total adjudicado | 2,74 M€ |
| Importe medio por contrato | 4.521 € |
| Evolución temporal del gasto | Ver informe Power BI, página "Resumen ejecutivo" |
| Top empresas por importe | Ver sección 3 |
| Distribución por tipo de contrato | Ver sección 2.2 |
| Gasto por área o departamento | **No disponible en los datos publicados**; se usa el tipo de contrato como proxy (ver limitaciones) |
| Segmentación interactiva | Informe Power BI con filtros por año, tipo y empresa |

## 6. Limitaciones

- **Sin desglose por área o departamento**: todos los contratos figuran bajo un único órgano contratante ("Ayuntamiento Vilagarcía de Arousa"), sin subdivisión por concejalía o servicio. Por eso el informe no responde esa pregunta del brief — no hay datos. Se documenta en el README.
- **Fechas sintéticas**: el 96 % de los contratos no tiene `fecha_formalizacion` publicada. Para poder construir visualizaciones temporales se genera una fecha aleatoria dentro del año conocido del contrato (semilla fija). Las tendencias mensuales deben interpretarse con cautela; el año sí es fiable.
- **Sesgo temporal hacia 2023**: el 90 % de los registros corresponde a 2023, por lo que no puede hacerse un análisis sólido de evolución interanual con este dataset.
- **Solo contratos menores**: el Excel original incluía contratos mayores que se filtraron por estar fuera del alcance. No se analiza el gasto global del Ayuntamiento.

## 7. Conclusiones

1. **El grueso del gasto en contratación menor se reparte entre obras (28,8 %), servicios (42,6 %) y suministros (25,2 %)**, con un peso residual de contratos privados (3,4 %).
2. **No se detecta concentración excesiva**: ninguna empresa acapara el gasto, y el top 10 supone menos de una cuarta parte del total. Dentro de ese top, sí aparecen proveedores recurrentes en obras y servicios técnicos que justificaría examinar con más detalle.
3. **El 5,4 % de contratos está cerca del límite legal**. Es una cifra manejable y no necesariamente problemática, pero las empresas con múltiples contratos en esa franja (MICROASFALT, GALSUR y MOVIMIENTO DE ARIDOS — esta última solo detectable agrupando por NIF) merecen una revisión caso a caso por posible fraccionamiento.
4. **Los 16 contratos con NIF inválido** son probablemente errores de publicación; deberían cero. Es una señal sobre la calidad del dato en el portal, más que sobre fraude.

### Próximos pasos sugeridos

- Cruzar las empresas del top 10 con el Registro Mercantil para verificar titularidades y detectar posibles vínculos entre proveedores.
- Incorporar contratos mayores para calibrar si las empresas recurrentes en menores también ganan los mayores.
- Analizar `objeto_contrato` con técnicas de texto para inferir un área funcional aproximada (obra pública, administración, servicios sociales…), supliendo parcialmente la ausencia de campo departamento.
- Una vez haya datos de más años, repetir el análisis de fraccionamiento buscando patrones de varios contratos consecutivos cerca del límite al mismo proveedor.
