USE empresa_recolectora;

DELIMITER $$

DROP PROCEDURE IF EXISTS p_registrar_persona$$

CREATE PROCEDURE p_registrar_persona(
    IN p_ci               VARCHAR(20),
    IN p_nombre           VARCHAR(50),
    IN p_paterno          VARCHAR(50),
    IN p_materno          VARCHAR(50),
    IN p_sexo             CHAR(1),
    IN p_fecha_nacimiento DATE,
    IN p_telefono         VARCHAR(20),
    IN p_direccion        VARCHAR(150),
    IN p_turno            VARCHAR(20)
)
BEGIN
    -- ===== Declaraciones =====
    DECLARE c_edad_minima INT DEFAULT 18;
    DECLARE v_idPersona   INT;
    DECLARE v_edad        INT;
    DECLARE v_existe      INT DEFAULT 0;
    DECLARE v_turno       VARCHAR(20);

    -- ===== Excepciones =====
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_registrar_persona;
        RESIGNAL;
    END;

    -- ===== Cuerpo =====
    START TRANSACTION;
    SAVEPOINT sp_registrar_persona;

    IF TRIM(IFNULL(p_ci, '')) = '' OR TRIM(IFNULL(p_nombre, '')) = ''
       OR TRIM(IFNULL(p_paterno, '')) = '' OR TRIM(IFNULL(p_materno, '')) = ''
       OR TRIM(IFNULL(p_telefono, '')) = '' OR TRIM(IFNULL(p_direccion, '')) = ''
       OR TRIM(IFNULL(p_turno, '')) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Todos los datos de la persona son obligatorios';
    END IF;

    IF UPPER(IFNULL(p_sexo, '')) NOT IN ('M', 'F') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sexo debe ser M o F';
    END IF;

    IF p_fecha_nacimiento IS NULL OR p_fecha_nacimiento > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de nacimiento invalida';
    END IF;

    SET v_edad = TIMESTAMPDIFF(YEAR, p_fecha_nacimiento, CURDATE());
    IF v_edad < c_edad_minima THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La persona debe ser mayor de 18 anios';
    END IF;

    -- Turno: se guarda como en los datos (Manana / Tarde / Noche).
    -- La coleccion de la BD ignora tildes, asi que "Mañana" tambien coincide.
    SET v_turno = CASE UPPER(TRIM(p_turno))
                      WHEN 'MANANA' THEN 'Manana'
                      WHEN 'TARDE'  THEN 'Tarde'
                      WHEN 'NOCHE'  THEN 'Noche'
                      ELSE NULL
                  END;
    IF v_turno IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Turno invalido (Manana, Tarde o Noche)';
    END IF;

    SELECT COUNT(*) INTO v_existe FROM PERSONA WHERE ci = TRIM(p_ci);
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una persona con ese CI';
    END IF;

    SELECT IFNULL(MAX(idPersona), 0) + 1 INTO v_idPersona FROM PERSONA;

    INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo,
                         fecha_nacimiento, telefono, direccion, turno)
    VALUES (v_idPersona, TRIM(p_ci), TRIM(p_nombre), TRIM(p_paterno), TRIM(p_materno),
            UPPER(p_sexo), p_fecha_nacimiento, TRIM(p_telefono), TRIM(p_direccion),
            v_turno);

    COMMIT;

    SELECT v_idPersona AS idPersona,
           CONCAT('Persona registrada: ', TRIM(p_nombre), ' ', TRIM(p_paterno)) AS mensaje;
END$$

DELIMITER ;