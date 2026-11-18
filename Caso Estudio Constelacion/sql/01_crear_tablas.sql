-- =========================================================
-- HAPPYTECH - Esquema Constelación (Pedidos + Soporte técnico)
-- PostgreSQL - Creación de tablas (la carga se hace con Pentaho)
-- =========================================================

-- ---------- DIMENSIONES COMPARTIDAS ----------
CREATE TABLE dim_tiempo (
    id_tiempo     INT PRIMARY KEY,          -- formato AAAAMMDD
    fecha         DATE NOT NULL UNIQUE,
    dia           SMALLINT NOT NULL,
    nombre_dia    VARCHAR(15) NOT NULL,
    semana        SMALLINT NOT NULL,
    mes           SMALLINT NOT NULL,
    nombre_mes    VARCHAR(15) NOT NULL,
    trimestre     SMALLINT NOT NULL,
    anio          SMALLINT NOT NULL
);

CREATE TABLE dim_producto (
    id_producto   SERIAL PRIMARY KEY,
    producto      VARCHAR(60) NOT NULL UNIQUE,
    categoria     VARCHAR(40) NOT NULL,
    marca         VARCHAR(40) NOT NULL
);

CREATE TABLE dim_cliente (
    id_cliente    SERIAL PRIMARY KEY,
    cliente       VARCHAR(60) NOT NULL UNIQUE,
    ciudad        VARCHAR(40) NOT NULL,
    region        VARCHAR(20) NOT NULL
);

-- ---------- DIMENSIÓN PROPIA DE SOPORTE ----------
CREATE TABLE dim_motivo (
    id_motivo     SERIAL PRIMARY KEY,
    motivo        VARCHAR(60) NOT NULL UNIQUE
);

-- ---------- TABLAS DE HECHOS ----------
CREATE TABLE fact_pedidos (
    id_pedido     SERIAL PRIMARY KEY,
    id_tiempo     INT NOT NULL REFERENCES dim_tiempo(id_tiempo),
    id_producto   INT NOT NULL REFERENCES dim_producto(id_producto),
    id_cliente    INT NOT NULL REFERENCES dim_cliente(id_cliente),
    cantidad      INT NOT NULL CHECK (cantidad > 0),
    total_pedido  NUMERIC(12,2) NOT NULL CHECK (total_pedido >= 0)
);

CREATE TABLE fact_soporte (
    id_soporte              SERIAL PRIMARY KEY,
    ticket_id               INT NOT NULL,   -- dimensión degenerada (en el origen no es única)
    id_tiempo               INT NOT NULL REFERENCES dim_tiempo(id_tiempo),
    id_producto             INT NOT NULL REFERENCES dim_producto(id_producto),
    id_cliente              INT NOT NULL REFERENCES dim_cliente(id_cliente),
    id_motivo               INT NOT NULL REFERENCES dim_motivo(id_motivo),
    tiempo_respuesta_horas  INT NOT NULL CHECK (tiempo_respuesta_horas >= 0),
    cantidad_tickets        INT NOT NULL DEFAULT 1
);

CREATE INDEX ix_fp_tiempo ON fact_pedidos(id_tiempo);
CREATE INDEX ix_fp_producto ON fact_pedidos(id_producto);
CREATE INDEX ix_fp_cliente ON fact_pedidos(id_cliente);
CREATE INDEX ix_fs_tiempo ON fact_soporte(id_tiempo);
CREATE INDEX ix_fs_producto ON fact_soporte(id_producto);
CREATE INDEX ix_fs_cliente ON fact_soporte(id_cliente);
CREATE INDEX ix_fs_motivo ON fact_soporte(id_motivo);
