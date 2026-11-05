-- ============================================================
-- CURSORES NUEVOS (4). Se agregan a los 5 de 05_cursores_empresa_recolectora.sql; no los reemplazan.
--   C1 fácil     c_revisar_botaderos()                          GET   sin parametros
--   C2 regular   c_reporte_camion(p_placa)                      GET   (cursor anidado)
--   C3 regular   c_reubicar_descarga_botadero(p_idTransporte,p_kg)  POST (escribe)
--   C4 complejo  c_plan_compra_materiales(p_anio, p_mes)        GET
-- En MySQL un cursor vive dentro de un procedimiento. Los de reporte arman una tabla temporal
-- y terminan con SELECT; asi los lee el backend (ver backend/app/catalogo.py).
-- ============================================================
USE empresa_recolectora;
SET NAMES utf8mb4;

DELIMITER $$

-- ------------------------------------------------------------
-- C1 (FACIL) Botaderos en riesgo: recorre BOTADERO y lista los que estan en
-- ADVERTENCIA, CRITICO o SATURADO, con lo que queda libre.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS c_revisar_botaderos$$
CREATE PROCEDURE c_revisar_botaderos()
BEGIN
    DECLARE v_id     INT;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_max    DECIMAL(15,2);
    DECLARE v_usada  DECIMAL(15,2);
    DECLARE v_nivel  VARCHAR(15);
    DECLARE v_pct    DECIMAL(7,2);
    DECLARE v_libre  DECIMAL(15,2);
    DECLARE v_accion VARCHAR(60);
    DECLARE v_fin    BOOL DEFAULT FALSE;
    DECLARE cur_botaderos CURSOR FOR
        SELECT idBotadero, nombre, capacidad_maxima_kg, capacidad_utilizada
          FROM BOTADERO ORDER BY idBotadero;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp_botaderos_riesgo;
    CREATE TEMPORARY TABLE tmp_botaderos_riesgo (
        idBotadero    INT,
        botadero      VARCHAR(100),
        ocupacion_pct DECIMAL(7,2),
        libre_kg      DECIMAL(15,2),
        libre_ton     DECIMAL(12,2),
        nivel         VARCHAR(15),
        recomendacion VARCHAR(60)
    );

    OPEN cur_botaderos;
    botaderos_loop: LOOP
        FETCH cur_botaderos INTO v_id, v_nombre, v_max, v_usada;
        IF v_fin THEN LEAVE botaderos_loop; END IF;

        SET v_nivel = f_nivel_ocupacion(v_usada, v_max);
        IF v_nivel IN ('ADVERTENCIA', 'CRITICO', 'SATURADO') THEN
            SET v_pct   = f_i_ocupacion_botadero(v_id);
            SET v_libre = f_i_margen_botadero(v_id);
            SET v_accion = CASE v_nivel
                               WHEN 'SATURADO' THEN 'No recibir: reubicar descargas'
                               WHEN 'CRITICO'  THEN 'Planificar reubicacion'
                               ELSE 'Monitorear' END;
            INSERT INTO tmp_botaderos_riesgo
            VALUES (v_id, v_nombre, v_pct, v_libre, ROUND(v_libre / 1000, 2), v_nivel, v_accion);
        END IF;
    END LOOP;
    CLOSE cur_botaderos;

    SELECT * FROM tmp_botaderos_riesgo ORDER BY ocupacion_pct DESC, idBotadero;
    DROP TEMPORARY TABLE tmp_botaderos_riesgo;
END$$

-- ------------------------------------------------------------
-- C2 (REGULAR) Reporte de un camion por placa. CURSOR ANIDADO:
--   cursor externo : ayudantes del camion
--     cursor interno : material entregado (DISPONE) a cada ayudante
--   cursor aparte  : recorridos (PASA_POR) del camion con sus contenedores
-- Resultado 1: placa, conductor, ayudante, material, costo, rutas distintas.
-- Resultado 2: cada recorrido (ruta, zona, fecha, horario, contenedores).
-- Cada cursor va en su propio bloque con su propio handler: un SELECT INTO sin filas tambien
-- dispara NOT FOUND y no debe contaminar la bandera de otro cursor.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS c_reporte_camion$$
CREATE PROCEDURE c_reporte_camion(IN p_placa VARCHAR(15))
BEGIN
    DECLARE v_idT       INT DEFAULT NULL;
    DECLARE v_placa     VARCHAR(15);
    DECLARE v_conductor VARCHAR(180) DEFAULT NULL;
    DECLARE v_rutas     INT DEFAULT 0;
    DECLARE v_ayudantes INT DEFAULT 0;

    IF TRIM(IFNULL(p_placa, '')) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ingrese la placa del camion';
    END IF;

    SELECT t.idTransporte, t.placa,
           CONCAT(pe.nombre, ' ', pe.paterno, ' ', pe.materno)
      INTO v_idT, v_placa, v_conductor
      FROM TRANSPORTE t
      JOIN PERSONA pe ON pe.idPersona = t.idconductor
     WHERE UPPER(TRIM(t.placa)) = UPPER(TRIM(p_placa));

    IF v_idT IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe un transporte con esa placa';
    END IF;

    SELECT COUNT(DISTINCT idRuta) INTO v_rutas FROM PASA_POR WHERE idTransporte = v_idT;

    DROP TEMPORARY TABLE IF EXISTS tmp_reporte_camion;
    CREATE TEMPORARY TABLE tmp_reporte_camion (
        placa              VARCHAR(15),
        conductor          VARCHAR(180),
        ayudante           VARCHAR(180),
        material_entregado TEXT,
        unidades_material  INT,
        costo_material_bs  DECIMAL(14,2),
        rutas_distintas    INT
    );
    DROP TEMPORARY TABLE IF EXISTS tmp_recorridos_camion;
    CREATE TEMPORARY TABLE tmp_recorridos_camion (
        placa        VARCHAR(15),
        idRuta       INT,
        zona         VARCHAR(100),
        fecha        DATE,
        horario      VARCHAR(50),
        contenedores INT
    );

    -- Cursor externo: ayudantes del camion
    BEGIN
        DECLARE v_fin_ay   BOOL DEFAULT FALSE;
        DECLARE v_idAy     INT;
        DECLARE v_nombreAy VARCHAR(180);
        DECLARE cur_ayudantes CURSOR FOR
            SELECT r.idrecolector, CONCAT(pe.nombre, ' ', pe.paterno, ' ', pe.materno)
              FROM RECOLECTOR r
              JOIN PERSONA pe ON pe.idPersona = r.idrecolector
             WHERE r.idTransporte = v_idT
               AND r.tipo_empleado = 'Ayudante de recoleccion'
             ORDER BY r.idrecolector;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_ay = TRUE;

        OPEN cur_ayudantes;
        ayudantes_loop: LOOP
            FETCH cur_ayudantes INTO v_idAy, v_nombreAy;
            IF v_fin_ay THEN LEAVE ayudantes_loop; END IF;
            SET v_ayudantes = v_ayudantes + 1;

            -- Cursor interno: material entregado a ese ayudante
            BEGIN
                DECLARE v_fin_mat BOOL DEFAULT FALSE;
                DECLARE v_mat     VARCHAR(100);
                DECLARE v_cant    INT;
                DECLARE v_lista   TEXT DEFAULT '';
                DECLARE v_unid    INT DEFAULT 0;
                DECLARE cur_material CURSOR FOR
                    SELECT m.nombre, SUM(d.cantidad)
                      FROM DISPONE d
                      JOIN MATERIAL_TRABAJO m ON m.idMaterial = d.idMaterial
                     WHERE d.idPersona = v_idAy
                     GROUP BY m.idMaterial, m.nombre
                     ORDER BY m.nombre;
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_mat = TRUE;

                OPEN cur_material;
                material_loop: LOOP
                    FETCH cur_material INTO v_mat, v_cant;
                    IF v_fin_mat THEN LEAVE material_loop; END IF;
                    SET v_lista = IF(v_lista = '', CONCAT(v_mat, ' x', v_cant),
                                     CONCAT(v_lista, '; ', v_mat, ' x', v_cant));
                    SET v_unid = v_unid + v_cant;
                END LOOP;
                CLOSE cur_material;

                INSERT INTO tmp_reporte_camion
                VALUES (v_placa, v_conductor, v_nombreAy,
                        IF(v_lista = '', 'Sin material entregado', v_lista),
                        v_unid, f_b_material_costo_entregado(v_idAy, '2000-01-01', '2100-12-31'), v_rutas);
            END;
        END LOOP;
        CLOSE cur_ayudantes;
    END;

    IF v_ayudantes = 0 THEN
        INSERT INTO tmp_reporte_camion
        VALUES (v_placa, v_conductor, 'Sin ayudante asignado', NULL, 0, 0, v_rutas);
    END IF;

    -- Cursor de recorridos del camion
    BEGIN
        DECLARE v_fin_rec BOOL DEFAULT FALSE;
        DECLARE v_idRuta  INT;
        DECLARE v_zona    VARCHAR(100);
        DECLARE v_fecha   DATE;
        DECLARE v_horario VARCHAR(50);
        DECLARE cur_recorridos CURSOR FOR
            SELECT pp.idRuta, z.nombre, pp.fecha, ru.Horario
              FROM PASA_POR pp
              JOIN RUTA ru ON ru.idRuta = pp.idRuta
              JOIN ZONA z  ON z.idZona  = ru.idZona
             WHERE pp.idTransporte = v_idT
             ORDER BY pp.fecha, pp.idRuta;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_rec = TRUE;

        OPEN cur_recorridos;
        recorridos_loop: LOOP
            FETCH cur_recorridos INTO v_idRuta, v_zona, v_fecha, v_horario;
            IF v_fin_rec THEN LEAVE recorridos_loop; END IF;
            INSERT INTO tmp_recorridos_camion
            VALUES (v_placa, v_idRuta, v_zona, v_fecha, v_horario, f_b_contenedores_ruta(v_idRuta));
        END LOOP;
        CLOSE cur_recorridos;
    END;

    SELECT * FROM tmp_reporte_camion;
    SELECT * FROM tmp_recorridos_camion ORDER BY fecha, idRuta;
    DROP TEMPORARY TABLE tmp_reporte_camion;
    DROP TEMPORARY TABLE tmp_recorridos_camion;
END$$

-- ------------------------------------------------------------
-- C3 (REGULAR) Descarga con reubicacion automatica.
--   1. Si el botadero habitual del camion tiene margen para los kg, descarga ahi.
--   2. Si no, el CURSOR recorre los demas botaderos, del menos al mas ocupado, y se DETIENE
--      en el primero con margen suficiente.
--   3. Si ninguno alcanza, error.
-- La descarga real la hace p_registrar_descarga (03): ese procedimiento
-- actualiza capacidad_utilizada y por eso dispara T1 (valida) y T2 (alerta).
-- OJO: ese procedimiento tambien deja el botadero elegido como destino habitual del camion.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS c_reubicar_descarga_botadero$$
CREATE PROCEDURE c_reubicar_descarga_botadero(
    IN p_idTransporte INT,
    IN p_kg           DECIMAL(12,2)
)
BEGIN
    DECLARE v_placa       VARCHAR(15) DEFAULT NULL;
    DECLARE v_actual      INT DEFAULT NULL;
    DECLARE v_nom_actual  VARCHAR(100);
    DECLARE v_pct_actual  DECIMAL(7,2);
    DECLARE v_destino     INT DEFAULT NULL;
    DECLARE v_nom_destino VARCHAR(100);
    DECLARE v_mensaje     VARCHAR(255);

    IF p_kg IS NULL OR p_kg <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los kg a descargar deben ser mayores que cero';
    END IF;

    SELECT t.placa, t.idBotadero INTO v_placa, v_actual
      FROM TRANSPORTE t WHERE t.idTransporte = p_idTransporte;
    IF v_placa IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El transporte no existe';
    END IF;

    SELECT b.nombre INTO v_nom_actual FROM BOTADERO b WHERE b.idBotadero = v_actual;
    SET v_pct_actual = f_i_ocupacion_botadero(v_actual);

    IF f_i_margen_botadero(v_actual) >= p_kg THEN
        SET v_destino = v_actual;
    ELSE
        BEGIN
            DECLARE v_fin  BOOL DEFAULT FALSE;
            DECLARE v_cand INT;
            DECLARE cur_candidatos CURSOR FOR
                SELECT idBotadero
                  FROM BOTADERO
                 WHERE idBotadero <> v_actual AND capacidad_maxima_kg > 0
                 ORDER BY capacidad_utilizada / capacidad_maxima_kg ASC, idBotadero;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

            OPEN cur_candidatos;
            busqueda: LOOP
                FETCH cur_candidatos INTO v_cand;
                IF v_fin THEN LEAVE busqueda; END IF;
                IF f_i_margen_botadero(v_cand) >= p_kg THEN
                    SET v_destino = v_cand;
                    LEAVE busqueda;
                END IF;
            END LOOP;
            CLOSE cur_candidatos;
        END;
    END IF;

    IF v_destino IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ningun botadero tiene capacidad para esa descarga';
    END IF;

    SELECT b.nombre INTO v_nom_destino FROM BOTADERO b WHERE b.idBotadero = v_destino;

    -- Descarga real (valida carga del camion y margen; actualiza BOTADERO y TRANSPORTE).
    CALL p_registrar_descarga(p_idTransporte, v_destino, NOW(), p_kg);
    -- p_registrar_descarga (03) no cambia el destino habitual del camion: lo dejamos aqui.
    UPDATE TRANSPORTE SET idBotadero = v_destino WHERE idTransporte = p_idTransporte;
    COMMIT;

    IF v_destino = v_actual THEN
        SET v_mensaje = CONCAT('Descarga de ', p_kg, ' kg registrada en ', v_nom_destino);
    ELSE
        SET v_mensaje = LEFT(CONCAT('Botadero ', v_nom_actual, ' sin capacidad (', v_pct_actual,
                                    '% ocupado): la descarga de ', p_kg, ' kg del camion ', v_placa,
                                    ' se reubico en ', v_nom_destino), 255);
        CALL p_aux_registrar_alerta('REUBICACION', v_destino, 'ADVERTENCIA', v_mensaje);
    END IF;

    SELECT IF(v_destino = v_actual, 'DESCARGA REGISTRADA', 'DESCARGA REUBICADA') AS resultado,
           p_idTransporte AS idTransporte,
           v_placa        AS placa,
           v_actual       AS botadero_original,
           v_pct_actual   AS ocupacion_original_pct,
           v_destino      AS botadero_final,
           p_kg           AS kg_descargados,
           v_mensaje      AS mensaje;
END$$

-- ------------------------------------------------------------
-- C4 (COMPLEJO) Plan de compra de materiales segun el presupuesto del mes.
--   1. Lee el presupuesto, calcula lo gastado y el saldo.
--   2. Si el saldo es <= 0 -> estado EXCEDIDO / AGOTADO y no sugiere compras.
--   3. Si queda saldo, el CURSOR recorre los materiales del mas al menos entregado (demanda)
--      y, por cada uno, sugiere hasta 5 unidades mientras alcance el saldo restante.
-- Resultado 1: resumen (presupuesto, gastado, saldo, estado, mensaje).
-- Resultado 2: lista de compra sugerida.
-- Solo sugiere: la compra real se hace con INSERT en COMPRA_MATERIAL (y T3 la vigila).
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS c_plan_compra_materiales$$
CREATE PROCEDURE c_plan_compra_materiales(IN p_anio INT, IN p_mes INT)
BEGIN
    DECLARE v_monto      DECIMAL(14,2) DEFAULT NULL;
    DECLARE v_inicio     DATE;
    DECLARE v_gasto      DECIMAL(14,2);
    DECLARE v_saldo      DECIMAL(14,2);
    DECLARE v_resto      DECIMAL(14,2);
    DECLARE v_estado     VARCHAR(30);
    DECLARE v_mensaje    VARCHAR(255);
    DECLARE v_sugerido   DECIMAL(14,2) DEFAULT 0;
    DECLARE v_prioridad  INT DEFAULT 0;
    DECLARE v_tope       INT DEFAULT 5;

    IF p_anio IS NULL OR p_anio NOT BETWEEN 2000 AND 2100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El anio debe estar entre 2000 y 2100';
    END IF;
    IF p_mes IS NULL OR p_mes NOT BETWEEN 1 AND 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El mes debe estar entre 1 y 12';
    END IF;

    SELECT pm.monto INTO v_monto
      FROM PRESUPUESTO_MATERIAL pm WHERE pm.anio = p_anio AND pm.mes = p_mes;
    IF v_monto IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay presupuesto definido para ese mes; definalo primero';
    END IF;

    SET v_inicio = STR_TO_DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01'), '%Y-%m-%d');
    SET v_gasto  = f_gasto_materiales_periodo(v_inicio, LAST_DAY(v_inicio));
    SET v_saldo  = v_monto - v_gasto;
    SET v_resto  = GREATEST(v_saldo, 0);

    DROP TEMPORARY TABLE IF EXISTS tmp_plan_compra;
    CREATE TEMPORARY TABLE tmp_plan_compra (
        prioridad          INT,
        idMaterial         INT,
        material           VARCHAR(100),
        demanda_unidades   INT,
        precio_bs          DECIMAL(10,2),
        unidades_sugeridas INT,
        costo_sugerido_bs  DECIMAL(14,2),
        saldo_restante_bs  DECIMAL(14,2)
    );

    IF v_saldo > 0 THEN
        BEGIN
            DECLARE v_fin     BOOL DEFAULT FALSE;
            DECLARE v_idMat   INT;
            DECLARE v_nombre  VARCHAR(100);
            DECLARE v_precio  DECIMAL(10,2);
            DECLARE v_demanda INT;
            DECLARE v_unid    INT;
            DECLARE v_costo   DECIMAL(14,2);
            DECLARE cur_materiales CURSOR FOR
                SELECT m.idMaterial, m.nombre, m.precio, COALESCE(SUM(d.cantidad), 0) AS demanda
                  FROM MATERIAL_TRABAJO m
                  LEFT JOIN DISPONE d ON d.idMaterial = m.idMaterial
                 GROUP BY m.idMaterial, m.nombre, m.precio
                 ORDER BY demanda DESC, m.idMaterial;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

            OPEN cur_materiales;
            materiales_loop: LOOP
                FETCH cur_materiales INTO v_idMat, v_nombre, v_precio, v_demanda;
                IF v_fin THEN LEAVE materiales_loop; END IF;

                SET v_prioridad = v_prioridad + 1;
                IF v_precio > 0 AND v_resto >= v_precio THEN
                    SET v_unid  = LEAST(FLOOR(v_resto / v_precio), v_tope);
                    SET v_costo = v_unid * v_precio;
                    SET v_resto = v_resto - v_costo;
                    SET v_sugerido = v_sugerido + v_costo;
                    INSERT INTO tmp_plan_compra
                    VALUES (v_prioridad, v_idMat, v_nombre, v_demanda, v_precio, v_unid, v_costo, v_resto);
                END IF;
            END LOOP;
            CLOSE cur_materiales;
        END;
    END IF;

    IF v_saldo < 0 THEN
        SET v_estado  = 'EXCEDIDO';
        SET v_mensaje = CONCAT('Presupuesto excedido en Bs ', ABS(v_saldo), '. No se recomienda comprar mas');
    ELSEIF v_saldo = 0 THEN
        SET v_estado  = 'AGOTADO';
        SET v_mensaje = 'Presupuesto agotado: no queda saldo para comprar';
    ELSEIF v_saldo < v_monto * 0.20 THEN
        SET v_estado  = 'SALDO BAJO';
        SET v_mensaje = CONCAT('Quedan Bs ', v_saldo, '; la lista sugerida usa Bs ', v_sugerido);
    ELSE
        SET v_estado  = 'DENTRO DEL PRESUPUESTO';
        SET v_mensaje = CONCAT('Quedan Bs ', v_saldo, '; la lista sugerida usa Bs ', v_sugerido);
    END IF;

    SELECT p_anio AS anio, p_mes AS mes, v_monto AS presupuesto_bs, v_gasto AS gastado_bs,
           v_saldo AS saldo_bs, v_sugerido AS compra_sugerida_bs, v_estado AS estado,
           v_mensaje AS mensaje;
    SELECT * FROM tmp_plan_compra ORDER BY prioridad;
    DROP TEMPORARY TABLE tmp_plan_compra;
END$$

DELIMITER ;
