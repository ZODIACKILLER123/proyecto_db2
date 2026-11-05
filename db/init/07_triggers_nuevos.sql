-- ============================================================
-- TRIGGERS NUEVOS (5 triggers, 7 objetos en MySQL)
--   T1 fácil     trg_validar_capacidad_botadero      BEFORE UPDATE  BOTADERO
--   T2 regular   trg_alerta_ocupacion_botadero       AFTER  UPDATE  BOTADERO
--   T3 regular   trg_control_presupuesto_material    BEFORE INSERT  COMPRA_MATERIAL
--                trg_alerta_presupuesto_material     AFTER  INSERT  COMPRA_MATERIAL
--   T4 complejo  trg_control_operativo_recoleccion   AFTER  INSERT  RECOLECTA
--   T5 fácil     trg_bloquear_jornada_cerrada(_bu/_bd) BEFORE INSERT/UPDATE/DELETE RECOLECTA
--
-- REGLA (04 y 03 ya lo hacen): ningun trigger modifica stock, carga del transporte ni capacidad del
-- botadero (eso lo hacen sus procedimientos). Estos triggers solo VALIDAN, ALERTAN o AUDITAN.
--
-- Dos formas de "avisar" al usuario:
--   * SIGNAL  -> bloquea la operacion; llega al frontend como error 400 (ventana de rechazo).
--   * ALERTA_SISTEMA -> aviso que NO bloquea; el frontend lo muestra en el panel de alertas.
--     (Una alerta no puede escribirse en el mismo trigger que hace SIGNAL: el SIGNAL deshace todo.)
-- ============================================================
USE empresa_recolectora;
SET NAMES utf8mb4;

DELIMITER $$

-- Reemplazado por trg_control_operativo_recoleccion (si la BD ya existia sin reiniciar el volumen)
DROP TRIGGER IF EXISTS trg_auditar_recoleccion$$

-- ------------------------------------------------------------
-- T1 (FACIL) Un botadero no puede pasar de su capacidad maxima.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validar_capacidad_botadero$$
CREATE TRIGGER trg_validar_capacidad_botadero
BEFORE UPDATE ON BOTADERO
FOR EACH ROW
BEGIN
    DECLARE v_msg   VARCHAR(128);
    DECLARE v_nivel VARCHAR(15);

    IF NEW.capacidad_utilizada < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La capacidad utilizada del botadero no puede ser negativa';
    END IF;

    IF NEW.capacidad_utilizada > NEW.capacidad_maxima_kg THEN
        SET v_msg = LEFT(CONCAT('Botadero lleno: ', NEW.nombre, ' excede su capacidad maxima en ',
                                ROUND(NEW.capacidad_utilizada - NEW.capacidad_maxima_kg, 2), ' kg'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    -- Funcion dentro del trigger: deja el estado del botadero siempre coherente.
    SET v_nivel = f_nivel_ocupacion(NEW.capacidad_utilizada, NEW.capacidad_maxima_kg);
    SET NEW.estado_operativo = CONCAT(UPPER(LEFT(v_nivel, 1)), LOWER(SUBSTRING(v_nivel, 2)));
END$$

-- ------------------------------------------------------------
-- T2 (REGULAR) Alerta cuando el botadero SUBE de nivel de ocupacion.
-- Compara el nivel antes (OLD) y despues (NEW); solo avisa si empeora, para no repetir avisos.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_alerta_ocupacion_botadero$$
CREATE TRIGGER trg_alerta_ocupacion_botadero
AFTER UPDATE ON BOTADERO
FOR EACH ROW
BEGIN
    DECLARE v_antes   VARCHAR(15);
    DECLARE v_despues VARCHAR(15);
    DECLARE v_pct     DECIMAL(7,2);
    DECLARE v_texto   VARCHAR(255);

    IF NEW.capacidad_utilizada <> OLD.capacidad_utilizada
       OR NEW.capacidad_maxima_kg <> OLD.capacidad_maxima_kg THEN

        SET v_antes   = f_nivel_ocupacion(OLD.capacidad_utilizada, OLD.capacidad_maxima_kg);
        SET v_despues = f_nivel_ocupacion(NEW.capacidad_utilizada, NEW.capacidad_maxima_kg);

        IF v_despues <> 'DISPONIBLE'
           AND FIELD(v_despues, 'DISPONIBLE', 'ADVERTENCIA', 'CRITICO', 'SATURADO')
             > FIELD(v_antes,   'DISPONIBLE', 'ADVERTENCIA', 'CRITICO', 'SATURADO') THEN

            SET v_pct = ROUND(100 * NEW.capacidad_utilizada / NEW.capacidad_maxima_kg, 2);

            IF v_despues = 'SATURADO' THEN
                SET v_texto = CONCAT('Botadero LLENO: ', NEW.nombre, ' (', v_pct, '% ocupado). Reubicar descargas');
            ELSE
                SET v_texto = CONCAT('Botadero ', NEW.nombre, ' en nivel ', v_despues, ' (', v_pct, '% ocupado)');
            END IF;

            CALL p_aux_registrar_alerta('BOTADERO', NEW.idBotadero,
                                        IF(v_despues = 'ADVERTENCIA', 'ADVERTENCIA', 'CRITICO'), v_texto);
        END IF;
    END IF;
END$$

-- ------------------------------------------------------------
-- T3 (REGULAR) Presupuesto de materiales.
-- BEFORE: bloquea la compra que haria pasar el gasto del mes del presupuesto definido.
-- AFTER : avisa al llegar al 80 % y al agotarse.
-- Si el mes no tiene presupuesto definido, la compra pasa sin control.
-- No toca el stock: la compra solo se inserta en COMPRA_MATERIAL.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_control_presupuesto_material$$
CREATE TRIGGER trg_control_presupuesto_material
BEFORE INSERT ON COMPRA_MATERIAL
FOR EACH ROW
BEGIN
    DECLARE v_monto_mes DECIMAL(14,2) DEFAULT NULL;
    DECLARE v_gasto     DECIMAL(14,2);
    DECLARE v_msg       VARCHAR(128);

    IF NEW.total IS NULL OR NEW.total = 0 THEN
        SET NEW.total = ROUND(NEW.cantidad * NEW.precio_unitario, 2);
    END IF;

    SELECT pm.monto INTO v_monto_mes
      FROM PRESUPUESTO_MATERIAL pm
     WHERE pm.anio = YEAR(NEW.fecha) AND pm.mes = MONTH(NEW.fecha);

    IF v_monto_mes IS NOT NULL THEN
        SET v_gasto = f_gasto_materiales_periodo(
                          DATE_SUB(NEW.fecha, INTERVAL DAYOFMONTH(NEW.fecha) - 1 DAY),
                          LAST_DAY(NEW.fecha));

        IF v_gasto + NEW.total > v_monto_mes THEN
            SET v_msg = LEFT(CONCAT('Presupuesto excedido: saldo Bs ', ROUND(v_monto_mes - v_gasto, 2),
                                    ', la compra cuesta Bs ', NEW.total), 128);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_alerta_presupuesto_material$$
CREATE TRIGGER trg_alerta_presupuesto_material
AFTER INSERT ON COMPRA_MATERIAL
FOR EACH ROW
BEGIN
    DECLARE v_monto_mes DECIMAL(14,2) DEFAULT NULL;
    DECLARE v_gasto     DECIMAL(14,2);
    DECLARE v_pct       DECIMAL(7,2);

    SELECT pm.monto INTO v_monto_mes
      FROM PRESUPUESTO_MATERIAL pm
     WHERE pm.anio = YEAR(NEW.fecha) AND pm.mes = MONTH(NEW.fecha);

    IF v_monto_mes IS NOT NULL AND v_monto_mes > 0 THEN
        -- La fila nueva ya es visible dentro del AFTER INSERT.
        SET v_gasto = f_gasto_materiales_periodo(
                          DATE_SUB(NEW.fecha, INTERVAL DAYOFMONTH(NEW.fecha) - 1 DAY),
                          LAST_DAY(NEW.fecha));
        SET v_pct = ROUND(100 * v_gasto / v_monto_mes, 2);

        IF v_pct >= 100 THEN
            CALL p_aux_registrar_alerta('PRESUPUESTO', MONTH(NEW.fecha), 'CRITICO',
                CONCAT('Presupuesto de materiales AGOTADO en ', MONTH(NEW.fecha), '/', YEAR(NEW.fecha),
                       ' (gastado Bs ', v_gasto, ' de Bs ', v_monto_mes, ')'));
        ELSEIF v_pct >= 80 THEN
            CALL p_aux_registrar_alerta('PRESUPUESTO', MONTH(NEW.fecha), 'ADVERTENCIA',
                CONCAT('Presupuesto de materiales al ', v_pct, '% en ', MONTH(NEW.fecha), '/', YEAR(NEW.fecha),
                       ' (quedan Bs ', ROUND(v_monto_mes - v_gasto, 2), ')'));
        END IF;
    END IF;
END$$

-- ------------------------------------------------------------
-- T5 (FACIL) Una jornada cerrada (zona + fecha) ya no admite cambios en RECOLECTA.
-- Se necesitan tres triggers porque MySQL no permite uno solo para varios eventos.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_bloquear_jornada_cerrada$$
CREATE TRIGGER trg_bloquear_jornada_cerrada
BEFORE INSERT ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_zona INT DEFAULT 0;
    DECLARE v_msg  VARCHAR(128);

    SET v_zona = f_jornada_cerrada_contenedor(NEW.idContenedor, NEW.fecha);
    IF v_zona > 0 THEN
        SET v_msg = LEFT(CONCAT('Jornada cerrada: la zona ', v_zona, ' ya cerro el ',
                                DATE_FORMAT(NEW.fecha, '%Y-%m-%d'), '; no se puede registrar'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_bloquear_jornada_cerrada_bu$$
CREATE TRIGGER trg_bloquear_jornada_cerrada_bu
BEFORE UPDATE ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_zona INT DEFAULT 0;
    DECLARE v_msg  VARCHAR(128);

    -- Se revisa el registro original y el destino: no se puede sacar ni meter nada en una jornada cerrada.
    SET v_zona = f_jornada_cerrada_contenedor(OLD.idContenedor, OLD.fecha);
    IF v_zona = 0 THEN
        SET v_zona = f_jornada_cerrada_contenedor(NEW.idContenedor, NEW.fecha);
    END IF;
    IF v_zona > 0 THEN
        SET v_msg = LEFT(CONCAT('Jornada cerrada: la zona ', v_zona, ' ya cerro; no se puede modificar la recoleccion'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_bloquear_jornada_cerrada_bd$$
CREATE TRIGGER trg_bloquear_jornada_cerrada_bd
BEFORE DELETE ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_zona INT DEFAULT 0;
    DECLARE v_msg  VARCHAR(128);

    SET v_zona = f_jornada_cerrada_contenedor(OLD.idContenedor, OLD.fecha);
    IF v_zona > 0 THEN
        SET v_msg = LEFT(CONCAT('Jornada cerrada: la zona ', v_zona, ' ya cerro; no se puede eliminar la recoleccion'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

-- ------------------------------------------------------------
-- T4 (COMPLEJO) Control operativo despues de cada recoleccion. Reemplaza a trg_auditar_recoleccion.
--   1. Zona del contenedor y transporte (el de la fila o, si viene NULL, el del recolector).
--   2. Carga PROYECTADA del transporte = carga_actual_kg + kg de esta recoleccion.
--      (p_registrar_recoleccion_kg suma la carga DESPUES del INSERT, por eso aqui se suma a mano.)
--      Si llega al 90 % -> alerta "enviar a botadero".
--   3. Cobertura de la zona ese dia (f_i_cobertura_zona). Si llega al 100 % -> alerta "zona completa".
--   4. Auditoria del INSERT con kg, % de carga y % de cobertura.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_control_operativo_recoleccion$$
CREATE TRIGGER trg_control_operativo_recoleccion
AFTER INSERT ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_zona       INT DEFAULT NULL;
    DECLARE v_transporte INT DEFAULT NULL;
    DECLARE v_placa      VARCHAR(15) DEFAULT NULL;
    DECLARE v_cap        DECIMAL(12,2) DEFAULT 0;
    DECLARE v_carga      DECIMAL(12,2) DEFAULT 0;
    DECLARE v_pct_carga  DECIMAL(7,2)  DEFAULT NULL;
    DECLARE v_cobertura  DECIMAL(5,2)  DEFAULT NULL;

    SELECT v.idZona INTO v_zona
      FROM CONTENEDOR c JOIN VIA v ON v.idVia = c.idVia
     WHERE c.idContenedor = NEW.idContenedor;

    SET v_transporte = NEW.idTransporte;
    IF v_transporte IS NULL THEN
        SELECT r.idTransporte INTO v_transporte
          FROM RECOLECTOR r WHERE r.idrecolector = NEW.idrecolector;
    END IF;

    IF v_transporte IS NOT NULL THEN
        SELECT t.placa, t.capacidad_kg, t.carga_actual_kg
          INTO v_placa, v_cap, v_carga
          FROM TRANSPORTE t WHERE t.idTransporte = v_transporte;

        IF v_cap > 0 THEN
            SET v_pct_carga = ROUND(100 * (v_carga + COALESCE(NEW.cantidad_kg, 0)) / v_cap, 2);
            IF v_pct_carga >= 90 THEN
                CALL p_aux_registrar_alerta('TRANSPORTE', v_transporte,
                    IF(v_pct_carga >= 100, 'CRITICO', 'ADVERTENCIA'),
                    CONCAT('Transporte ', v_placa, ' al limite de su capacidad (90% o mas): enviar a botadero'));
            END IF;
        END IF;
    END IF;

    IF v_zona IS NOT NULL THEN
        SET v_cobertura = f_i_cobertura_zona(v_zona, NEW.fecha, NEW.fecha);
        IF v_cobertura IS NOT NULL AND v_cobertura >= 100 THEN
            CALL p_aux_registrar_alerta('ZONA', v_zona, 'INFO',
                CONCAT('Zona ', v_zona, ' completada el ', DATE_FORMAT(NEW.fecha, '%Y-%m-%d'),
                       ': todos sus contenedores fueron recolectados. Puede cerrar la jornada'));
        END IF;
    END IF;

    INSERT INTO AUDITORIA_RECOLECCION
        (accion, idrecolector, idContenedor, fecha_recoleccion, idZona, detalle, usuario)
    VALUES ('INSERT', NEW.idrecolector, NEW.idContenedor, NEW.fecha, v_zona,
            LEFT(CONCAT('Recoleccion ', COALESCE(NEW.cantidad_kg, 0), ' kg; transporte ', COALESCE(v_placa, 's/d'),
                        '; carga ', COALESCE(v_pct_carga, 's/d'), '%; cobertura zona ',
                        COALESCE(v_cobertura, 's/d'), '%'), 255),
            CURRENT_USER());
END$$

DELIMITER ;
