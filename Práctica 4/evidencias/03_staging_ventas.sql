/* ----------------------------------------------------------------------------
   Paso 1. Tabla de staging
   Las 26 columnas del CSV, en el MISMO ORDEN (pgAdmin importa por posición) y
   con nombres en snake_case, porque los encabezados originales traen espacios
   (por ejemplo "Product Code", "Order Date").
   ---------------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg_ventas;

CREATE TABLE stg_ventas (
    product_key        INT,
    product_code       VARCHAR(10),
    product_name       VARCHAR(100),
    list_price         NUMERIC(10,2),
    color              VARCHAR(30),
    size               VARCHAR(20),
    category           VARCHAR(50),
    subcategory        VARCHAR(50),
    customer_key       INT,
    birth_date         DATE,
    marital_status     VARCHAR(20),
    gender             CHAR(1),
    income             NUMERIC(12,2),
    children           INT,
    home_owner         VARCHAR(3),
    cars               INT,
    order_date_key     INT,
    order_date         DATE,
    ship_date_key      INT,
    ship_date          DATE,
    order_number       VARCHAR(10),
    order_line_number  INT,
    quantity           INT,
    unit_price         NUMERIC(10,2),
    product_cost       NUMERIC(10,2),
    sales_amount       NUMERIC(12,2)
);


/* ----------------------------------------------------------------------------
   PASO MANUAL (no es SQL): importar el CSV a stg_ventas
   Clic derecho sobre stg_ventas > Import/Export Data
     - Import | Formato: CSV | Encoding: UTF8
     - Header: ON
     - Delimiter: ;  (punto y coma; products.csv usaba coma)
   ---------------------------------------------------------------------------- */


/* ----------------------------------------------------------------------------
   Paso 2. Validación de la importación
   Control: 100 filas, 100 pedidos únicos, 9 productos, 10 clientes,
            2 categorías y 6 subcategorías.
   ---------------------------------------------------------------------------- */
SELECT COUNT(*) AS total_filas,
       COUNT(DISTINCT order_number) AS pedidos_unicos,
       COUNT(DISTINCT product_key) AS productos,
       COUNT(DISTINCT customer_key) AS clientes,
       COUNT(DISTINCT category) AS categorias,
       COUNT(DISTINCT subcategory) AS subcategorias
FROM stg_ventas;

-- Control de calidad: el monto de cada venta debe ser cantidad x precio unitario.
-- Control: 0 ventas inconsistentes.
SELECT COUNT(*) AS ventas_inconsistentes
FROM stg_ventas
WHERE sales_amount <> quantity * unit_price;


/* ----------------------------------------------------------------------------
   Paso 3. Estandarización de textos sobre staging
   El archivo no presentó problemas de calidad, pero se aplica la misma limpieza
   de la parte guiada (btrim y regexp_replace) como buena práctica y para dejar
   evidencia del paso de limpieza en el proceso.
   ---------------------------------------------------------------------------- */
UPDATE stg_ventas
SET product_code   = btrim(product_code),
    product_name   = regexp_replace(btrim(product_name), '\s+', ' ', 'g'),
    color          = btrim(color),
    size           = btrim(size),
    category       = btrim(category),
    subcategory    = btrim(subcategory),
    marital_status = btrim(marital_status),
    gender         = btrim(gender),
    home_owner     = btrim(home_owner),
    order_number   = btrim(order_number);