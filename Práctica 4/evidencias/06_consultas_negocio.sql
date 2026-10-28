/* ----------------------------------------------------------------------------
   Consulta 1. ¿Cuántas ventas se realizaron por categoría de producto y mes?
   Dimensiones : dim_product (categoría), dim_date (mes, por fecha de PEDIDO)
   Medida      : número de ventas = COUNT(*), una fila por venta
   Detalle     : se agrupa por year_month (AAAA-MM) y no solo por el número
                 de mes, para no mezclar el mismo mes de años distintos.
   Control     : 59 filas; la suma de total_ventas es 100.
   ---------------------------------------------------------------------------- */
SELECT p.category,
       d.year_month,
       COUNT(*) AS total_ventas
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_date d    ON f.order_date_key = d.date_key
GROUP BY p.category, d.year_month
ORDER BY d.year_month, p.category;


/* ----------------------------------------------------------------------------
   Consulta 2. ¿Cuál es el ingreso total (ventas) por cliente y género?
   Dimensión   : dim_customer (cliente y género)
   Medida      : ingreso = SUM(sales_amount)
   Detalle     : customer_key va en el GROUP BY porque se pide el total por
                 cliente; el género es un atributo que acompaña al cliente.
   Control     : 10 filas; el primero es el cliente 1022 (M) con 11656;
                 el total general es 69547.
   ---------------------------------------------------------------------------- */
SELECT c.customer_key,
       c.gender,
       SUM(f.sales_amount) AS ingreso_total
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.gender
ORDER BY ingreso_total DESC;


/* ----------------------------------------------------------------------------
   Consulta 3. ¿Cuál es la cantidad total vendida por producto?
   Dimensión   : dim_product (producto)
   Medida      : unidades = SUM(quantity)
   Control     : 9 filas; el primero es Product 19 con 60 unidades;
                 el total general es 296.
   ---------------------------------------------------------------------------- */
SELECT p.product_key,
       p.product_name,
       SUM(f.quantity) AS cantidad_total
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_key, p.product_name
ORDER BY cantidad_total DESC;


/* ----------------------------------------------------------------------------
   Consulta 4. ¿Cuál fue la cantidad enviada por mes de envío?
   Dimensión   : dim_date, con el rol de FECHA DE ENVÍO
   Medida      : unidades enviadas = SUM(quantity)
   Detalle     : misma estructura que la consulta 1, pero el JOIN usa
                 ship_date_key y no order_date_key. Una sola dim_date
                 responde a "cuándo se pidió" y a "cuándo se envió"
                 (dimensión con doble rol).
   Control     : 41 filas; el total es 296, igual que la consulta 3.
   ---------------------------------------------------------------------------- */
SELECT d.year_month AS mes_envio,
       SUM(f.quantity) AS cantidad_enviada
FROM fact_sales f
JOIN dim_date d ON f.ship_date_key = d.date_key
GROUP BY d.year_month
ORDER BY d.year_month;


/* ----------------------------------------------------------------------------
   Consulta 5. ¿Cuánto se vendió por tamaño de producto y estado civil del
               cliente?
   Dimensiones : dim_product (tamaño) y dim_customer (estado civil)
   Medidas     : monto = SUM(sales_amount); unidades = SUM(quantity)
   Detalle     : es la única consulta que cruza dos dimensiones a la vez.
                 "Cuánto se vendió" puede ser dinero o unidades, por eso se
                 devuelven ambas medidas.
   Control     : 6 filas; los montos suman 69547
                 (Large-Married 17047, Large-Single 6607,
                  Medium-Married 23714, Medium-Single 10504,
                  Small-Married 9411, Small-Single 2264).
   ---------------------------------------------------------------------------- */
SELECT p.size,
       c.marital_status,
       SUM(f.sales_amount) AS monto_vendido,
       SUM(f.quantity)     AS unidades_vendidas
FROM fact_sales f
JOIN dim_product p  ON f.product_key = p.product_key
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY p.size, c.marital_status
ORDER BY p.size, c.marital_status;