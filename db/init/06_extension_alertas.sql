-- =====================================================================
-- 06_extension_alertas.sql
-- Tablas nuevas (alertas, presupuesto, cierre de jornada, auditoria) y las
-- funciones/procedimientos auxiliares que usan los triggers (07) y cursores (08).
-- Se instala DESPUES de 05. Todo es idempotente (IF NOT EXISTS / DROP IF EXISTS):
-- se puede volver a ejecutar sin perder alertas ni presupuestos.
-- =====================================================================
USE empresa_recolectora;
SET NAMES utf8mb4;

-- 3. Tablas nuevas para triggers y cursores
-- ------------------------------------------------------------
-- Alertas que escriben los triggers (y p_aux_registrar_alerta). El frontend las consulta.
-- Sin FOREIGN KEY: una alerta debe sobrevivir aunque se borre lo que la origino.
CREATE TABLE IF NOT EXISTS ALERTA_SISTEMA (
    idAlerta     BIGINT AUTO_INCREMENT PRIMARY KEY,
    tipo         VARCHAR(30)  NOT NULL,          -- BOTADERO, PRESUPUESTO, TRANSPORTE, ZONA, REUBICACION
    idReferencia INT          NULL,              -- id del botadero / transporte / zona segun el tipo
    nivel        VARCHAR(15)  NOT NULL DEFAULT 'INFO'
                 CHECK (nivel IN ('INFO', 'ADVERTENCIA', 'CRITICO')),
    mensaje      VARCHAR(255) NOT NULL,
    leida        TINYINT(1)   NOT NULL DEFAULT 0,
    fecha_hora   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_alerta_pendientes (leida, idAlerta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Presupuesto mensual de compra de materiales (lo define el usuario desde la pantalla).
CREATE TABLE IF NOT EXISTS PRESUPUESTO_MATERIAL (
    anio           INT           NOT NULL CHECK (anio BETWEEN 2000 AND 2100),
    mes            INT           NOT NULL CHECK (mes BETWEEN 1 AND 12),
    monto          DECIMAL(14,2) NOT NULL CHECK (monto >= 0),
    usuario        VARCHAR(100)  NOT NULL DEFAULT (CURRENT_USER()),
    fecha_registro DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (anio, mes)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Cierre de jornada (zona + fecha). Una jornada cerrada ya no admite cambios en RECOLECTA.
-- Si p_cerrar_jornada_recoleccion usa otras columnas, ajustar solo f_jornada_cerrada (mas abajo).
CREATE TABLE IF NOT EXISTS CIERRE_JORNADA (
    idCierre               INT AUTO_INCREMENT PRIMARY KEY,
    idZona                 INT           NOT NULL,
    fecha                  DATE          NOT NULL,
    total_recolecciones    INT           NOT NULL DEFAULT 0,
    total_kg               DECIMAL(12,2) NOT NULL DEFAULT 0,
    contenedores_atendidos INT           NOT NULL DEFAULT 0,
    cobertura_pct          DECIMAL(5,2)  NULL,
    resumen                VARCHAR(500)  NULL,
    usuario                VARCHAR(100)  NOT NULL DEFAULT (CURRENT_USER()),
    fecha_cierre           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_cierre_zona_fecha (idZona, fecha),
    CONSTRAINT fk_cierre_zona FOREIGN KEY (idZona) REFERENCES ZONA(idZona)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS AUDITORIA_RECOLECCION (
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

-- Presupuesto de ejemplo para el mes con compras mas recientes de los datos (julio 2026)
INSERT IGNORE INTO PRESUPUESTO_MATERIAL (anio, mes, monto)
SELECT 2026, 7, ROUND(COALESCE(SUM(total),0) + 300, 2) FROM COMPRA_MATERIAL
 WHERE fecha BETWEEN '2026-07-01' AND '2026-07-31';

DELIMITER $$

-- ------------------------------------------------------------
-- f_nivel_ocupacion: clasifica la ocupacion de un botadero.
-- Mismos umbrales que f_analisis_capacidad_botadero de 02_funciones.sql:
--   >=100 SATURADO | >=90 CRITICO | >=70 ADVERTENCIA | resto DISPONIBLE
-- Recibe los kg (no el id) para poder usarla con OLD.* y NEW.* dentro de un trigger.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS f_nivel_ocupacion$$
CREATE FUNCTION f_nivel_ocupacion(p_usada DECIMAL(15,2), p_max DECIMAL(15,2))
RETURNS VARCHAR(15)
DETERMINISTIC
BEGIN
    DECLARE v_pct DECIMAL(9,2);

    IF p_max IS NULL OR p_max <= 0 OR p_usada IS NULL THEN
        RETURN 'SIN CAPACIDAD';
    END IF;

    SET v_pct = 100 * p_usada / p_max;

    IF v_pct >= 100 THEN RETURN 'SATURADO'; END IF;
    IF v_pct >= 90  THEN RETURN 'CRITICO'; END IF;
    IF v_pct >= 70  THEN RETURN 'ADVERTENCIA'; END IF;
    RETURN 'DISPONIBLE';
END$$

-- ------------------------------------------------------------
-- f_jornada_cerrada: 1 si la zona ya cerro su jornada en esa fecha.
-- Es la UNICA funcion que conoce las columnas de CIERRE_JORNADA.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS f_jornada_cerrada$$
CREATE FUNCTION f_jornada_cerrada(p_idZona INT, p_fecha DATE)
RETURNS TINYINT
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_cierres INT DEFAULT 0;

    SELECT COUNT(*) INTO v_cierres
      FROM CIERRE_JORNADA
     WHERE idZona = p_idZona AND fecha = p_fecha;

    RETURN IF(v_cierres > 0, 1, 0);
END$$

-- ------------------------------------------------------------
-- f_jornada_cerrada_contenedor: devuelve el idZona si la jornada del contenedor
-- (zona de su via) esta cerrada en esa fecha; 0 si esta abierta.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS f_jornada_cerrada_contenedor$$
CREATE FUNCTION f_jornada_cerrada_contenedor(p_idContenedor INT, p_fecha DATE)
RETURNS INT
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_zona INT DEFAULT NULL;

    SELECT v.idZona INTO v_zona
      FROM CONTENEDOR c JOIN VIA v ON v.idVia = c.idVia
     WHERE c.idContenedor = p_idContenedor;

    IF v_zona IS NOT NULL AND f_jornada_cerrada(v_zona, p_fecha) = 1 THEN
        RETURN v_zona;
    END IF;
    RETURN 0;
END$$

-- ------------------------------------------------------------
-- f_gasto_materiales_periodo: total comprado (COMPRA_MATERIAL) entre dos fechas.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS f_gasto_materiales_periodo$$
CREATE FUNCTION f_gasto_materiales_periodo(p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(14,2)
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(14,2) DEFAULT 0;

    SELECT COALESCE(SUM(total), 0) INTO v_total
      FROM COMPRA_MATERIAL
     WHERE fecha BETWEEN p_desde AND p_hasta;

    RETURN v_total;
END$$

-- ------------------------------------------------------------
-- f_saldo_presupuesto: presupuesto del mes menos lo gastado.
-- NULL si no hay presupuesto definido para ese mes. Negativo = excedido.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS f_saldo_presupuesto$$
CREATE FUNCTION f_saldo_presupuesto(p_anio INT, p_mes INT)
RETURNS DECIMAL(14,2)
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_monto  DECIMAL(14,2) DEFAULT NULL;
    DECLARE v_inicio DATE;

    SELECT pm.monto INTO v_monto
      FROM PRESUPUESTO_MATERIAL pm
     WHERE pm.anio = p_anio AND pm.mes = p_mes;

    IF v_monto IS NULL THEN
        RETURN NULL;
    END IF;

    SET v_inicio = STR_TO_DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01'), '%Y-%m-%d');
    RETURN v_monto - f_gasto_materiales_periodo(v_inicio, LAST_DAY(v_inicio));
END$$

-- ------------------------------------------------------------
-- p_aux_registrar_alerta: inserta en ALERTA_SISTEMA sin repetir.
-- Si ya existe una alerta NO LEIDA igual (mismo tipo, referencia y mensaje) no hace nada.
-- Sin transaccion ni resultados: por eso un trigger puede llamarla.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS p_aux_registrar_alerta$$
CREATE PROCEDURE p_aux_registrar_alerta(
    IN p_tipo    VARCHAR(30),
    IN p_ref     INT,
    IN p_nivel   VARCHAR(15),
    IN p_mensaje VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ALERTA_SISTEMA
                    WHERE tipo = p_tipo
                      AND idReferencia <=> p_ref
                      AND mensaje = p_mensaje
                      AND leida = 0) THEN
        INSERT INTO ALERTA_SISTEMA (tipo, idReferencia, nivel, mensaje)
        VALUES (p_tipo, p_ref, p_nivel, p_mensaje);
    END IF;
END$$

-- ------------------------------------------------------------
-- p_definir_presupuesto_material: el usuario escribe el monto del mes.
-- Crea o actualiza el presupuesto y responde cuanto lleva gastado y cuanto queda.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS p_definir_presupuesto_material$$
CREATE PROCEDURE p_definir_presupuesto_material(
    IN p_anio  INT,
    IN p_mes   INT,
    IN p_monto DECIMAL(14,2)
)
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_gasto  DECIMAL(14,2);
    DECLARE v_saldo  DECIMAL(14,2);
    DECLARE v_estado VARCHAR(30);
    DECLARE v_mensaje VARCHAR(200);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_anio IS NULL OR p_anio NOT BETWEEN 2000 AND 2100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El anio debe estar entre 2000 y 2100';
    END IF;
    IF p_mes IS NULL OR p_mes NOT BETWEEN 1 AND 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El mes debe estar entre 1 y 12';
    END IF;
    IF p_monto IS NULL OR p_monto < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto del presupuesto no puede ser negativo';
    END IF;

    START TRANSACTION;

    IF EXISTS (SELECT 1 FROM PRESUPUESTO_MATERIAL WHERE anio = p_anio AND mes = p_mes) THEN
        UPDATE PRESUPUESTO_MATERIAL
           SET monto = p_monto, usuario = CURRENT_USER(), fecha_registro = NOW()
         WHERE anio = p_anio AND mes = p_mes;
    ELSE
        INSERT INTO PRESUPUESTO_MATERIAL (anio, mes, monto) VALUES (p_anio, p_mes, p_monto);
    END IF;

    COMMIT;

    SET v_inicio = STR_TO_DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01'), '%Y-%m-%d');
    SET v_gasto  = f_gasto_materiales_periodo(v_inicio, LAST_DAY(v_inicio));
    SET v_saldo  = p_monto - v_gasto;

    IF v_saldo < 0 THEN
        SET v_estado  = 'EXCEDIDO';
        SET v_mensaje = CONCAT('Presupuesto definido, pero ya se excedio en Bs ', ABS(v_saldo));
    ELSE
        SET v_estado  = 'DENTRO DEL PRESUPUESTO';
        SET v_mensaje = CONCAT('Presupuesto definido: quedan Bs ', v_saldo, ' para comprar materiales');
    END IF;

    SELECT 'PRESUPUESTO DEFINIDO' AS resultado,
           p_anio  AS anio,
           p_mes   AS mes,
           p_monto AS presupuesto_bs,
           v_gasto AS gastado_bs,
           v_saldo AS saldo_bs,
           v_estado AS estado,
           v_mensaje AS mensaje;
END$$

DELIMITER ;
