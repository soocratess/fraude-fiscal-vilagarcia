-- =============================================================================
-- ANÁLISIS DE CONTRATOS MENORES — Ayuntamiento de Vilagarcía de Arousa
-- Esquema en estrella: FACT_CONTRATOS + DIM_CONTRATISTA + DIM_FECHA
--
-- Tablas eliminadas del diseño original (ver notebook 03 para justificación):
--   - DIM_TIPO_CONTRATO → tipo_contrato va directo en FACT (4 valores, sin atributos variables)
--   - DIM_ENTIDAD       → entidad_contratante es constante en todo el dataset
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1: Volumen de contratación por año
-- Cuántos contratos se firmaron cada año y cuánto dinero movieron.
-- Permite detectar años con un incremento inusual de actividad.
-- -----------------------------------------------------------------------------
SELECT
    anio_contrato,
    COUNT(*)                                AS num_contratos,
    ROUND(SUM(importe_con_iva_eur), 2)      AS total_eur,
    ROUND(AVG(importe_con_iva_eur), 2)      AS media_eur,
    ROUND(MAX(importe_con_iva_eur), 2)      AS max_eur
FROM FACT_CONTRATOS
GROUP BY anio_contrato
ORDER BY anio_contrato;


-- -----------------------------------------------------------------------------
-- Q2: Volumen por tipo de contrato (Obras / Servicios / Suministros / Privado)
-- Revela qué categoría concentra más gasto y si alguna roza el límite legal
-- de forma sistemática.
-- -----------------------------------------------------------------------------
SELECT
    tipo_contrato,
    COUNT(*)                               AS num_contratos,
    ROUND(SUM(importe_con_iva_eur), 2)     AS total_eur,
    ROUND(AVG(importe_con_iva_eur), 2)     AS media_eur,
    -- porcentaje sobre el gasto total
    ROUND(
        100.0 * SUM(importe_con_iva_eur)
        / SUM(SUM(importe_con_iva_eur)) OVER (),
        1
    )                                      AS pct_gasto
FROM FACT_CONTRATOS
GROUP BY tipo_contrato
ORDER BY total_eur DESC;


-- -----------------------------------------------------------------------------
-- Q3: Top 20 empresas adjudicatarias por importe total
-- Una concentración elevada de contratos en pocas empresas puede indicar
-- favoritismo o falta de concurrencia real en la licitación.
-- -----------------------------------------------------------------------------
SELECT
    c.nombre_contratista,
    c.nif_contratista,
    COUNT(*)                              AS num_contratos,
    ROUND(SUM(f.importe_con_iva_eur), 2)  AS total_eur,
    ROUND(AVG(f.importe_con_iva_eur), 2)  AS media_eur,
    COUNT(DISTINCT f.anio_contrato)       AS anios_activa
FROM FACT_CONTRATOS  f
JOIN DIM_CONTRATISTA c ON f.nif_contratista = c.nif_contratista
WHERE c.nombre_contratista IS NOT NULL
GROUP BY c.nombre_contratista, c.nif_contratista
ORDER BY total_eur DESC
LIMIT 20;


-- -----------------------------------------------------------------------------
-- Q4: Contratos que superan o rozan el límite legal (flag_limite)
-- Los contratos «cerca_del_limite» y «supera_limite» son los de mayor riesgo:
-- importes próximos al umbral pueden indicar fragmentación deliberada para
-- evitar licitación pública.
-- -----------------------------------------------------------------------------
SELECT
    flag_limite,
    tipo_contrato,
    COUNT(*)                              AS num_contratos,
    ROUND(SUM(importe_con_iva_eur), 2)    AS total_eur,
    ROUND(MIN(importe_con_iva_eur), 2)    AS min_eur,
    ROUND(MAX(importe_con_iva_eur), 2)    AS max_eur
FROM FACT_CONTRATOS
GROUP BY flag_limite, tipo_contrato
ORDER BY
    CASE flag_limite
        WHEN 'supera_limite'    THEN 1
        WHEN 'cerca_del_limite' THEN 2
        ELSE 3
    END,
    tipo_contrato;


-- -----------------------------------------------------------------------------
-- Q5: Detalle de los contratos que superan el límite legal
-- Lista individual de expedientes donde el importe supera el umbral permitido
-- para contratos menores. Cada uno debería haberse licitado públicamente.
-- -----------------------------------------------------------------------------
SELECT
    f.num_referencia,
    f.anio_contrato,
    f.tipo_contrato,
    f.objeto_contrato,
    c.nombre_contratista,
    c.nif_contratista,
    ROUND(f.importe_con_iva_eur, 2)  AS importe_con_iva_eur,
    f.fecha_estimada
FROM FACT_CONTRATOS  f
JOIN DIM_CONTRATISTA c ON f.nif_contratista = c.nif_contratista
WHERE f.flag_limite = 'supera_limite'
ORDER BY f.importe_con_iva_eur DESC;


-- -----------------------------------------------------------------------------
-- Q6: Empresas que acumulan múltiples contratos cercanos al límite
-- Si una empresa recibe varios contratos que individualmente rozan el tope,
-- la suma total puede suponer una adjudicación encubierta sin licitación.
-- -----------------------------------------------------------------------------
SELECT
    c.nombre_contratista,
    c.nif_contratista,
    f.tipo_contrato,
    COUNT(*)                              AS contratos_cerca_limite,
    ROUND(SUM(f.importe_con_iva_eur), 2)  AS acumulado_eur
FROM FACT_CONTRATOS  f
JOIN DIM_CONTRATISTA c ON f.nif_contratista = c.nif_contratista
WHERE f.flag_limite IN ('cerca_del_limite', 'supera_limite')
GROUP BY c.nombre_contratista, c.nif_contratista, f.tipo_contrato
HAVING COUNT(*) >= 2
ORDER BY acumulado_eur DESC;


-- -----------------------------------------------------------------------------
-- Q7: Contratistas con NIF/CIF inválido
-- Un NIF que no supera el checksum puede indicar un error de registro o,
-- en casos extremos, una empresa ficticia.
-- -----------------------------------------------------------------------------
SELECT
    c.nif_contratista,
    c.motivo_invalido,
    c.nombre_contratista,
    COUNT(*)                              AS num_contratos,
    ROUND(SUM(f.importe_con_iva_eur), 2)  AS total_eur
FROM FACT_CONTRATOS  f
JOIN DIM_CONTRATISTA c ON f.nif_contratista = c.nif_contratista
WHERE c.nif_valido = FALSE
GROUP BY c.nif_contratista, c.motivo_invalido, c.nombre_contratista
ORDER BY total_eur DESC;


-- -----------------------------------------------------------------------------
-- Q8: Distribución mensual de contratos usando DIM_FECHA
-- Detecta si hay meses con una concentración inusual de adjudicaciones,
-- por ejemplo al final del ejercicio presupuestario (noviembre-diciembre).
-- -----------------------------------------------------------------------------
SELECT
    d.anio,
    d.mes,
    d.nombre_mes,
    COUNT(*)                              AS num_contratos,
    ROUND(SUM(f.importe_con_iva_eur), 2)  AS total_eur
FROM FACT_CONTRATOS f
JOIN DIM_FECHA      d ON f.fecha_estimada = d.fecha
GROUP BY d.anio, d.mes, d.nombre_mes
ORDER BY d.anio, d.mes;


-- -----------------------------------------------------------------------------
-- Q9: Objeto de contrato más repetido por empresa (posible fragmentación)
-- Si el mismo objeto aparece adjudicado múltiples veces al mismo contratista,
-- puede ser un indicio de que se ha troceado un contrato mayor para evitar
-- superar el límite legal.
-- -----------------------------------------------------------------------------
SELECT
    f.objeto_contrato,
    c.nombre_contratista,
    COUNT(*)                              AS veces,
    ROUND(SUM(f.importe_con_iva_eur), 2)  AS total_eur
FROM FACT_CONTRATOS  f
JOIN DIM_CONTRATISTA c ON f.nif_contratista = c.nif_contratista
GROUP BY f.objeto_contrato, c.nombre_contratista
HAVING COUNT(*) >= 3
ORDER BY veces DESC, total_eur DESC
LIMIT 30;


-- -----------------------------------------------------------------------------
-- Q10: Resumen ejecutivo — KPIs globales del dataset
-- Vista rápida de los indicadores clave para el dashboard de Power BI.
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                                            AS total_contratos,
    COUNT(DISTINCT anio_contrato)                                       AS anios_cubiertos,
    COUNT(DISTINCT nif_contratista)                                     AS empresas_distintas,
    ROUND(SUM(importe_con_iva_eur), 2)                                  AS gasto_total_eur,
    ROUND(AVG(importe_con_iva_eur), 2)                                  AS gasto_medio_eur,
    SUM(CASE WHEN flag_limite = 'supera_limite'    THEN 1 ELSE 0 END)   AS contratos_ilegales,
    SUM(CASE WHEN flag_limite = 'cerca_del_limite' THEN 1 ELSE 0 END)   AS contratos_en_riesgo
FROM FACT_CONTRATOS;
