USE empresa_recolectora;

DELIMITER $$

-- Version anterior (creaba persona y conductor juntos): ya no se usa
DROP PROCEDURE IF EXISTS p_registrar_persona_conductor$$
DROP PROCEDURE IF EXISTS p_registrar_conductor$$

CREATE PROCEDURE p_registrar_conductor(
    IN p_ci                 VARCHAR(20),
    IN p_nro_licencia       VARCHAR(30),
    IN p_categoria_licencia VARCHAR(10)
)
BEGIN
    -- ===== Declaraciones =====
    DECLARE v_idPersona INT DEFAULT NULL;
    DECLARE v_nombre    VARCHAR(101);
    DECLARE v_existe    INT DEFAULT 0;

    -- ===== Excepciones =====
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_registrar_conductor;
        RESIGNAL;
    END;

    -- ===== Cuerpo =====
    START TRANSACTION;
    SAVEPOINT sp_registrar_conductor;

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

    -- 2) Sin rol previo: la persona no puede ser ya conductor ni recolector
    SELECT COUNT(*) INTO v_existe FROM CONDUCTOR WHERE idconductor = v_idPersona;
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esa persona ya es conductor';
    END IF;

    SELECT COUNT(*) INTO v_existe FROM RECOLECTOR WHERE idrecolector = v_idPersona;
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esa persona ya es recolector, no puede ser conductor';
    END IF;

    -- 3) Licencia: categoria valida y numero no repetido
    IF UPPER(IFNULL(p_categoria_licencia, '')) NOT IN ('A', 'B', 'C') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Categoria de licencia invalida (A, B o C)';
    END IF;

    IF TRIM(IFNULL(p_nro_licencia, '')) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El numero de licencia es obligatorio';
    END IF;

    SELECT COUNT(*) INTO v_existe FROM CONDUCTOR WHERE nro_licencia = TRIM(p_nro_licencia);
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un conductor con ese numero de licencia';
    END IF;

    -- 4) Insercion (FK a PERSONA)
    INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia)
    VALUES (v_idPersona, TRIM(p_nro_licencia), UPPER(p_categoria_licencia));

    COMMIT;

    SELECT v_idPersona AS idconductor,
           CONCAT('Conductor registrado: ', v_nombre) AS mensaje;
END$$

DELIMITER ;