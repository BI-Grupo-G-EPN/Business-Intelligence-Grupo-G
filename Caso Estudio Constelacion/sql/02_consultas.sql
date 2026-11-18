-- =========================================================
-- HAPPYTECH - Consultas de análisis (ejecutar después del job de Pentaho)
-- =========================================================
-- Conteo de filas cargadas (esperado: 30 fechas, 5 productos, 5 clientes, 4 motivos, 50 pedidos, 50 tickets)
SELECT 'dim_tiempo' tabla, COUNT(*) FROM dim_tiempo UNION ALL
SELECT 'dim_producto', COUNT(*) FROM dim_producto UNION ALL
SELECT 'dim_cliente', COUNT(*) FROM dim_cliente UNION ALL
SELECT 'dim_motivo', COUNT(*) FROM dim_motivo UNION ALL
SELECT 'fact_pedidos', COUNT(*) FROM fact_pedidos UNION ALL
SELECT 'fact_soporte', COUNT(*) FROM fact_soporte;
-- 1. Productos y categorías más vendidos por ciudad
SELECT c.ciudad, p.categoria, p.producto,
       SUM(f.cantidad) AS unidades, SUM(f.total_pedido) AS ventas
FROM fact_pedidos f
JOIN dim_producto p ON p.id_producto = f.id_producto
JOIN dim_cliente  c ON c.id_cliente  = f.id_cliente
GROUP BY c.ciudad, p.categoria, p.producto
ORDER BY c.ciudad, unidades DESC;

-- 2. Clientes que más compran por ciudad
SELECT c.ciudad, c.cliente,
       SUM(f.cantidad) AS unidades, SUM(f.total_pedido) AS ventas
FROM fact_pedidos f
JOIN dim_cliente c ON c.id_cliente = f.id_cliente
GROUP BY c.ciudad, c.cliente
ORDER BY unidades DESC;

-- 3. Productos y categorías con más tickets
SELECT p.categoria, p.producto, COUNT(*) AS tickets,
       ROUND(AVG(f.tiempo_respuesta_horas),1) AS horas_promedio
FROM fact_soporte f
JOIN dim_producto p ON p.id_producto = f.id_producto
GROUP BY p.categoria, p.producto
ORDER BY tickets DESC;

-- 4. Clientes con más tickets
SELECT c.cliente, c.ciudad, COUNT(*) AS tickets
FROM fact_soporte f
JOIN dim_cliente c ON c.id_cliente = f.id_cliente
GROUP BY c.cliente, c.ciudad
ORDER BY tickets DESC;

-- Análisis cruzado (gracias a las dimensiones compartidas):
-- tickets por cada 10 unidades vendidas, por producto
WITH v AS (SELECT id_producto, SUM(cantidad) u FROM fact_pedidos GROUP BY id_producto),
     t AS (SELECT id_producto, COUNT(*) n FROM fact_soporte GROUP BY id_producto)
SELECT p.producto, v.u AS unidades_vendidas, COALESCE(t.n,0) AS tickets,
       ROUND(10.0*COALESCE(t.n,0)/v.u,2) AS tickets_por_10_unidades
FROM dim_producto p
LEFT JOIN v ON v.id_producto = p.id_producto
LEFT JOIN t ON t.id_producto = p.id_producto
ORDER BY tickets_por_10_unidades DESC;
