USE empresa_recolectora;
SET NAMES utf8mb4;

-- Complemento para el proyecto Empresa Recolectora.
-- Los nombres y firmas coinciden con backend/app/catalogo.py.
-- Las reglas propuestas que no fija el diagrama se documentan junto a cada objeto.

DELIMITER $$

-- ---------------------------------------------------------------------------
-- FUNCIONES (lectura)
-- ---------------------------------------------------------------------------

DROP FUNCTION IF EXISTS f_capacidad_total_botadero$$
CREATE FUNCTION f_capacidad_total_botadero(p_idBotadero INT)
RETURNS DECIMAL(12,2)
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2) DEFAULT 0;

    SELECT COALESCE(SUM(q.capacidad_numerica), 0)
      INTO v_total
      FROM (
          SELECT DISTINCT t.idTransporte,
                 CAST(REGEXP_SUBSTR(t.capacidad, '^[0-9]+([.][0-9]+)?') AS DECIMAL(12,2))
                     AS capacidad_numerica
            FROM TRANSPORTE t
             JOIN PASA_POR pp ON pp.idTransporte = t.idTransporte
            WHERE t.idBotadero = p_idBotadero
              AND UPPER(TRIM(t.estado)) = 'OPERATIVO'
      ) AS q;

    RETURN v_total;
END$$

DROP FUNCTION IF EXISTS f_recolectas_por_recolector$$
CREATE FUNCTION f_recolectas_por_recolector(
    p_idrecolector INT,
    p_desde DATE,
    p_hasta DATE
)
RETURNS INT
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*) INTO v_total
      FROM RECOLECTA r
     WHERE r.idrecolector = p_idrecolector
       AND (p_desde IS NULL OR r.fecha >= p_desde)
       AND (p_hasta IS NULL OR r.fecha <= p_hasta);

    RETURN v_total;
END$$

DROP FUNCTION IF EXISTS f_costo_materiales_persona$$
CREATE FUNCTION f_costo_materiales_persona(p_idPersona INT)
RETURNS DECIMAL(14,2)
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(14,2) DEFAULT 0;

    -- Reconstruye el precio vigente en la fecha de entrega usando el historial.
    -- Antes del primer cambio registrado, el precio era precio_anterior de ese cambio.
    SELECT COALESCE(SUM(
               d.cantidad * COALESCE(
                   (SELECT h.precio_nuevo
                      FROM HISTORIAL_PRECIO_MATERIAL h
                     WHERE h.idMaterial = d.idMaterial
                       AND h.fecha_cambio < DATE_ADD(d.fecha, INTERVAL 1 DAY)
                     ORDER BY h.fecha_cambio DESC, h.idHistorial DESC
                     LIMIT 1),
                   (SELECT h.precio_anterior
                      FROM HISTORIAL_PRECIO_MATERIAL h
                     WHERE h.idMaterial = d.idMaterial
                     ORDER BY h.fecha_cambio ASC, h.idHistorial ASC
                     LIMIT 1),
                   m.precio
               )
           ), 0)
      INTO v_total
      FROM DISPONE d
      JOIN MATERIAL_TRABAJO m ON m.idMaterial = d.idMaterial
     WHERE d.idPersona = p_idPersona;

    RETURN v_total;
END$$

DROP FUNCTION IF EXISTS f_estado_operativo_transporte$$
CREATE FUNCTION f_estado_operativo_transporte(p_idTransporte INT)
RETURNS VARCHAR(20)
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_estado VARCHAR(30);
    DECLARE v_idconductor INT;
    DECLARE v_licencia_valida INT DEFAULT 0;
    DECLARE v_recolectores INT DEFAULT 0;
    DECLARE v_rutas INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe
      FROM TRANSPORTE WHERE idTransporte = p_idTransporte;
    IF v_existe = 0 THEN
        RETURN 'NO OPERATIVO';
    END IF;

    SELECT estado, idconductor INTO v_estado, v_idconductor
      FROM TRANSPORTE WHERE idTransporte = p_idTransporte;

    SELECT COUNT(*) INTO v_licencia_valida
      FROM CONDUCTOR c
     WHERE c.idconductor = v_idconductor
       AND TRIM(c.nro_licencia) <> ''
       AND UPPER(TRIM(c.categoria_licencia)) IN ('A', 'B', 'C');

    SELECT COUNT(*) INTO v_recolectores
      FROM RECOLECTOR WHERE idTransporte = p_idTransporte;

    SELECT COUNT(*) INTO v_rutas
      FROM PASA_POR WHERE idTransporte = p_idTransporte;

    -- Un transporte operativo debe estar activo, tener licencia valida,
    -- entre 1 y 3 recolectores y al menos una ruta asignada.
    IF UPPER(TRIM(v_estado)) = 'OPERATIVO'
       AND v_licencia_valida = 1
       AND v_recolectores BETWEEN 1 AND 3
       AND v_rutas >= 1 THEN
        RETURN 'OPERATIVO';
    END IF;

    RETURN 'NO OPERATIVO';
END$$

DROP FUNCTION IF EXISTS f_cobertura_zona$$
CREATE FUNCTION f_cobertura_zona(
    p_idZona INT,
    p_desde DATE,
    p_hasta DATE
)
RETURNS DECIMAL(5,2)
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_contenedores INT DEFAULT 0;
    DECLARE v_recolectados INT DEFAULT 0;

    SELECT COUNT(DISTINCT c.idContenedor) INTO v_contenedores
      FROM CONTENEDOR c
      JOIN VIA v ON v.idVia = c.idVia
     WHERE v.idZona = p_idZona;

    IF v_contenedores = 0 THEN
        RETURN NULL;
    END IF;

    SELECT COUNT(DISTINCT r.idContenedor) INTO v_recolectados
      FROM RECOLECTA r
      JOIN CONTENEDOR c ON c.idContenedor = r.idContenedor
      JOIN VIA v ON v.idVia = c.idVia
     WHERE v.idZona = p_idZona
       AND (p_desde IS NULL OR r.fecha >= p_desde)
       AND (p_hasta IS NULL OR r.fecha <= p_hasta);

    RETURN ROUND(100.0 * v_recolectados / v_contenedores, 2);
END$$

-- ---------------------------------------------------------------------------
-- TRIGGERS (validaciones y auditoría)
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_validar_transporte_activo$$
CREATE TRIGGER trg_validar_transporte_activo
BEFORE INSERT ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_estado VARCHAR(30);
    SELECT t.estado INTO v_estado
      FROM RECOLECTOR r JOIN TRANSPORTE t ON t.idTransporte = r.idTransporte
     WHERE r.idrecolector = NEW.idrecolector;
    IF UPPER(TRIM(COALESCE(v_estado, ''))) <> 'OPERATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede recolectar: el transporte del recolector no esta operativo';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_validar_transporte_activo_bu$$
CREATE TRIGGER trg_validar_transporte_activo_bu
BEFORE UPDATE ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_estado VARCHAR(30);
    SELECT t.estado INTO v_estado
      FROM RECOLECTOR r JOIN TRANSPORTE t ON t.idTransporte = r.idTransporte
     WHERE r.idrecolector = NEW.idrecolector;
    IF UPPER(TRIM(COALESCE(v_estado, ''))) <> 'OPERATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede reasignar: el transporte del recolector no esta operativo';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_auditar_recoleccion$$
CREATE TRIGGER trg_auditar_recoleccion
AFTER INSERT ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_zona INT DEFAULT NULL;
    SELECT v.idZona INTO v_zona
      FROM CONTENEDOR c JOIN VIA v ON v.idVia = c.idVia
     WHERE c.idContenedor = NEW.idContenedor;
    INSERT INTO AUDITORIA_RECOLECCION
        (accion, idrecolector, idContenedor, fecha_recoleccion, idZona, detalle, usuario)
    VALUES ('INSERT', NEW.idrecolector, NEW.idContenedor, NEW.fecha, v_zona,
            'Registro de recoleccion', CURRENT_USER());
END$$

DROP TRIGGER IF EXISTS trg_auditar_recoleccion_au$$
CREATE TRIGGER trg_auditar_recoleccion_au
AFTER UPDATE ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_zona INT DEFAULT NULL;
    SELECT v.idZona INTO v_zona
      FROM CONTENEDOR c JOIN VIA v ON v.idVia = c.idVia
     WHERE c.idContenedor = NEW.idContenedor;
    INSERT INTO AUDITORIA_RECOLECCION
        (accion, idrecolector, idContenedor, fecha_recoleccion, idZona, detalle, usuario)
    VALUES ('UPDATE', NEW.idrecolector, NEW.idContenedor, NEW.fecha, v_zona,
            CONCAT('Antes: recolector=', OLD.idrecolector, ', contenedor=', OLD.idContenedor,
                   ', fecha=', DATE_FORMAT(OLD.fecha, '%Y-%m-%d')),
            CURRENT_USER());
END$$

DROP TRIGGER IF EXISTS trg_auditar_recoleccion_ad$$
CREATE TRIGGER trg_auditar_recoleccion_ad
AFTER DELETE ON RECOLECTA
FOR EACH ROW
BEGIN
    DECLARE v_zona INT DEFAULT NULL;
    SELECT v.idZona INTO v_zona
      FROM CONTENEDOR c JOIN VIA v ON v.idVia = c.idVia
     WHERE c.idContenedor = OLD.idContenedor;
    INSERT INTO AUDITORIA_RECOLECCION
        (accion, idrecolector, idContenedor, fecha_recoleccion, idZona, detalle, usuario)
    VALUES ('DELETE', OLD.idrecolector, OLD.idContenedor, OLD.fecha, v_zona,
            'Eliminacion de recoleccion', CURRENT_USER());
END$$

DROP TRIGGER IF EXISTS trg_validar_precio_material$$
CREATE TRIGGER trg_validar_precio_material
BEFORE UPDATE ON MATERIAL_TRABAJO
FOR EACH ROW
BEGIN
    IF NEW.precio IS NULL OR NEW.precio < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio debe ser mayor o igual a cero';
    END IF;

    IF NEW.precio <> OLD.precio THEN
        -- Regla propuesta: no se permite subir el precio más de 100%.
        -- Desde precio cero cualquier subida positiva excede ese límite.
        IF (OLD.precio = 0 AND NEW.precio > 0)
           OR (OLD.precio > 0 AND NEW.precio > OLD.precio * 2) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La subida del precio no puede superar el 100%';
        END IF;

        INSERT INTO HISTORIAL_PRECIO_MATERIAL
            (idMaterial, precio_anterior, precio_nuevo, usuario)
        VALUES (OLD.idMaterial, OLD.precio, NEW.precio, CURRENT_USER());
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_validar_contenedor$$
CREATE TRIGGER trg_validar_contenedor
BEFORE INSERT ON CONTENEDOR
FOR EACH ROW
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;
    DECLARE v_capacidad DECIMAL(10,2) DEFAULT 0;

    IF TRIM(COALESCE(NEW.tipo, '')) NOT IN (
        'Organico (verde)', 'Inorganico (gris)', 'Mixto (negro)',
        'Reciclable - plastico (amarillo)', 'Reciclable - papel y carton (azul)',
        'Reciclable - vidrio (blanco)'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de contenedor no reconocido';
    END IF;

    IF NOT REGEXP_LIKE(TRIM(COALESCE(NEW.capacidad, '')),
                       '^[0-9]+([.][0-9]+)?[[:space:]]*(L|m3)$', 'i') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacidad invalida; use un valor positivo seguido de L o m3';
    END IF;
    SET v_capacidad = CAST(REGEXP_SUBSTR(NEW.capacidad, '^[0-9]+([.][0-9]+)?') AS DECIMAL(10,2));
    IF v_capacidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La capacidad debe ser mayor que cero';
    END IF;

    IF UPPER(TRIM(NEW.tamanio)) NOT IN ('PEQUENO', 'MEDIANO', 'GRANDE') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tamanio invalido: use Pequeno, Mediano o Grande';
    END IF;
    IF (UPPER(TRIM(NEW.tamanio)) = 'PEQUENO' AND
        ((UPPER(TRIM(NEW.capacidad)) LIKE '%M3') OR v_capacidad > 300))
       OR (UPPER(TRIM(NEW.tamanio)) = 'MEDIANO' AND
        ((UPPER(TRIM(NEW.capacidad)) LIKE '%M3') OR v_capacidad < 300 OR v_capacidad > 900))
       OR (UPPER(TRIM(NEW.tamanio)) = 'GRANDE' AND
        NOT (UPPER(TRIM(NEW.capacidad)) LIKE '%M3' OR v_capacidad >= 900)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La capacidad no corresponde al tamanio indicado';
    END IF;

    -- Regla propuesta ante la falta de un número en el diagrama: máximo 5 por vía.
    SELECT COUNT(*) INTO v_cantidad FROM CONTENEDOR WHERE idVia = NEW.idVia;
    IF v_cantidad >= 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La via ya alcanzo el limite de 5 contenedores';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_validar_contenedor_bu$$
CREATE TRIGGER trg_validar_contenedor_bu
BEFORE UPDATE ON CONTENEDOR
FOR EACH ROW
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;
    DECLARE v_capacidad DECIMAL(10,2) DEFAULT 0;
    DECLARE v_integrado INT DEFAULT 0;

    IF TRIM(COALESCE(NEW.tipo, '')) NOT IN (
        'Organico (verde)', 'Inorganico (gris)', 'Mixto (negro)',
        'Reciclable - plastico (amarillo)', 'Reciclable - papel y carton (azul)',
        'Reciclable - vidrio (blanco)'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de contenedor no reconocido';
    END IF;
    IF NOT REGEXP_LIKE(TRIM(COALESCE(NEW.capacidad, '')),
                       '^[0-9]+([.][0-9]+)?[[:space:]]*(L|m3)$', 'i') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacidad invalida; use un valor positivo seguido de L o m3';
    END IF;
    SET v_capacidad = CAST(REGEXP_SUBSTR(NEW.capacidad, '^[0-9]+([.][0-9]+)?') AS DECIMAL(10,2));
    IF v_capacidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La capacidad debe ser mayor que cero';
    END IF;
    IF UPPER(TRIM(NEW.tamanio)) NOT IN ('PEQUENO', 'MEDIANO', 'GRANDE') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tamanio invalido: use Pequeno, Mediano o Grande';
    END IF;
    IF (UPPER(TRIM(NEW.tamanio)) = 'PEQUENO' AND
        ((UPPER(TRIM(NEW.capacidad)) LIKE '%M3') OR v_capacidad > 300))
       OR (UPPER(TRIM(NEW.tamanio)) = 'MEDIANO' AND
        ((UPPER(TRIM(NEW.capacidad)) LIKE '%M3') OR v_capacidad < 300 OR v_capacidad > 900))
       OR (UPPER(TRIM(NEW.tamanio)) = 'GRANDE' AND
        NOT (UPPER(TRIM(NEW.capacidad)) LIKE '%M3' OR v_capacidad >= 900)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La capacidad no corresponde al tamanio indicado';
    END IF;

    IF NEW.idVia <> OLD.idVia THEN
        SELECT COUNT(*) INTO v_integrado FROM INTEGRA WHERE idContenedor = OLD.idContenedor;
        IF v_integrado > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede trasladar: el contenedor ya forma parte de una ruta';
        END IF;
    END IF;

    SELECT COUNT(*) INTO v_cantidad
      FROM CONTENEDOR
     WHERE idVia = NEW.idVia AND idContenedor <> OLD.idContenedor;
    IF v_cantidad >= 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La via ya alcanzo el limite de 5 contenedores';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_control_horario_ruta$$
CREATE TRIGGER trg_control_horario_ruta
BEFORE INSERT ON PASA_POR
FOR EACH ROW
BEGIN
    DECLARE v_horario VARCHAR(50);
    DECLARE v_zona INT;
    DECLARE v_inicio INT;
    DECLARE v_fin INT;
    DECLARE v_conflictos INT DEFAULT 0;

    SELECT Horario, idZona INTO v_horario, v_zona FROM RUTA WHERE idRuta = NEW.idRuta;
    IF v_horario IS NULL OR NOT REGEXP_LIKE(v_horario,
       '^([01][0-9]|2[0-3]):[0-5][0-9] - ([01][0-9]|2[0-3]):[0-5][0-9]$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Horario de ruta invalido; formato esperado HH:MM - HH:MM';
    END IF;
    SET v_inicio = HOUR(STR_TO_DATE(SUBSTRING(v_horario, 1, 5), '%H:%i')) * 60
                 + MINUTE(STR_TO_DATE(SUBSTRING(v_horario, 1, 5), '%H:%i'));
    SET v_fin = HOUR(STR_TO_DATE(SUBSTRING(v_horario, 9, 5), '%H:%i')) * 60
              + MINUTE(STR_TO_DATE(SUBSTRING(v_horario, 9, 5), '%H:%i'));
    IF v_fin <= v_inicio THEN SET v_fin = v_fin + 1440; END IF;

    SELECT COUNT(*) INTO v_conflictos
      FROM PASA_POR pp
      JOIN RUTA r ON r.idRuta = pp.idRuta
     WHERE pp.fecha = NEW.fecha
       AND r.idZona = v_zona
       AND NOT (pp.idTransporte = NEW.idTransporte AND pp.idRuta = NEW.idRuta AND pp.fecha = NEW.fecha)
       AND REGEXP_LIKE(r.Horario,
           '^([01][0-9]|2[0-3]):[0-5][0-9] - ([01][0-9]|2[0-3]):[0-5][0-9]$')
       AND (
           v_inicio < (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                       + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i'))
                       + IF(HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) <=
                          HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')), 1440, 0))
              AND (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                   + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i'))) < v_fin
        OR v_inicio < (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                       + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i'))
                       + IF(HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) <=
                          HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')), 1440, 0) - 1440)
              AND (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                   + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) - 1440) < v_fin
        OR v_inicio < (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                       + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i'))
                       + IF(HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) <=
                          HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')), 1440, 0) + 1440)
              AND (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                   + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) + 1440) < v_fin
       );

    IF v_conflictos > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una ruta de esta zona con horario traslapado para esa fecha';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_control_horario_ruta_bu$$
CREATE TRIGGER trg_control_horario_ruta_bu
BEFORE UPDATE ON PASA_POR
FOR EACH ROW
BEGIN
    DECLARE v_horario VARCHAR(50);
    DECLARE v_zona INT;
    DECLARE v_inicio INT;
    DECLARE v_fin INT;
    DECLARE v_conflictos INT DEFAULT 0;

    SELECT Horario, idZona INTO v_horario, v_zona FROM RUTA WHERE idRuta = NEW.idRuta;
    IF v_horario IS NULL OR NOT REGEXP_LIKE(v_horario,
       '^([01][0-9]|2[0-3]):[0-5][0-9] - ([01][0-9]|2[0-3]):[0-5][0-9]$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Horario de ruta invalido; formato esperado HH:MM - HH:MM';
    END IF;
    SET v_inicio = HOUR(STR_TO_DATE(SUBSTRING(v_horario, 1, 5), '%H:%i')) * 60
                 + MINUTE(STR_TO_DATE(SUBSTRING(v_horario, 1, 5), '%H:%i'));
    SET v_fin = HOUR(STR_TO_DATE(SUBSTRING(v_horario, 9, 5), '%H:%i')) * 60
              + MINUTE(STR_TO_DATE(SUBSTRING(v_horario, 9, 5), '%H:%i'));
    IF v_fin <= v_inicio THEN SET v_fin = v_fin + 1440; END IF;

    SELECT COUNT(*) INTO v_conflictos
      FROM PASA_POR pp JOIN RUTA r ON r.idRuta = pp.idRuta
     WHERE pp.fecha = NEW.fecha AND r.idZona = v_zona
       AND NOT (pp.idTransporte = OLD.idTransporte AND pp.idRuta = OLD.idRuta AND pp.fecha = OLD.fecha)
       AND REGEXP_LIKE(r.Horario,
           '^([01][0-9]|2[0-3]):[0-5][0-9] - ([01][0-9]|2[0-3]):[0-5][0-9]$')
       AND (
           v_inicio < (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                       + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i'))
                       + IF(HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) <=
                          HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')), 1440, 0))
              AND (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                   + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i'))) < v_fin
        OR v_inicio < (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                       + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i'))
                       + IF(HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) <=
                          HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')), 1440, 0) - 1440)
              AND (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                   + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) - 1440) < v_fin
        OR v_inicio < (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                       + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i'))
                       + IF(HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 9, 5), '%H:%i')) <=
                          HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                          + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')), 1440, 0) + 1440)
              AND (HOUR(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) * 60
                   + MINUTE(STR_TO_DATE(SUBSTRING(r.Horario, 1, 5), '%H:%i')) + 1440) < v_fin
       );

    IF v_conflictos > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una ruta de esta zona con horario traslapado para esa fecha';
    END IF;
END$$

-- ---------------------------------------------------------------------------
-- CURSORES (cada rutina devuelve un conjunto de filas para el módulo de reportes)
-- ---------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS c_zonas_y_sus_vias$$
CREATE PROCEDURE c_zonas_y_sus_vias()
BEGIN
    DECLARE v_fin_zonas BOOL DEFAULT FALSE;
    DECLARE v_idZona INT;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_ubicacion VARCHAR(150);
    DECLARE v_idVia INT;
    DECLARE v_descripcion VARCHAR(150);
    DECLARE v_tipo VARCHAR(10);
    DECLARE cur_zonas CURSOR FOR SELECT idZona, nombre, ubicacion FROM ZONA ORDER BY idZona;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_zonas = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp_zonas_vias;
    CREATE TEMPORARY TABLE tmp_zonas_vias (
        idZona INT, zona VARCHAR(100), ubicacion VARCHAR(150),
        idVia INT NULL, via VARCHAR(150) NULL, tipo_via VARCHAR(10) NULL
    );
    OPEN cur_zonas;
    zonas_loop: LOOP
        FETCH cur_zonas INTO v_idZona, v_nombre, v_ubicacion;
        IF v_fin_zonas THEN LEAVE zonas_loop; END IF;
        BEGIN
            DECLARE v_fin_vias BOOL DEFAULT FALSE;
            DECLARE cur_vias CURSOR FOR
                SELECT idVia, descripcion, calle_avenida FROM VIA
                 WHERE idZona = v_idZona ORDER BY idVia;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_vias = TRUE;
            OPEN cur_vias;
            vias_loop: LOOP
                FETCH cur_vias INTO v_idVia, v_descripcion, v_tipo;
                IF v_fin_vias THEN LEAVE vias_loop; END IF;
                INSERT INTO tmp_zonas_vias VALUES
                    (v_idZona, v_nombre, v_ubicacion, v_idVia, v_descripcion, v_tipo);
            END LOOP;
            CLOSE cur_vias;
        END;
    END LOOP;
    CLOSE cur_zonas;
    SELECT * FROM tmp_zonas_vias ORDER BY idZona, idVia;
    DROP TEMPORARY TABLE tmp_zonas_vias;
END$$

DROP PROCEDURE IF EXISTS c_rutas_y_sus_contenedores$$
CREATE PROCEDURE c_rutas_y_sus_contenedores()
BEGIN
    DECLARE v_fin_rutas BOOL DEFAULT FALSE;
    DECLARE v_idRuta INT;
    DECLARE v_zona INT;
    DECLARE v_horario VARCHAR(50);
    DECLARE v_idVia INT;
    DECLARE v_idContenedor INT;
    DECLARE v_tipo VARCHAR(50);
    DECLARE cur_rutas CURSOR FOR SELECT idRuta, idZona, Horario FROM RUTA ORDER BY idRuta;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_rutas = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp_rutas_contenedores;
    CREATE TEMPORARY TABLE tmp_rutas_contenedores (
        idRuta INT, idZona INT, horario VARCHAR(50), idVia INT NULL,
        idContenedor INT NULL, tipo VARCHAR(50) NULL
    );
    OPEN cur_rutas;
    rutas_loop: LOOP
        FETCH cur_rutas INTO v_idRuta, v_zona, v_horario;
        IF v_fin_rutas THEN LEAVE rutas_loop; END IF;
        BEGIN
            DECLARE v_fin_contenedores BOOL DEFAULT FALSE;
            DECLARE cur_contenedores CURSOR FOR
                SELECT i.idVia, c.idContenedor, c.tipo
                  FROM INTEGRA i JOIN CONTENEDOR c ON c.idContenedor = i.idContenedor
                 WHERE i.idRuta = v_idRuta ORDER BY i.idVia, c.idContenedor;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_contenedores = TRUE;
            OPEN cur_contenedores;
            contenedores_loop: LOOP
                FETCH cur_contenedores INTO v_idVia, v_idContenedor, v_tipo;
                IF v_fin_contenedores THEN LEAVE contenedores_loop; END IF;
                INSERT INTO tmp_rutas_contenedores VALUES
                    (v_idRuta, v_zona, v_horario, v_idVia, v_idContenedor, v_tipo);
            END LOOP;
            CLOSE cur_contenedores;
        END;
    END LOOP;
    CLOSE cur_rutas;
    SELECT * FROM tmp_rutas_contenedores ORDER BY idRuta, idVia, idContenedor;
    DROP TEMPORARY TABLE tmp_rutas_contenedores;
END$$

DROP PROCEDURE IF EXISTS c_botaderos_y_sus_transportes$$
CREATE PROCEDURE c_botaderos_y_sus_transportes()
BEGIN
    DECLARE v_fin_botaderos BOOL DEFAULT FALSE;
    DECLARE v_idBotadero INT;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_idTransporte INT;
    DECLARE v_placa VARCHAR(15);
    DECLARE v_estado VARCHAR(30);
    DECLARE v_capacidad VARCHAR(30);
    DECLARE cur_botaderos CURSOR FOR SELECT idBotadero, nombre FROM BOTADERO ORDER BY idBotadero;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_botaderos = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp_botaderos_transportes;
    CREATE TEMPORARY TABLE tmp_botaderos_transportes (
        idBotadero INT, botadero VARCHAR(100), idTransporte INT NULL,
        placa VARCHAR(15) NULL, estado VARCHAR(30) NULL, capacidad VARCHAR(30) NULL
    );
    OPEN cur_botaderos;
    botaderos_loop: LOOP
        FETCH cur_botaderos INTO v_idBotadero, v_nombre;
        IF v_fin_botaderos THEN LEAVE botaderos_loop; END IF;
        BEGIN
            DECLARE v_fin_transportes BOOL DEFAULT FALSE;
            DECLARE cur_transportes CURSOR FOR
                SELECT idTransporte, placa, estado, capacidad FROM TRANSPORTE
                 WHERE idBotadero = v_idBotadero ORDER BY idTransporte;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_transportes = TRUE;
            OPEN cur_transportes;
            transportes_loop: LOOP
                FETCH cur_transportes INTO v_idTransporte, v_placa, v_estado, v_capacidad;
                IF v_fin_transportes THEN LEAVE transportes_loop; END IF;
                INSERT INTO tmp_botaderos_transportes VALUES
                    (v_idBotadero, v_nombre, v_idTransporte, v_placa, v_estado, v_capacidad);
            END LOOP;
            CLOSE cur_transportes;
        END;
    END LOOP;
    CLOSE cur_botaderos;
    SELECT * FROM tmp_botaderos_transportes ORDER BY idBotadero, idTransporte;
    DROP TEMPORARY TABLE tmp_botaderos_transportes;
END$$

DROP PROCEDURE IF EXISTS c_recolectores_y_sus_trabajos$$
CREATE PROCEDURE c_recolectores_y_sus_trabajos()
BEGIN
    DECLARE v_fin_recolectores BOOL DEFAULT FALSE;
    DECLARE v_idrecolector INT;
    DECLARE v_nombre VARCHAR(152);
    DECLARE v_idZona INT;
    DECLARE v_fecha DATE;
    DECLARE v_contenedores INT;
    DECLARE v_cobertura DECIMAL(5,2);
    DECLARE v_recolectas INT;
    DECLARE cur_recolectores CURSOR FOR
        SELECT r.idrecolector, CONCAT(p.nombre, ' ', p.paterno)
          FROM RECOLECTOR r JOIN PERSONA p ON p.idPersona = r.idrecolector
         ORDER BY r.idrecolector;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_recolectores = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp_recolectores_trabajos;
    CREATE TEMPORARY TABLE tmp_recolectores_trabajos (
        idrecolector INT, recolector VARCHAR(152), idZona INT, fecha DATE,
        contenedores_zona INT, cobertura_pct DECIMAL(5,2), recolectas_dia INT
    );
    OPEN cur_recolectores;
    recolectores_loop: LOOP
        FETCH cur_recolectores INTO v_idrecolector, v_nombre;
        IF v_fin_recolectores THEN LEAVE recolectores_loop; END IF;
        BEGIN
            DECLARE v_fin_trabajos BOOL DEFAULT FALSE;
            DECLARE cur_trabajos CURSOR FOR
                SELECT tw.idZona, tw.fecha, COUNT(DISTINCT c.idContenedor)
                  FROM TRABAJA tw
                  LEFT JOIN VIA vi ON vi.idZona = tw.idZona
                  LEFT JOIN CONTENEDOR c ON c.idVia = vi.idVia
                 WHERE tw.idrecolector = v_idrecolector
                 GROUP BY tw.idZona, tw.fecha ORDER BY tw.fecha, tw.idZona;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_trabajos = TRUE;
            OPEN cur_trabajos;
            trabajos_loop: LOOP
                FETCH cur_trabajos INTO v_idZona, v_fecha, v_contenedores;
                IF v_fin_trabajos THEN LEAVE trabajos_loop; END IF;
                SET v_cobertura = f_cobertura_zona(v_idZona, v_fecha, v_fecha);
                SET v_recolectas = f_recolectas_por_recolector(v_idrecolector, v_fecha, v_fecha);
                INSERT INTO tmp_recolectores_trabajos VALUES
                    (v_idrecolector, v_nombre, v_idZona, v_fecha,
                     v_contenedores, v_cobertura, v_recolectas);
            END LOOP;
            CLOSE cur_trabajos;
        END;
    END LOOP;
    CLOSE cur_recolectores;
    SELECT * FROM tmp_recolectores_trabajos ORDER BY idrecolector, fecha, idZona;
    DROP TEMPORARY TABLE tmp_recolectores_trabajos;
END$$

DELIMITER ;
