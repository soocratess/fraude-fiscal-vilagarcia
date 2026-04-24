-- =============================================================================
-- ANÁLISIS DE CONTRATOS MENORES — Ayuntamiento de Vilagarcía de Arousa
--
-- Esquema en estrella: FACT_CONTRATOS + DIM_CONTRATISTA + DIM_FECHA
-- Los importes se reportan con IVA (columna importe_con_iva_eur), coherente
-- con la medida "Gasto Total" del informe de Power BI.
--
-- Las consultas se ordenan de general a específico: primero los KPIs globales
-- y la distribución por año / tipo / empresa (respuestas directas al brief)
-- y después dos análisis específicos del dominio de detección de fraude.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1: Resumen ejecutivo — KPIs globales del dataset
-- Fila única con los indicadores clave. Responde a "¿cuántos contratos?" y
-- "¿cuál es el importe total y el importe medio?" del brief.
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                                            AS total_contratos,
    COUNT(DISTINCT anio_contrato)                                       AS anios_cubiertos,
    COUNT(DISTINCT nif_contratista)                                     AS empresas_distintas,
    ROUND(SUM(importe_con_iva_eur), 2)                                  AS gasto_total_eur,
    ROUND(AVG(importe_con_iva_eur), 2)                                  AS gasto_medio_eur,
    SUM(CASE WHEN flag_limite = 'cerca_del_limite' THEN 1 ELSE 0 END)   AS contratos_cerca_limite
FROM FACT_CONTRATOS;


-- -----------------------------------------------------------------------------
-- Q2: Volumen de contratación por año
-- Responde a "¿cuántos contratos se han realizado por año?" del brief.
-- Permite detectar años con incremento inusual de actividad o huecos en la
-- publicación.
-- -----------------------------------------------------------------------------
SELECT
    anio_contrato,
    COUNT(*)                              AS num_contratos,
    ROUND(SUM(importe_con_iva_eur), 2)    AS total_eur,
    ROUND(AVG(importe_con_iva_eur), 2)    AS media_eur,
    ROUND(MAX(importe_con_iva_eur), 2)    AS max_eur
FROM FACT_CONTRATOS
GROUP BY anio_contrato
ORDER BY anio_contrato;


-- -----------------------------------------------------------------------------
-- Q3: Volumen por tipo de contrato (Obras / Servicios / Suministros / Privado)
-- Usado como proxy de la pregunta "qué áreas municipales gastan más" del brief,
-- ya que el dataset no incluye área o departamento (ver README, sección
-- Limitaciones). Muestra qué categoría concentra más gasto y su peso relativo.
-- -----------------------------------------------------------------------------
SELECT
    tipo_contrato,
    COUNT(*)                               AS num_contratos,
    ROUND(SUM(importe_con_iva_eur), 2)     AS total_eur,
    ROUND(AVG(importe_con_iva_eur), 2)     AS media_eur,
    ROUND(
        100.0 * SUM(importe_con_iva_eur)
        / SUM(SUM(importe_con_iva_eur)) OVER (),
        1
    )                                      AS pct_gasto
FROM FACT_CONTRATOS
GROUP BY tipo_contrato
ORDER BY total_eur DESC;


-- -----------------------------------------------------------------------------
-- Q4: Top 20 empresas adjudicatarias por importe total
-- Responde a "¿qué empresas concentran mayor volumen de gasto?" del brief.
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
-- Q5 (específica del dominio): Contratistas con NIF/CIF inválido
-- El NIF se valida con el algoritmo oficial de la AEAT. Un identificador que
-- no supera el checksum o tiene longitud anómala indica, como mínimo, un error
-- de captura; en casos extremos puede apuntar a datos falseados.
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
-- Q6 (específica del dominio): Empresas con múltiples contratos cerca del límite
-- Se marca como "cerca_del_limite" todo contrato cuyo importe supera el 90 %
-- del umbral legal (15.000 € servicios/suministros, 40.000 € obras). Una misma
-- empresa con varios contratos rozando el tope puede estar recibiendo un
-- contrato fragmentado para evitar licitar por procedimiento abierto.
-- Se agrupa por NIF (no por nombre) para capturar casos de la misma empresa
-- publicada con grafías distintas.
-- -----------------------------------------------------------------------------
SELECT
    c.nif_contratista,
    c.nombre_contratista,
    f.tipo_contrato,
    COUNT(*)                              AS contratos_cerca_limite,
    ROUND(SUM(f.importe_con_iva_eur), 2)  AS acumulado_eur
FROM FACT_CONTRATOS  f
JOIN DIM_CONTRATISTA c ON f.nif_contratista = c.nif_contratista
WHERE f.flag_limite = 'cerca_del_limite'
GROUP BY c.nif_contratista, c.nombre_contratista, f.tipo_contrato
HAVING COUNT(*) >= 2
ORDER BY acumulado_eur DESC;
