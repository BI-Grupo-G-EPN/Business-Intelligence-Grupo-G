/* ----------------------------------------------------------------------------
   Paso 1. Eliminar tablas previas (hechos primero, por las claves foráneas)
   ---------------------------------------------------------------------------- */
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_date;


/* ----------------------------------------------------------------------------
   Paso 2. Dimensiones
   ---------------------------------------------------------------------------- */

-- Dimensión producto: describe QUÉ se vendió.
-- list_price es un atributo del producto; el precio de cada transacción
-- (unit_price) vive en la tabla de hechos.
CREATE TABLE dim_product (
    product_key   INT PRIMARY KEY,
    product_code  VARCHAR(10) NOT NULL UNIQUE,
    product_name  VARCHAR(100) NOT NULL,
    list_price    NUMERIC(10,2) NOT NULL,
    color         VARCHAR(30) NOT NULL,
    size          VARCHAR(20) NOT NULL,
    category      VARCHAR(50) NOT NULL,
    subcategory   VARCHAR(50) NOT NULL
);

-- Dimensión cliente: describe QUIÉN compró.
CREATE TABLE dim_customer (
    customer_key    INT PRIMARY KEY,
    birth_date      DATE NOT NULL,
    marital_status  VARCHAR(20) NOT NULL,
    gender          CHAR(1) NOT NULL,
    income          NUMERIC(12,2) NOT NULL,
    children        INT NOT NULL,
    home_owner      VARCHAR(3) NOT NULL,
    cars            INT NOT NULL
);

-- Dimensión fecha: describe CUÁNDO ocurrió.
-- year_month (AAAA-MM) evita que el mismo mes de años distintos se mezcle
-- al agrupar por mes.
CREATE TABLE dim_date (
    date_key     INT PRIMARY KEY,
    full_date    DATE NOT NULL UNIQUE,
    year         INT NOT NULL,
    quarter      INT NOT NULL,
    month        INT NOT NULL,
    month_name   VARCHAR(15) NOT NULL,
    year_month   CHAR(7) NOT NULL,
    day          INT NOT NULL,
    day_of_week  INT NOT NULL,
    day_name     VARCHAR(15) NOT NULL
);


/* ----------------------------------------------------------------------------
   Paso 3. Tabla de hechos
   - Clave primaria compuesta (order_number, order_line_number): implementa
     físicamente el grano. Ambas columnas son dimensiones degeneradas: viven
     en la tabla de hechos y no requieren tabla propia.
   - Dos claves foráneas hacia dim_date (order_date_key y ship_date_key):
     dimensión con doble rol. Una sola dim_date responde a "cuándo se pidió"
     y a "cuándo se envió".
   - Medidas: quantity, unit_price, product_cost y sales_amount.
   ---------------------------------------------------------------------------- */
CREATE TABLE fact_sales (
    order_number       VARCHAR(10) NOT NULL,
    order_line_number  INT NOT NULL,
    product_key        INT NOT NULL REFERENCES dim_product (product_key),
    customer_key       INT NOT NULL REFERENCES dim_customer (customer_key),
    order_date_key     INT NOT NULL REFERENCES dim_date (date_key),
    ship_date_key      INT NOT NULL REFERENCES dim_date (date_key),
    quantity           INT NOT NULL,
    unit_price         NUMERIC(10,2) NOT NULL,
    product_cost       NUMERIC(10,2) NOT NULL,
    sales_amount       NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (order_number, order_line_number)
);