/* ----------------------------------------------------------------------------
   Paso 1. Tabla de staging
   Copia fiel de la estructura del CSV, sin restricciones (sin NOT NULL ni
   PRIMARY KEY), para ver los datos tal como vienen de la fuente y limpiarlos
   antes de integrarlos al modelo. pgAdmin importa por POSICIÓN, por lo que el
   orden de las columnas debe coincidir con el del CSV.
   ---------------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg_products;

CREATE TABLE stg_products (
    product_id      VARCHAR(5),
    product_name    VARCHAR(150),
    category        VARCHAR(80),
    subcategory     VARCHAR(80)
);

-- Debe devolver 0 filas y mostrar las 4 columnas.
SELECT * FROM stg_products LIMIT 10;


/* ----------------------------------------------------------------------------
   PASO MANUAL (no es SQL): importar products.csv a stg_products
   Clic derecho sobre stg_products > Import/Export Data
     - Import | Formato: CSV | Encoding: UTF8
     - Header: ON | Delimiter: , (coma)
   ---------------------------------------------------------------------------- */


/* ----------------------------------------------------------------------------
   Paso 2. Validación de la importación
   Control: 699 registros, 699 IDs únicos, 10 categorías y 53 subcategorías.
   ---------------------------------------------------------------------------- */
SELECT COUNT(*) AS total_registros FROM stg_products;

SELECT COUNT(DISTINCT product_id) AS productos_unicos FROM stg_products;

SELECT COUNT(DISTINCT category) AS categorias,
       COUNT(DISTINCT subcategory) AS subcategorias
FROM stg_products;


/* ----------------------------------------------------------------------------
   Paso 3. Detección de nombres con espacios repetidos o tabulaciones
   Evidencia "antes" de la limpieza. Anotar cuántos registros salen.
   ---------------------------------------------------------------------------- */
SELECT product_id, product_name
FROM stg_products
WHERE product_name ~ '\s{2,}' OR product_name ~ '\t'
LIMIT 10;

SELECT COUNT(*) AS nombres_con_espacios_raros
FROM stg_products
WHERE product_name ~ '\s{2,}' OR product_name ~ '\t';


/* ----------------------------------------------------------------------------
   Paso 4. Limpieza sobre staging (el archivo fuente no se modifica)
   btrim          : quita espacios al inicio y al final.
   regexp_replace : con la bandera 'g' reemplaza, en todo el texto, cualquier
                    grupo de espacios o tabulaciones por un solo espacio.
   Se aplica también a category y subcategory para que 'Beauty & Hygiene ' y
   'Beauty & Hygiene' no cuenten como categorías distintas.
   Control: repetir la consulta del Paso 3; debe devolver 0.
   ---------------------------------------------------------------------------- */
UPDATE stg_products
SET product_name = regexp_replace(btrim(product_name), '\s+', ' ', 'g'),
    category     = btrim(category),
    subcategory  = btrim(subcategory);


/* ----------------------------------------------------------------------------
   Paso 5. Dimensión dim_product (versión de la parte guiada)
   product_key : clave sustituta generada por el propio Data Warehouse.
   product_id  : clave natural del sistema fuente, se conserva con UNIQUE.
   category y subcategory se mantienen dentro de la dimensión (desnormalizada),
   lo que reduce los JOIN en las consultas analíticas (esquema estrella, no
   copo de nieve).
   ---------------------------------------------------------------------------- */
DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product (
    product_key  BIGSERIAL PRIMARY KEY,
    product_id   VARCHAR(5) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(80) NOT NULL,
    subcategory  VARCHAR(80) NOT NULL
);

-- product_key no se incluye en el INSERT: PostgreSQL lo asigna (1, 2, 3...).
INSERT INTO dim_product
    (product_id, product_name, category, subcategory)
SELECT DISTINCT
    product_id,
    product_name,
    category,
    subcategory
FROM stg_products
ORDER BY product_id;

-- Control: 699 filas, con product_key de 1 a 699.
SELECT COUNT(*) AS total_dim_product FROM dim_product;

SELECT * FROM dim_product ORDER BY product_key LIMIT 20;


/* ----------------------------------------------------------------------------
   Paso 6. Consultas de análisis sobre dim_product
   Comprueban que los atributos de la dimensión permiten agrupar y filtrar
   sin ningún JOIN.
   ---------------------------------------------------------------------------- */

-- 6.1 Productos por categoría. Control: 10 filas; la suma de total_productos es 699.
SELECT category,
       COUNT(*) AS total_productos
FROM dim_product
GROUP BY category
ORDER BY total_productos DESC;

-- 6.2 Productos por subcategoría. Control: 53 filas.
SELECT subcategory,
       COUNT(*) AS total_productos
FROM dim_product
GROUP BY subcategory
ORDER BY total_productos DESC;

-- 6.3 Productos de la categoría 'Beauty & Hygiene'.
SELECT product_id, product_name, subcategory
FROM dim_product
WHERE category = 'Beauty & Hygiene'
ORDER BY product_name;

-- 6.4 Productos de la subcategoría 'Biscuits & Cookies'.
SELECT product_id, product_name, category
FROM dim_product
WHERE subcategory = 'Biscuits & Cookies'
ORDER BY product_name;

-- 6.5 Subcategorías por categoría. COUNT(DISTINCT) porque una subcategoría se
--     repite en muchos productos y solo debe contarse una vez por categoría.
SELECT category,
       COUNT(DISTINCT subcategory) AS total_subcategorias
FROM dim_product
GROUP BY category
ORDER BY total_subcategorias DESC, category;