-- =========================================================
-- La Tradicional – Boulangerie
-- Data warehouse de ventas y compras (postres y bocadillos de sal)
-- Archivo 01: creación de tablas
-- =========================================================

-- Crear la base datos
-- CREATE DATABASE dw_la_tradicional;

-- =========================================================
-- 1. STAGING (datos crudos)
-- =========================================================

-- Comprobantes electrónicos recibidos del SRI (compras / gastos)
CREATE TABLE raw_compras (
  ruc_emisor                  VARCHAR(13),
  razon_social_emisor         VARCHAR(300),
  tipo_comprobante            VARCHAR(80),
  serie_comprobante           VARCHAR(20),
  clave_acceso                VARCHAR(49),
  fecha_autorizacion          VARCHAR(25),
  fecha_emision               DATE,
  identificacion_receptor     VARCHAR(20),
  valor_sin_impuestos         NUMERIC(12,2),
  iva                         NUMERIC(12,2),
  importe_total               NUMERIC(12,2),
  numero_documento_modificado VARCHAR(20),
  archivo_origen              VARCHAR(200)
);

-- Ventas del sistema contable (detalle por línea de producto)
CREATE TABLE raw_ventas (
  fecha             DATE,
  tipo_registro     VARCHAR(30),
  tipo_documento    VARCHAR(50),
  num_documento     VARCHAR(20),
  autorizacion      VARCHAR(49),
  persona           VARCHAR(200),
  identificacion    VARCHAR(20),
  producto_cuenta   VARCHAR(20),
  cod_producto      VARCHAR(50),
  nombre_producto   VARCHAR(200),
  cat_producto      VARCHAR(100),
  cantidad          NUMERIC(12,2),
  precio            NUMERIC(12,4),
  porc_descuento    NUMERIC(6,2),
  descuento         NUMERIC(12,2),
  subtotal_iva      NUMERIC(12,2),
  subtotal_0        NUMERIC(12,2),
  iva               NUMERIC(12,2),
  total             NUMERIC(12,2),
  saldo             NUMERIC(12,2),
  estado            VARCHAR(30),
  dias_vencimiento  INT,
  fecha_vencimiento DATE,
  forma_pago        VARCHAR(150),
  descripcion       VARCHAR(300)
);


-- =========================================================
-- 2. DIMENSIONES
-- =========================================================

-- Calendario compartido por ventas y compras
CREATE TABLE dim_tiempo (
  fecha      DATE PRIMARY KEY,
  anio       INT,
  mes        INT,
  dia        INT,
  trimestre  INT,
  dia_semana INT            -- 1 = domingo ... 7 = sábado
);

-- Productos: postres y bocadillos de sal
CREATE TABLE dim_producto (
  producto_key    SERIAL PRIMARY KEY,
  cod_producto    VARCHAR(50),
  nombre          VARCHAR(200),   -- nombre tal como viene del sistema
  categoria       VARCHAR(100),   -- categoría del sistema (General / PRINCIPAL)
  nombre_estandar VARCHAR(200),   -- unifica productos con dos códigos
  linea           VARCHAR(50)     -- Postres / Bocadillos de sal
);

-- Clientes
CREATE TABLE dim_cliente (
  cliente_key         SERIAL PRIMARY KEY,
  identificacion      VARCHAR(20),
  nombre              VARCHAR(200),
  tipo_identificacion VARCHAR(20)   -- CEDULA / RUC / CONSUMIDOR FINAL / OTRO
);

-- Proveedores
CREATE TABLE dim_proveedor (
  proveedor_key SERIAL PRIMARY KEY,
  ruc           VARCHAR(13),
  razon_social  VARCHAR(300)
);


-- =========================================================
-- 3. HECHOS
-- =========================================================

-- Las llaves foráneas (REFERENCES) unen cada hecho con su dimensión.
-- Power BI las lee al cargar y crea las relaciones del modelo constelación.

-- Granularidad: una línea de producto dentro de una factura de venta
CREATE TABLE fact_ventas (
  venta_key     SERIAL PRIMARY KEY,
  producto_key  INT  CONSTRAINT fk_ventas_producto REFERENCES dim_producto (producto_key),
  cliente_key   INT  CONSTRAINT fk_ventas_cliente  REFERENCES dim_cliente (cliente_key),
  fecha         DATE CONSTRAINT fk_ventas_tiempo   REFERENCES dim_tiempo (fecha),
  num_documento VARCHAR(20),
  forma_pago    VARCHAR(150),
  estado        VARCHAR(30),
  cantidad      NUMERIC(12,2),
  precio        NUMERIC(12,4),
  descuento     NUMERIC(12,2),
  subtotal_iva  NUMERIC(12,2),
  subtotal_0    NUMERIC(12,2),
  iva           NUMERIC(12,2),
  total         NUMERIC(12,2),
  saldo         NUMERIC(12,2)
);

-- Granularidad: un comprobante recibido (factura)
CREATE TABLE fact_compras (
  compra_key          SERIAL PRIMARY KEY,
  proveedor_key       INT  CONSTRAINT fk_compras_proveedor REFERENCES dim_proveedor (proveedor_key),
  fecha               DATE CONSTRAINT fk_compras_tiempo    REFERENCES dim_tiempo (fecha),
  tipo_comprobante    VARCHAR(80),
  clave_acceso        VARCHAR(49),
  valor_sin_impuestos NUMERIC(12,2),
  iva                 NUMERIC(12,2),
  importe_total       NUMERIC(12,2)
);


-- =========================================================
-- 4. COMPROBACIÓN
-- =========================================================

-- 4.1 Deben aparecer 8 tablas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 4.2 Deben aparecer 5 llaves foráneas (3 en fact_ventas, 2 en fact_compras)
SELECT conname             AS llave,
       conrelid::regclass  AS tabla_hechos,
       confrelid::regclass AS dimension
FROM pg_constraint
WHERE contype = 'f'
ORDER BY 2, 1;
