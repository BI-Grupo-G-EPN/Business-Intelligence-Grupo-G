-- =========================================================
-- La Tradicional – Boulangerie
-- Archivo 02: verificación del contenido cargado por el ETL
-- Reúne en una sola consulta los controles de staging,
-- dimensiones y hechos. Cada fila dice OK o REVISAR.
-- Ejecutar después del job de Pentaho.
-- =========================================================

WITH controles AS (
  -- ===== STAGING: compras (5 archivos TXT del SRI) =====
  SELECT 1 AS orden, 'raw_compras' AS tabla, 'Filas cargadas' AS control,
         (SELECT COUNT(*) FROM raw_compras)::text AS obtenido,
         '491' AS esperado
  UNION ALL SELECT 2, 'raw_compras', 'Archivos TXT cargados',
         (SELECT COUNT(DISTINCT archivo_origen) FROM raw_compras)::text, '6'
  UNION ALL SELECT 3, 'raw_compras', 'Claves de acceso únicas',
         (SELECT COUNT(DISTINCT clave_acceso) FROM raw_compras)::text, '491'
  UNION ALL SELECT 4, 'raw_compras', 'Largo de la clave de acceso (mín-máx)',
         (SELECT MIN(LENGTH(clave_acceso)) || '-' || MAX(LENGTH(clave_acceso)) FROM raw_compras), '49-49'
  UNION ALL SELECT 5, 'raw_compras', 'Tipos de comprobante',
         (SELECT string_agg(DISTINCT tipo_comprobante, ', ') FROM raw_compras), 'Factura'

  -- ===== STAGING: ventas (archivo XLS) =====
  UNION ALL SELECT 6, 'raw_ventas', 'Filas cargadas',
         (SELECT COUNT(*) FROM raw_ventas)::text, '6768'
  UNION ALL SELECT 7, 'raw_ventas', 'Años en las fechas',
         (SELECT string_agg(DISTINCT EXTRACT(YEAR FROM fecha)::text, ', ') FROM raw_ventas), '2026'
  UNION ALL SELECT 8, 'raw_ventas', 'Largos de identificación',
         (SELECT string_agg(DISTINCT LENGTH(identificacion)::text, ', ') FROM raw_ventas), '10, 13, 8'
  UNION ALL SELECT 9, 'raw_ventas', 'Total de ventas',
         (SELECT SUM(total) FROM raw_ventas)::text, '58349.00'

  -- ===== DIMENSIONES =====
  UNION ALL SELECT 10, 'dim_tiempo', 'Fechas (igual a fechas distintas del staging)',
         (SELECT COUNT(*) FROM dim_tiempo)::text,
         (SELECT COUNT(*) FROM (SELECT fecha FROM raw_ventas
                                UNION
                                SELECT fecha_emision FROM raw_compras) t)::text
  UNION ALL SELECT 11, 'dim_tiempo', 'Días de semana mal calculados',
         (SELECT COUNT(*) FROM dim_tiempo
          WHERE dia_semana <> EXTRACT(DOW FROM fecha) + 1)::text, '0'
  UNION ALL SELECT 12, 'dim_producto', 'Códigos de producto',
         (SELECT COUNT(*) FROM dim_producto)::text, '24'
  UNION ALL SELECT 13, 'dim_producto', 'Productos estándar',
         (SELECT COUNT(DISTINCT nombre_estandar) FROM dim_producto)::text, '21'
  UNION ALL SELECT 14, 'dim_producto', 'Productos sin clasificar',
         (SELECT COUNT(*) FROM dim_producto
          WHERE linea IS NULL OR linea = 'SIN CLASIFICAR')::text, '0'
  UNION ALL SELECT 15, 'dim_cliente', 'Clientes (igual a identificaciones del staging)',
         (SELECT COUNT(*) FROM dim_cliente)::text,
         (SELECT COUNT(DISTINCT TRIM(identificacion)) FROM raw_ventas)::text
  UNION ALL SELECT 16, 'dim_cliente', 'Identificaciones repetidas',
         (SELECT COUNT(*) - COUNT(DISTINCT identificacion) FROM dim_cliente)::text, '0'
  UNION ALL SELECT 17, 'dim_proveedor', 'Proveedores (igual a RUC del staging)',
         (SELECT COUNT(*) FROM dim_proveedor)::text,
         (SELECT COUNT(DISTINCT TRIM(ruc_emisor)) FROM raw_compras)::text
  UNION ALL SELECT 18, 'dim_proveedor', 'RUC repetidos',
         (SELECT COUNT(*) - COUNT(DISTINCT ruc) FROM dim_proveedor)::text, '0'
  UNION ALL SELECT 19, 'dim_proveedor', 'RUC con largo distinto de 13',
         (SELECT COUNT(*) FROM dim_proveedor WHERE LENGTH(ruc) <> 13)::text, '0'

  -- ===== HECHOS =====
  UNION ALL SELECT 20, 'fact_ventas', 'Filas cargadas',
         (SELECT COUNT(*) FROM fact_ventas)::text, '6768'
  UNION ALL SELECT 21, 'fact_ventas', 'Llaves nulas (producto, cliente o fecha)',
         (SELECT COUNT(*) FROM fact_ventas
          WHERE producto_key IS NULL OR cliente_key IS NULL OR fecha IS NULL)::text, '0'
  UNION ALL SELECT 22, 'fact_ventas', 'Unidades vendidas',
         (SELECT SUM(cantidad) FROM fact_ventas)::text,
         (SELECT SUM(cantidad) FROM raw_ventas)::text
  UNION ALL SELECT 23, 'fact_ventas', 'Total de ventas',
         (SELECT SUM(total) FROM fact_ventas)::text, '58349.00'
  UNION ALL SELECT 24, 'fact_compras', 'Filas cargadas',
         (SELECT COUNT(*) FROM fact_compras)::text, '491'
  UNION ALL SELECT 25, 'fact_compras', 'Llaves nulas (proveedor o fecha)',
         (SELECT COUNT(*) FROM fact_compras
          WHERE proveedor_key IS NULL OR fecha IS NULL)::text, '0'
  UNION ALL SELECT 26, 'fact_compras', 'Total de compras (igual al staging)',
         (SELECT SUM(importe_total) FROM fact_compras)::text,
         (SELECT SUM(importe_total) FROM raw_compras)::text
)
SELECT orden, tabla, control, obtenido, esperado,
       CASE WHEN obtenido = esperado THEN 'OK' ELSE 'REVISAR' END AS estado
FROM controles
ORDER BY orden;


-- =========================================================
-- Solo si hay que repetir la carga a mano (sin el job):
-- quitar los guiones de la línea y ejecutarla sola.
-- =========================================================
-- TRUNCATE raw_compras, raw_ventas, dim_tiempo, dim_producto, dim_cliente,
--          dim_proveedor, fact_ventas, fact_compras RESTART IDENTITY;
