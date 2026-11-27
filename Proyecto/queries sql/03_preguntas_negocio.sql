-- =========================================================
-- La Tradicional – Boulangerie
-- Archivo 03: consultas de las 6 preguntas de negocio
-- Se ejecutan sobre el modelo dimensional (fact_ y dim_).
-- Ejecutar cada consulta por separado (seleccionarla y F5).
-- =========================================================


-- =========================================================
-- PREGUNTA 1
-- ¿Cuánto se vende cada mes y en qué línea:
-- postres o bocadillos de sal?
-- =========================================================
SELECT t.anio,
       t.mes,
       SUM(f.total) FILTER (WHERE p.linea = 'Postres')           AS ventas_postres,
       SUM(f.total) FILTER (WHERE p.linea = 'Bocadillos de sal') AS ventas_bocadillos,
       SUM(f.total)                                              AS ventas_total,
       ROUND(100.0 * SUM(f.total) FILTER (WHERE p.linea = 'Postres')
             / NULLIF(SUM(f.total), 0), 1)                       AS pct_postres,
       COUNT(DISTINCT f.num_documento)                           AS facturas,
       ROUND(SUM(f.total) / COUNT(DISTINCT f.num_documento), 2)  AS ticket_promedio
FROM fact_ventas f
JOIN dim_tiempo   t ON f.fecha        = t.fecha
JOIN dim_producto p ON f.producto_key = p.producto_key
GROUP BY t.anio, t.mes
ORDER BY t.anio, t.mes;


-- =========================================================
-- PREGUNTA 2
-- ¿Cuáles son los productos más vendidos por ingreso
-- y por unidades?
-- =========================================================
SELECT RANK() OVER (ORDER BY SUM(f.total)    DESC)             AS puesto_ingreso,
       RANK() OVER (ORDER BY SUM(f.cantidad) DESC)             AS puesto_unidades,
       p.nombre_estandar                                       AS producto,
       p.linea,
       SUM(f.cantidad)                                         AS unidades,
       SUM(f.total)                                            AS ventas,
       ROUND(100.0 * SUM(f.total) / SUM(SUM(f.total)) OVER (), 1) AS pct_ventas
FROM fact_ventas f
JOIN dim_producto p ON f.producto_key = p.producto_key
GROUP BY p.nombre_estandar, p.linea
ORDER BY ventas DESC
LIMIT 10;


-- =========================================================
-- PREGUNTA 3
-- ¿Quiénes son los principales clientes, sin contar
-- al consumidor final?
-- =========================================================
SELECT RANK() OVER (ORDER BY SUM(f.total) DESC)                    AS puesto,
       c.nombre                                                    AS cliente,
       c.tipo_identificacion,
       COUNT(DISTINCT f.num_documento)                             AS facturas,
       SUM(f.total)                                                AS ventas,
       ROUND(SUM(f.total) / COUNT(DISTINCT f.num_documento), 2)    AS ticket_promedio,
       ROUND(100.0 * SUM(f.total) / SUM(SUM(f.total)) OVER (), 1) AS pct_clientes_identificados
FROM fact_ventas f
JOIN dim_cliente c ON f.cliente_key = c.cliente_key
WHERE c.tipo_identificacion <> 'CONSUMIDOR FINAL'
GROUP BY c.cliente_key, c.nombre, c.tipo_identificacion
ORDER BY ventas DESC
LIMIT 10;


-- =========================================================
-- PREGUNTA 4
-- ¿Cómo se comparan las ventas y las compras de cada mes?
-- (las dos tablas de hechos se cruzan por dim_tiempo)
-- =========================================================
WITH ventas AS (
  SELECT t.anio, t.mes, SUM(f.total) AS ventas
  FROM fact_ventas f
  JOIN dim_tiempo t ON f.fecha = t.fecha
  GROUP BY t.anio, t.mes
),
compras AS (
  SELECT t.anio, t.mes, SUM(f.importe_total) AS compras
  FROM fact_compras f
  JOIN dim_tiempo t ON f.fecha = t.fecha
  GROUP BY t.anio, t.mes
)
SELECT COALESCE(v.anio, c.anio)                              AS anio,
       COALESCE(v.mes,  c.mes)                               AS mes,
       COALESCE(v.ventas, 0)                                 AS ventas,
       COALESCE(c.compras, 0)                                AS compras,
       COALESCE(v.ventas, 0) - COALESCE(c.compras, 0)        AS diferencia,
       ROUND(100.0 * c.compras / NULLIF(v.ventas, 0), 1)     AS compras_sobre_ventas_pct
FROM ventas v
FULL JOIN compras c ON v.anio = c.anio AND v.mes = c.mes
ORDER BY anio, mes;


-- =========================================================
-- PREGUNTA 5
-- ¿En qué proveedores se concentra el gasto del negocio?
-- (pct_acumulado muestra cuántos proveedores explican
--  la mayor parte del gasto: análisis de Pareto)
-- =========================================================
WITH gasto AS (
  SELECT p.razon_social,
         p.ruc,
         COUNT(*)             AS facturas,
         SUM(f.importe_total) AS compras
  FROM fact_compras f
  JOIN dim_proveedor p ON f.proveedor_key = p.proveedor_key
  GROUP BY p.proveedor_key, p.razon_social, p.ruc
)
SELECT RANK() OVER (ORDER BY compras DESC)                          AS puesto,
       razon_social                                                 AS proveedor,
       ruc,
       facturas,
       compras,
       ROUND(100.0 * compras / SUM(compras) OVER (), 1)             AS pct_gasto,
       ROUND(100.0 * SUM(compras) OVER (ORDER BY compras DESC
                                        ROWS UNBOUNDED PRECEDING)
             / SUM(compras) OVER (), 1)                             AS pct_acumulado
FROM gasto
ORDER BY compras DESC
LIMIT 10;


-- =========================================================
-- PREGUNTA 6
-- ¿Cómo pagan los clientes y cuánto queda por cobrar?
-- (la última fila, TOTAL, es el resumen de todo el periodo)
-- =========================================================
SELECT COALESCE(f.forma_pago, 'TOTAL')                                 AS forma_pago,
       COUNT(DISTINCT f.num_documento)                                 AS facturas,
       SUM(f.total)                                                    AS ventas,
       ROUND(100.0 * SUM(f.total)
             / (SELECT SUM(total) FROM fact_ventas), 1)                AS pct_ventas,
       SUM(f.saldo)                                                    AS saldo_por_cobrar,
       COUNT(DISTINCT f.num_documento) FILTER (WHERE f.saldo > 0)      AS facturas_pendientes
FROM fact_ventas f
GROUP BY ROLLUP (f.forma_pago)
ORDER BY GROUPING(f.forma_pago), ventas DESC;
