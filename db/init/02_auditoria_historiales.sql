-- ============================================================
-- TABLAS DE AUDITORIA E HISTORIALES (capa 3 del modelo navegacional)
-- Las llenan los triggers / procedimientos que agregues despues:
--   AUDITORIA_RECOLECCION              <- trg_auditar_recoleccion
--   HISTORIAL_PRECIO_MATERIAL          <- trg_validar_precio_material
--   HISTORIAL_ASIGNACION_RECOLECTOR    <- p_reasignar_recolector_transporte
-- No llevan FOREIGN KEY a proposito: un registro de auditoria debe
-- sobrevivir aunque se borre la fila original (ej. p_eliminar_zona_segura).
-- ============================================================
USE empresa_recolectora;
SET NAMES utf8mb4;

DROP TABLE IF EXISTS HISTORIAL_ASIGNACION_RECOLECTOR;
DROP TABLE IF EXISTS HISTORIAL_PRECIO_MATERIAL;
DROP TABLE IF EXISTS AUDITORIA_RECOLECCION;

-- Quien hizo que sobre RECOLECTA (accion, zona, usuario, hora)
CREATE TABLE AUDITORIA_RECOLECCION (
    idAuditoria       BIGINT AUTO_INCREMENT PRIMARY KEY,
    accion            VARCHAR(10)  NOT NULL CHECK (accion IN ('INSERT', 'UPDATE', 'DELETE')),
    idrecolector      INT          NOT NULL,
    idContenedor      INT          NOT NULL,
    fecha_recoleccion DATE         NOT NULL,
    idZona            INT          NULL,
    detalle           VARCHAR(255) NULL,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fecha_hora        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_aud_fecha (fecha_hora),
    INDEX idx_aud_recolector (idrecolector),
    INDEX idx_aud_zona (idZona)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Cada cambio de precio de un material (base para "precio vigente")
CREATE TABLE HISTORIAL_PRECIO_MATERIAL (
    idHistorial     BIGINT AUTO_INCREMENT PRIMARY KEY,
    idMaterial      INT           NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL CHECK (precio_anterior >= 0),
    precio_nuevo    DECIMAL(10,2) NOT NULL CHECK (precio_nuevo >= 0),
    variacion_pct   DECIMAL(8,2)  GENERATED ALWAYS AS (
                        IF(precio_anterior = 0, NULL,
                           ROUND((precio_nuevo - precio_anterior) / precio_anterior * 100, 2))
                    ) STORED,
    usuario         VARCHAR(100)  NOT NULL DEFAULT (CURRENT_USER()),
    fecha_cambio    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_hpm_material_fecha (idMaterial, fecha_cambio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Cada vez que un recolector cambia de transporte
CREATE TABLE HISTORIAL_ASIGNACION_RECOLECTOR (
    idHistorial           BIGINT AUTO_INCREMENT PRIMARY KEY,
    idrecolector          INT          NOT NULL,
    idTransporte_anterior INT          NULL,
    idTransporte_nuevo    INT          NOT NULL,
    motivo                VARCHAR(255) NULL,
    usuario               VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fecha_cambio          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_har_recolector_fecha (idrecolector, fecha_cambio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
