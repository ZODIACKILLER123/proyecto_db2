USE empresa_recolectora;

DELIMITER $$

DROP PROCEDURE IF EXISTS p_registrar_recolector$$

CREATE PROCEDURE p_registrar_recolector(
    IN p_ci            VARCHAR(20),
    IN p_tipo_empleado VARCHAR(50),
    IN p_sueldo        DECIMAL(10,2),
    IN p_idTransporte  INT
)
BEGIN
    -- ===== Declaraciones =====
    DECLARE v_idPersona INT DEFAULT NULL;
    DECLARE v_nombre    VARCHAR(101);
    DECLARE v_existe    INT DEFAULT 0;
    DECLARE v_tipo      VARCHAR(50);
    DECLARE v_estado    VARCHAR(30) DEFAULT NULL;

    -- ===== Excepciones =====
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_registrar_recolector;
        RESIGNAL;
    END;

    -- ===== Cuerpo =====
    START TRANSACTION;
    SAVEPOINT sp_registrar_recolector;

    -- 1) La persona debe existir (se busca por CI)
    IF TRIM(IFNULL(p_ci, '')) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El CI es obligatorio';
    END IF;

    SELECT idPersona, CONCAT(nombre, ' ', paterno)
      INTO v_idPersona, v_nombre
      FROM PERSONA WHERE ci = TRIM(p_ci) LIMIT 1;

    IF v_idPersona IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No existe una persona con ese CI. Registrala primero en la pestana PERSONA';
    END IF;

    -- 2) Sin rol previo: la persona no puede ser ya recolector ni conductor
    SELECT COUNT(*) INTO v_existe FROM RECOLECTOR WHERE idrecolector = v_idPersona;
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esa persona ya es recolector';
    END IF;

    SELECT COUNT(*) INTO v_existe FROM CONDUCTOR WHERE idconductor = v_idPersona;
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esa persona ya es conductor, no puede ser recolector';
    END IF;

    -- 3) Datos propios del recolector
    SET v_tipo = CASE UPPER(TRIM(p_tipo_empleado))
                     WHEN 'RECOLECTOR'              THEN 'Recolector'
                     WHEN 'CARGADOR'                THEN 'Cargador'
                     WHEN 'AYUDANTE DE RECOLECCION' THEN 'Ayudante de recoleccion'
                     ELSE NULL
                 END;
    IF v_tipo IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tipo invalido (Recolector, Cargador o Ayudante de recoleccion)';
    END IF;

    IF p_sueldo IS NULL OR p_sueldo <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sueldo debe ser mayor a 0';
    END IF;

    -- 4) El transporte debe existir y estar operativo
    SELECT estado INTO v_estado FROM TRANSPORTE WHERE idTransporte = p_idTransporte;
    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El transporte indicado no existe';
    END IF;
    IF UPPER(v_estado) <> 'OPERATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El transporte no esta operativo';
    END IF;

    -- 5) Insercion (FK a PERSONA y TRANSPORTE)
    INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte)
    VALUES (v_idPersona, v_tipo, p_sueldo, p_idTransporte);

    COMMIT;

    SELECT v_idPersona AS idrecolector,
           CONCAT('Recolector registrado: ', v_nombre) AS mensaje;
END$$

DELIMITER ;