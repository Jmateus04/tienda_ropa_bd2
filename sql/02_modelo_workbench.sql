-- =====================================================================
-- Proyecto Final Bases de Datos 2 - Tienda de Ropa
-- Archivo : 02_modelo_workbench.sql
-- Autores : Juan Esteban Mateus, Diego Lemus
-- Fecha   : 2026-10-26 23:20
-- Descr.  : Script SOLO para generar el diagrama Crow's Foot en
--           MySQL Workbench (Reverse Engineer). La base real se crea
--           en PostgreSQL con 01_creacion.sql (incluye CHECK, triggers,
--           procedimientos y roles).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS tienda_ropa;
USE tienda_ropa;

-- ---------------------------------------------------------------
-- CATALOGO
-- ---------------------------------------------------------------
CREATE TABLE categoria (
  id_categoria   INT          NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(60)  NOT NULL,
  descripcion    VARCHAR(255) NULL,
  PRIMARY KEY (id_categoria),
  UNIQUE KEY uq_categoria_nombre (nombre)
) ENGINE = InnoDB;

CREATE TABLE producto (
  id_producto    INT           NOT NULL AUTO_INCREMENT,
  id_categoria   INT           NOT NULL,
  nombre         VARCHAR(100)  NOT NULL,
  descripcion    VARCHAR(255)  NULL,
  precio_base    DECIMAL(12,0) NOT NULL,
  activo         BOOLEAN       NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_producto),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
    REFERENCES categoria (id_categoria)
) ENGINE = InnoDB;

CREATE TABLE talla (
  id_talla       INT          NOT NULL AUTO_INCREMENT,
  codigo         VARCHAR(5)   NOT NULL,
  orden          INT          NOT NULL,
  PRIMARY KEY (id_talla),
  UNIQUE KEY uq_talla_codigo (codigo)
) ENGINE = InnoDB;

CREATE TABLE color (
  id_color       INT          NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(40)  NOT NULL,
  PRIMARY KEY (id_color),
  UNIQUE KEY uq_color_nombre (nombre)
) ENGINE = InnoDB;

CREATE TABLE variante_producto (
  id_variante       INT         NOT NULL AUTO_INCREMENT,
  id_producto       INT         NOT NULL,
  id_talla          INT         NOT NULL,
  id_color          INT         NOT NULL,
  sku               VARCHAR(30) NOT NULL,
  stock_disponible  INT         NOT NULL DEFAULT 0,
  stock_averiado    INT         NOT NULL DEFAULT 0,
  stock_minimo      INT         NOT NULL DEFAULT 2,
  PRIMARY KEY (id_variante),
  UNIQUE KEY uq_variante_sku (sku),
  UNIQUE KEY uq_variante_combinacion (id_producto, id_talla, id_color),
  CONSTRAINT fk_variante_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto),
  CONSTRAINT fk_variante_talla    FOREIGN KEY (id_talla)    REFERENCES talla (id_talla),
  CONSTRAINT fk_variante_color    FOREIGN KEY (id_color)    REFERENCES color (id_color)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------
-- PROVEEDORES
-- ---------------------------------------------------------------
CREATE TABLE proveedor (
  id_proveedor   INT          NOT NULL AUTO_INCREMENT,
  nit            VARCHAR(20)  NOT NULL,
  razon_social   VARCHAR(120) NOT NULL,
  email          VARCHAR(120) NULL,
  PRIMARY KEY (id_proveedor),
  UNIQUE KEY uq_proveedor_nit (nit)
) ENGINE = InnoDB;

-- Atributo multivalor "telefonos" del modelo Chen -> tabla propia (1FN)
CREATE TABLE telefono_proveedor (
  id_proveedor   INT          NOT NULL,
  telefono       VARCHAR(20)  NOT NULL,
  PRIMARY KEY (id_proveedor, telefono),
  CONSTRAINT fk_telefono_proveedor FOREIGN KEY (id_proveedor)
    REFERENCES proveedor (id_proveedor)
) ENGINE = InnoDB;

-- Relacion N:M "suministra" con su atributo costo
CREATE TABLE producto_proveedor (
  id_producto    INT           NOT NULL,
  id_proveedor   INT           NOT NULL,
  costo          DECIMAL(12,0) NOT NULL,
  PRIMARY KEY (id_producto, id_proveedor),
  CONSTRAINT fk_pp_producto  FOREIGN KEY (id_producto)  REFERENCES producto (id_producto),
  CONSTRAINT fk_pp_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------
-- CLIENTES Y FIDELIZACION
-- ---------------------------------------------------------------
CREATE TABLE nivel_fidelidad (
  id_nivel             INT           NOT NULL AUTO_INCREMENT,
  nombre               VARCHAR(20)   NOT NULL,
  compra_minima_anual  DECIMAL(12,0) NOT NULL,
  pct_cumpleanos       DECIMAL(5,2)  NOT NULL,
  PRIMARY KEY (id_nivel),
  UNIQUE KEY uq_nivel_nombre (nombre)
) ENGINE = InnoDB;

-- Atributo compuesto nombre_completo -> nombres + apellidos
-- Atributo derivado edad -> no se almacena (se calcula con fecha_nacimiento)
CREATE TABLE cliente (
  id_cliente        INT          NOT NULL AUTO_INCREMENT,
  tipo_documento    VARCHAR(2)   NOT NULL,
  documento         VARCHAR(20)  NOT NULL,
  nombres           VARCHAR(60)  NOT NULL,
  apellidos         VARCHAR(60)  NOT NULL,
  email             VARCHAR(120) NULL,
  fecha_nacimiento  DATE         NOT NULL,
  PRIMARY KEY (id_cliente),
  UNIQUE KEY uq_cliente_documento (documento),
  UNIQUE KEY uq_cliente_email (email)
) ENGINE = InnoDB;

-- Entidad debil: su PK es la misma del cliente (relacion 1:1 identificadora)
CREATE TABLE cuenta_fidelidad (
  id_cliente           INT           NOT NULL,
  id_nivel             INT           NOT NULL,
  total_comprado_12m   DECIMAL(14,0) NOT NULL DEFAULT 0,
  fecha_actualizacion  DATETIME      NOT NULL,
  PRIMARY KEY (id_cliente),
  CONSTRAINT fk_cuenta_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
  CONSTRAINT fk_cuenta_nivel   FOREIGN KEY (id_nivel)   REFERENCES nivel_fidelidad (id_nivel)
) ENGINE = InnoDB;

CREATE TABLE promocion (
  id_promocion   INT           NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(80)   NOT NULL,
  monto_minimo   DECIMAL(12,0) NOT NULL,
  valor_bono     DECIMAL(12,0) NOT NULL,
  fecha_inicio   DATE          NOT NULL,
  fecha_fin      DATE          NOT NULL,
  activa         BOOLEAN       NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_promocion)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------
-- VENTAS
-- ---------------------------------------------------------------
CREATE TABLE empleado (
  id_empleado    INT          NOT NULL AUTO_INCREMENT,
  documento      VARCHAR(20)  NOT NULL,
  nombres        VARCHAR(100) NOT NULL,
  cargo          VARCHAR(20)  NOT NULL,
  activo         BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_empleado),
  UNIQUE KEY uq_empleado_documento (documento)
) ENGINE = InnoDB;

CREATE TABLE venta (
  id_venta        INT           NOT NULL AUTO_INCREMENT,
  fecha           DATETIME      NOT NULL,
  id_cliente      INT           NULL,      -- NULL = cliente ocasional
  id_empleado     INT           NOT NULL,
  id_promocion    INT           NULL,      -- solo si se aplico un bono
  subtotal        DECIMAL(12,0) NOT NULL,
  descuento       DECIMAL(12,0) NOT NULL DEFAULT 0,
  total           DECIMAL(12,0) NOT NULL,
  tipo_descuento  VARCHAR(12)   NOT NULL DEFAULT 'NINGUNO',
  estado          VARCHAR(10)   NOT NULL DEFAULT 'ACTIVA',
  PRIMARY KEY (id_venta),
  CONSTRAINT fk_venta_cliente   FOREIGN KEY (id_cliente)   REFERENCES cliente (id_cliente),
  CONSTRAINT fk_venta_empleado  FOREIGN KEY (id_empleado)  REFERENCES empleado (id_empleado),
  CONSTRAINT fk_venta_promocion FOREIGN KEY (id_promocion) REFERENCES promocion (id_promocion)
) ENGINE = InnoDB;

-- Relacion N:M "incluye" con sus atributos cantidad y precio_unitario
CREATE TABLE detalle_venta (
  id_venta         INT           NOT NULL,
  id_variante      INT           NOT NULL,
  cantidad         INT           NOT NULL,
  precio_unitario  DECIMAL(12,0) NOT NULL,
  PRIMARY KEY (id_venta, id_variante),
  CONSTRAINT fk_detalle_venta    FOREIGN KEY (id_venta)    REFERENCES venta (id_venta),
  CONSTRAINT fk_detalle_variante FOREIGN KEY (id_variante) REFERENCES variante_producto (id_variante)
) ENGINE = InnoDB;

CREATE TABLE pago (
  id_pago        INT           NOT NULL AUTO_INCREMENT,
  id_venta       INT           NOT NULL,
  metodo         VARCHAR(15)   NOT NULL,
  valor          DECIMAL(12,0) NOT NULL,
  fecha          DATETIME      NOT NULL,
  PRIMARY KEY (id_pago),
  CONSTRAINT fk_pago_venta FOREIGN KEY (id_venta) REFERENCES venta (id_venta)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------
-- INVENTARIO
-- ---------------------------------------------------------------
CREATE TABLE movimiento_inventario (
  id_movimiento  INT          NOT NULL AUTO_INCREMENT,
  id_variante    INT          NOT NULL,
  tipo           VARCHAR(12)  NOT NULL,
  cantidad       INT          NOT NULL,
  motivo         VARCHAR(150) NULL,
  fecha          DATETIME     NOT NULL,
  PRIMARY KEY (id_movimiento),
  CONSTRAINT fk_movimiento_variante FOREIGN KEY (id_variante)
    REFERENCES variante_producto (id_variante)
) ENGINE = InnoDB;
