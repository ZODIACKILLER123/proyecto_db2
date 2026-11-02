USE empresa_recolectora;

DELIMITER $$

-- ============================================================
-- p_registrar_zona
-- ============================================================
DROP PROCEDURE IF EXISTS p_registrar_zona$$

CREATE PROCEDURE p_registrar_zona(
    IN p_nombre          VARCHAR(100),
    IN p_ubicacion       VARCHAR(150),
    IN p_cantidad_calles INT
)
BEGIN
    DECLARE v_idZona  INT;
    DECLARE v_existe  INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_registrar_zona;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_registrar_zona;

    IF TRIM(IFNULL(p_nombre, '')) = '' OR TRIM(IFNULL(p_ubicacion, '')) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre y la ubicacion de la zona son obligatorios';
    END IF;

    IF p_cantidad_calles IS NULL OR p_cantidad_calles < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad de calles no puede ser negativa';
    END IF;

    SELECT COUNT(*) INTO v_existe FROM ZONA WHERE UPPER(nombre) = UPPER(TRIM(p_nombre));
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una zona con ese nombre';
    END IF;

    SELECT IFNULL(MAX(idZona), 0) + 1 INTO v_idZona FROM ZONA;

    INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles)
    VALUES (v_idZona, TRIM(p_nombre), TRIM(p_ubicacion), p_cantidad_calles);

    COMMIT;

    SELECT v_idZona AS idZona,
           CONCAT('Zona registrada: ', TRIM(p_nombre)) AS mensaje;
END$$

-- ============================================================
-- p_registrar_via
-- ============================================================
DROP PROCEDURE IF EXISTS p_registrar_via$$

CREATE PROCEDURE p_registrar_via(
    IN p_descripcion   VARCHAR(150),
    IN p_calle_avenida VARCHAR(10),
    IN p_idZona        INT
)
BEGIN
    DECLARE v_idVia  INT;
    DECLARE v_tipo   VARCHAR(10);
    DECLARE v_zona   VARCHAR(100);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_registrar_via;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_registrar_via;

    IF TRIM(IFNULL(p_descripcion, '')) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La descripcion de la via es obligatoria';
    END IF;

    SET v_tipo = CASE UPPER(TRIM(IFNULL(p_calle_avenida, '')))
                     WHEN 'CALLE'   THEN 'Calle'
                     WHEN 'AVENIDA' THEN 'Avenida'
                     ELSE NULL
                 END;
    IF v_tipo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tipo de via debe ser Calle o Avenida';
    END IF;

    SELECT nombre INTO v_zona FROM ZONA WHERE idZona = p_idZona;
    IF v_zona IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La zona indicada no existe';
    END IF;

    SELECT IFNULL(MAX(idVia), 0) + 1 INTO v_idVia FROM VIA;

    INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona)
    VALUES (v_idVia, TRIM(p_descripcion), v_tipo, p_idZona);

    COMMIT;

    SELECT v_idVia AS idVia,
           CONCAT('Via registrada en la zona ', v_zona) AS mensaje;
END$$

-- ============================================================
-- p_registrar_contenedor
-- (la validacion fina de tipo/capacidad/limite por via la hace trg_validar_contenedor)
-- ============================================================
DROP PROCEDURE IF EXISTS p_registrar_contenedor$$

CREATE PROCEDURE p_registrar_contenedor(
    IN p_tipo      VARCHAR(50),
    IN p_capacidad VARCHAR(30),
    IN p_tamanio   VARCHAR(30),
    IN p_idVia     INT
)
BEGIN
    DECLARE v_idContenedor INT;
    DECLARE v_tamanio      VARCHAR(30);
    DECLARE v_via          VARCHAR(150);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_registrar_contenedor;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_registrar_contenedor;

    IF TRIM(IFNULL(p_tipo, '')) = '' OR TRIM(IFNULL(p_capacidad, '')) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tipo y la capacidad del contenedor son obligatorios';
    END IF;

    SET v_tamanio = CASE UPPER(TRIM(IFNULL(p_tamanio, '')))
                        WHEN 'PEQUENO' THEN 'Pequeno'
                        WHEN 'MEDIANO' THEN 'Mediano'
                        WHEN 'GRANDE'  THEN 'Grande'
                        ELSE NULL
                    END;
    IF v_tamanio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tamanio invalido (Pequeno, Mediano o Grande)';
    END IF;

    SELECT descripcion INTO v_via FROM VIA WHERE idVia = p_idVia;
    IF v_via IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La via indicada no existe';
    END IF;

    SELECT IFNULL(MAX(idContenedor), 0) + 1 INTO v_idContenedor FROM CONTENEDOR;

    INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia)
    VALUES (v_idContenedor, TRIM(p_tipo), TRIM(p_capacidad), v_tamanio, p_idVia);

    COMMIT;

    SELECT v_idContenedor AS idContenedor,
           CONCAT('Contenedor registrado en: ', v_via) AS mensaje;
END$$

-- ============================================================
-- p_eliminar_zona_segura
-- Solo borra la zona si NADA depende de ella.
-- ============================================================
DROP PROCEDURE IF EXISTS p_eliminar_zona_segura$$

CREATE PROCEDURE p_eliminar_zona_segura(
    IN p_idZona INT
)
BEGIN
    DECLARE v_nombre        VARCHAR(100);
    DECLARE v_vias          INT DEFAULT 0;
    DECLARE v_rutas         INT DEFAULT 0;
    DECLARE v_trabaja       INT DEFAULT 0;
    DECLARE v_contenedores  INT DEFAULT 0;
    DECLARE v_recolectas    INT DEFAULT 0;
    DECLARE v_detalle       VARCHAR(255) DEFAULT '';
    DECLARE v_mensaje       VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_eliminar_zona;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_eliminar_zona;

    SELECT nombre INTO v_nombre FROM ZONA WHERE idZona = p_idZona;
    IF v_nombre IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La zona indicada no existe';
    END IF;

    SELECT COUNT(*) INTO v_vias    FROM VIA     WHERE idZona = p_idZona;
    SELECT COUNT(*) INTO v_rutas   FROM RUTA    WHERE idZona = p_idZona;
    SELECT COUNT(*) INTO v_trabaja FROM TRABAJA WHERE idZona = p_idZona;
    SELECT COUNT(*) INTO v_contenedores
      FROM CONTENEDOR c JOIN VIA v ON v.idVia = c.idVia WHERE v.idZona = p_idZona;
    SELECT COUNT(*) INTO v_recolectas
      FROM RECOLECTA r
      JOIN CONTENEDOR c ON c.idContenedor = r.idContenedor
      JOIN VIA v ON v.idVia = c.idVia
     WHERE v.idZona = p_idZona;

    IF v_vias > 0         THEN SET v_detalle = CONCAT(v_detalle, v_vias, ' vias, ');          END IF;
    IF v_rutas > 0        THEN SET v_detalle = CONCAT(v_detalle, v_rutas, ' rutas, ');        END IF;
    IF v_trabaja > 0      THEN SET v_detalle = CONCAT(v_detalle, v_trabaja, ' trabajos, ');   END IF;
    IF v_contenedores > 0 THEN SET v_detalle = CONCAT(v_detalle, v_contenedores, ' contenedores, '); END IF;
    IF v_recolectas > 0   THEN SET v_detalle = CONCAT(v_detalle, v_recolectas, ' recolectas, ');     END IF;

    IF v_detalle <> '' THEN
        SET v_detalle = LEFT(v_detalle, CHAR_LENGTH(v_detalle) - 2);
        -- MESSAGE_TEXT solo acepta literal o variable (maximo 128 caracteres)
        SET v_mensaje = LEFT(CONCAT('No se puede eliminar la zona "', v_nombre, '": tiene ', v_detalle), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
    END IF;

    DELETE FROM ZONA WHERE idZona = p_idZona;

    COMMIT;

    SELECT CONCAT('Zona eliminada: ', v_nombre) AS mensaje;
END$$


DROP PROCEDURE IF EXISTS p_asignar_transporte_ruta$$

CREATE PROCEDURE p_asignar_transporte_ruta(
    IN p_idTransporte INT,
    IN p_idRuta       INT,
    IN p_fecha        DATE,
    IN p_modo         VARCHAR(10)
)
BEGIN
    DECLARE c_max_rutas_dia INT DEFAULT 3;
    DECLARE v_modo     VARCHAR(10);
    DECLARE v_placa    VARCHAR(15);
    DECLARE v_estado   VARCHAR(30);
    DECLARE v_ruta     INT DEFAULT 0;
    DECLARE v_otro     INT;
    DECLARE v_rutas_dia INT DEFAULT 0;
    DECLARE v_mensaje  VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_asignar_ruta;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_asignar_ruta;

    SET v_modo = UPPER(TRIM(IFNULL(p_modo, '')));
    IF v_modo = '' THEN SET v_modo = 'ASIGNAR'; END IF;
    IF v_modo NOT IN ('ASIGNAR', 'REASIGNAR') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El modo debe ser ASIGNAR o REASIGNAR';
    END IF;

    IF p_fecha IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha es obligatoria';
    END IF;

    SELECT placa, estado INTO v_placa, v_estado FROM TRANSPORTE WHERE idTransporte = p_idTransporte;
    IF v_placa IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El transporte indicado no existe';
    END IF;
    IF v_estado <> 'Operativo' THEN
        SET v_mensaje = LEFT(CONCAT('El transporte ', v_placa, ' no esta operativo (', v_estado, ')'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
    END IF;

    SELECT COUNT(*) INTO v_ruta FROM RUTA WHERE idRuta = p_idRuta;
    IF v_ruta = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La ruta indicada no existe';
    END IF;

    -- transporte que ya atiende esa ruta ese dia (si lo hay)
    SELECT idTransporte INTO v_otro FROM PASA_POR WHERE idRuta = p_idRuta AND fecha = p_fecha LIMIT 1;

    IF v_otro = p_idTransporte THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ese transporte ya tiene asignada esa ruta en esa fecha';
    END IF;

    SELECT COUNT(*) INTO v_rutas_dia FROM PASA_POR WHERE idTransporte = p_idTransporte AND fecha = p_fecha;
    IF v_rutas_dia >= c_max_rutas_dia THEN
        SET v_mensaje = LEFT(CONCAT('El transporte ', v_placa, ' ya tiene ', c_max_rutas_dia, ' rutas ese dia (maximo permitido)'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
    END IF;

    IF v_modo = 'ASIGNAR' THEN
        IF v_otro IS NOT NULL THEN
            SET v_mensaje = LEFT(CONCAT('La ruta ya la atiende el transporte ', v_otro, ' ese dia. Usa el modo REASIGNAR'), 128);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
        END IF;
        INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (p_idTransporte, p_idRuta, p_fecha);
    ELSE
        IF v_otro IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La ruta no tiene transporte asignado ese dia. Usa el modo ASIGNAR';
        END IF;
        UPDATE PASA_POR SET idTransporte = p_idTransporte WHERE idRuta = p_idRuta AND fecha = p_fecha;
    END IF;

    COMMIT;

    SELECT v_rutas_dia + 1 AS rutas_del_dia,
           CONCAT(IF(v_modo = 'ASIGNAR', 'Ruta ', 'Ruta reasignada '), p_idRuta,
                  ' -> transporte ', v_placa, '. Rutas del dia: ', v_rutas_dia + 1, '/', c_max_rutas_dia) AS mensaje;
END$$

-- ============================================================
-- p_reasignar_recolector_transporte
--   * Transporte nuevo operativo y con espacio (maximo 3 recolectores).
--   * Deja constancia en HISTORIAL_ASIGNACION_RECOLECTOR.
-- ============================================================
DROP PROCEDURE IF EXISTS p_reasignar_recolector_transporte$$

CREATE PROCEDURE p_reasignar_recolector_transporte(
    IN p_idrecolector       INT,
    IN p_idTransporte_nuevo INT,
    IN p_motivo             VARCHAR(255)
)
BEGIN
    DECLARE c_max_recolectores INT DEFAULT 3;
    DECLARE v_actual   INT;
    DECLARE v_placa    VARCHAR(15);
    DECLARE v_estado   VARCHAR(30);
    DECLARE v_ocupados INT DEFAULT 0;
    DECLARE v_mensaje  VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_reasignar_recolector;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_reasignar_recolector;

    SELECT idTransporte INTO v_actual FROM RECOLECTOR WHERE idrecolector = p_idrecolector;
    IF v_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recolector indicado no existe';
    END IF;

    SELECT placa, estado INTO v_placa, v_estado FROM TRANSPORTE WHERE idTransporte = p_idTransporte_nuevo;
    IF v_placa IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El transporte nuevo no existe';
    END IF;
    IF v_estado <> 'Operativo' THEN
        SET v_mensaje = LEFT(CONCAT('El transporte ', v_placa, ' no esta operativo (', v_estado, ')'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
    END IF;

    IF v_actual = p_idTransporte_nuevo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recolector ya pertenece a ese transporte';
    END IF;

    SELECT COUNT(*) INTO v_ocupados FROM RECOLECTOR WHERE idTransporte = p_idTransporte_nuevo;
    IF v_ocupados >= c_max_recolectores THEN
        SET v_mensaje = LEFT(CONCAT('El transporte ', v_placa, ' ya tiene ', c_max_recolectores, ' recolectores (capacidad maxima)'), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
    END IF;

    UPDATE RECOLECTOR SET idTransporte = p_idTransporte_nuevo WHERE idrecolector = p_idrecolector;

    INSERT INTO HISTORIAL_ASIGNACION_RECOLECTOR
        (idrecolector, idTransporte_anterior, idTransporte_nuevo, motivo, usuario)
    VALUES
        (p_idrecolector, v_actual, p_idTransporte_nuevo, NULLIF(TRIM(IFNULL(p_motivo, '')), ''), USER());

    COMMIT;

    SELECT CONCAT('Recolector ', p_idrecolector, ' reasignado del transporte ', v_actual,
                  ' al ', p_idTransporte_nuevo, ' (', v_placa, ')') AS mensaje;
END$$

 -- ============================================================
-- p_registrar_recoleccion
-- Registra o reasigna la recoleccion de un contenedor
-- ============================================================

DROP PROCEDURE IF EXISTS p_registrar_recoleccion$$

CREATE PROCEDURE p_registrar_recoleccion(
    IN p_idrecolector INT,
    IN p_idContenedor INT,
    IN p_fecha DATE,
    IN p_modo VARCHAR(20)
)
BEGIN
    DECLARE v_idZona INT;
    DECLARE v_estadoTransporte VARCHAR(30);
    DECLARE v_existeRecolector INT DEFAULT 0;
    DECLARE v_existeContenedor INT DEFAULT 0;
    DECLARE v_trabaja INT DEFAULT 0;
    DECLARE v_recolecciones INT DEFAULT 0;
    DECLARE v_recolectorAnterior INT;
    DECLARE v_totalDia INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- --------------------------------------------------------
    -- 1. Validar parametros
    -- --------------------------------------------------------

    IF p_idrecolector IS NULL OR p_idrecolector <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El ID del recolector no es valido';
    END IF;

    IF p_idContenedor IS NULL OR p_idContenedor <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El ID del contenedor no es valido';
    END IF;

    IF p_fecha IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de recoleccion es obligatoria';
    END IF;

    IF UPPER(TRIM(IFNULL(p_modo, ''))) NOT IN ('REGISTRAR', 'REASIGNAR') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El modo debe ser REGISTRAR o REASIGNAR';
    END IF;

    -- --------------------------------------------------------
    -- 2. Validar existencia del recolector
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_existeRecolector
    FROM RECOLECTOR
    WHERE idrecolector = p_idrecolector;

    IF v_existeRecolector = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El recolector indicado no existe';
    END IF;

    -- --------------------------------------------------------
    -- 3. Validar existencia del contenedor y obtener su zona
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_existeContenedor
    FROM CONTENEDOR
    WHERE idContenedor = p_idContenedor;

    IF v_existeContenedor = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El contenedor indicado no existe';
    END IF;

    SELECT V.idZona
    INTO v_idZona
    FROM CONTENEDOR C
    INNER JOIN VIA V ON C.idVia = V.idVia
    WHERE C.idContenedor = p_idContenedor;

    -- --------------------------------------------------------
    -- 4. Validar que el transporte este operativo
    -- --------------------------------------------------------

    SELECT T.estado
    INTO v_estadoTransporte
    FROM RECOLECTOR R
    INNER JOIN TRANSPORTE T
        ON R.idTransporte = T.idTransporte
    WHERE R.idrecolector = p_idrecolector;

    IF UPPER(TRIM(v_estadoTransporte)) <> 'OPERATIVO' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El transporte asignado al recolector no esta operativo';
    END IF;

    -- --------------------------------------------------------
    -- 5. Validar que el recolector trabaje en esa zona y fecha
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_trabaja
    FROM TRABAJA
    WHERE idrecolector = p_idrecolector
      AND idZona = v_idZona
      AND fecha = p_fecha;

    IF v_trabaja = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El recolector no tiene asignada esta zona para la fecha indicada';
    END IF;

    -- --------------------------------------------------------
    -- 6. Consultar recolecciones existentes del contenedor
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_recolecciones
    FROM RECOLECTA
    WHERE idContenedor = p_idContenedor
      AND fecha = p_fecha;

    -- --------------------------------------------------------
    -- 7. Ejecutar segun el modo seleccionado
    -- --------------------------------------------------------

    IF UPPER(TRIM(p_modo)) = 'REGISTRAR' THEN

        IF v_recolecciones > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El contenedor ya tiene una recoleccion registrada para esta fecha';
        END IF;

        INSERT INTO RECOLECTA (
            idrecolector,
            idContenedor,
            fecha
        )
        VALUES (
            p_idrecolector,
            p_idContenedor,
            p_fecha
        );

    ELSEIF UPPER(TRIM(p_modo)) = 'REASIGNAR' THEN

        IF v_recolecciones = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No existe una recoleccion previa para reasignar';
        END IF;

        IF v_recolecciones > 1 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Existen varias asignaciones para este contenedor y fecha; revise los registros';
        END IF;

        SELECT idrecolector
        INTO v_recolectorAnterior
        FROM RECOLECTA
        WHERE idContenedor = p_idContenedor
          AND fecha = p_fecha
        FOR UPDATE;

        IF v_recolectorAnterior = p_idrecolector THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El contenedor ya esta asignado a este recolector';
        END IF;

        UPDATE RECOLECTA
        SET idrecolector = p_idrecolector
        WHERE idContenedor = p_idContenedor
          AND fecha = p_fecha;

    END IF;

    -- --------------------------------------------------------
    -- 8. Calcular total de recolecciones del dia
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_totalDia
    FROM RECOLECTA
    WHERE idrecolector = p_idrecolector
      AND fecha = p_fecha;

    COMMIT;

    -- --------------------------------------------------------
    -- 9. Devolver resultado
    -- --------------------------------------------------------

    SELECT
        p_idrecolector AS idrecolector,
        p_idContenedor AS idContenedor,
        p_fecha AS fecha,
        UPPER(TRIM(p_modo)) AS modo,
        v_totalDia AS total_recolecciones_dia,
        CASE
            WHEN UPPER(TRIM(p_modo)) = 'REGISTRAR'
                THEN 'Recoleccion registrada correctamente'
            ELSE 'Recoleccion reasignada correctamente'
        END AS mensaje;

END$$   

DELIMITER ;
