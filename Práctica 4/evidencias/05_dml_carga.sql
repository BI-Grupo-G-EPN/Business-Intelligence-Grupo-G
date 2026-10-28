/* ----------------------------------------------------------------------------
   Paso 1. Dimensión producto
   SELECT DISTINCT: staging repite los atributos del producto en cada venta;
   la dimensión debe tener una fila por producto.
   Control: 9 filas.
   ---------------------------------------------------------------------------- */
INSERT INTO dim_product
    (product_key, product_code, product_name, list_price, color, size, category, subcategory)
SELECT DISTINCT
    product_key, product_code, product_name, list_price, color, size, category, subcategory
FROM stg_ventas
ORDER BY product_key;


/* ----------------------------------------------------------------------------
   Paso 2. Dimensión cliente
   Igual que en producto: una fila por cliente.
   Control: 10 filas.
   ---------------------------------------------------------------------------- */
INSERT INTO dim_customer
    (customer_key, birth_date, marital_status, gender, income, children, home_owner, cars)
SELECT DISTINCT
    customer_key, birth_date, marital_status, gender, income, children, home_owner, cars
FROM stg_ventas
ORDER BY customer_key;


/* ----------------------------------------------------------------------------
   Paso 3. Dimensión fecha (calendario completo 2022-2025)
   No se copia del CSV, que solo contiene las fechas con alguna venta (147
   distintas). Una dimensión de tiempo real incluye también los días sin
   ventas; generate_series crea los 1461 días de una sola vez.
   Control: 1461 filas.
   ---------------------------------------------------------------------------- */
INSERT INTO dim_date
    (date_key, full_date, year, quarter, month, month_name, year_month, day, day_of_week, day_name)
SELECT
    to_char(d, 'YYYYMMDD')::INT,
    d::DATE,
    EXTRACT(YEAR FROM d)::INT,
    EXTRACT(QUARTER FROM d)::INT,
    EXTRACT(MONTH FROM d)::INT,
    (ARRAY['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto',
           'Septiembre','Octubre','Noviembre','Diciembre'])[EXTRACT(MONTH FROM d)::INT],
    to_char(d, 'YYYY-MM'),
    EXTRACT(DAY FROM d)::INT,
    EXTRACT(ISODOW FROM d)::INT,
    (ARRAY['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'])[EXTRACT(ISODOW FROM d)::INT]
FROM generate_series('2022-01-01'::DATE, '2025-12-31'::DATE, '1 day') AS d;


/* ----------------------------------------------------------------------------
   Paso 4. Tabla de hechos
   Las claves foráneas validan la integridad: si algún producto, cliente o
   fecha no existiera en su dimensión, el INSERT fallaría.
   Control: 100 filas.
   ---------------------------------------------------------------------------- */
INSERT INTO fact_sales
    (order_number, order_line_number, product_key, customer_key,
     order_date_key, ship_date_key, quantity, unit_price, product_cost, sales_amount)
SELECT
    order_number, order_line_number, product_key, customer_key,
    order_date_key, ship_date_key, quantity, unit_price, product_cost, sales_amount
FROM stg_ventas;


/* ----------------------------------------------------------------------------
   Paso 5. Verificación de la carga
   Control: dim_product 9, dim_customer 10, dim_date 1461, fact_sales 100.
   ---------------------------------------------------------------------------- */
SELECT 'dim_product'  AS tabla, COUNT(*) AS filas FROM dim_product
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_date',     COUNT(*) FROM dim_date
UNION ALL SELECT 'fact_sales',   COUNT(*) FROM fact_sales;

-- Prueba de que no se perdió ni duplicó ninguna venta en el paso de staging a
-- hechos. Control: ambos totales iguales (69547).
SELECT (SELECT SUM(sales_amount) FROM stg_ventas) AS total_staging,
       (SELECT SUM(sales_amount) FROM fact_sales)  AS total_hechos;