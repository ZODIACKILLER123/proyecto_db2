-- =====================================================================
-- BASE DE DATOS II | 5 REPORTES COMPLEJOS CON CURSORES | MYSQL 8.0
-- Sin tablas persistentes nuevas: usa TEMPORARY TABLE locales a la sesion.
-- Cada reporte combina 2 cursores ANIDADOS y varias relaciones 1:N / N:M.
-- Informes de solo lectura (no modifica datos operativos).
-- =====================================================================
USE empresa_recolectora;
DELIMITER $$

-- C1: ZONAS -> VIAS -> CONTENEDORES (1:N, 1:N) y RECOLECTA
DROP PROCEDURE IF EXISTS c_reporte_zonas_vias_contenedores$$
CREATE PROCEDURE c_reporte_zonas_vias_contenedores(IN p_desde DATE,IN p_hasta DATE)
BEGIN
  DECLARE v_fin INT DEFAULT 0;
  DECLARE v_idZona INT;
  DECLARE v_nombre VARCHAR(100);
  DECLARE v_vias INT;
  DECLARE v_contenedores INT;
  DECLARE v_atendidos INT;
  DECLARE v_kg DECIMAL(18,2);
  DECLARE c_zonas CURSOR FOR SELECT idZona,nombre FROM ZONA ORDER BY idZona;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=1;
  IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='C1: rango de fechas invalido';
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_c1_zonas;
  CREATE TEMPORARY TABLE tmp_c1_zonas(
    idZona INT PRIMARY KEY,nombre VARCHAR(100),vias INT,contenedores INT,
    contenedores_atendidos INT,kg_recolectados DECIMAL(18,2),cobertura_pct DECIMAL(7,2)
  );
  OPEN c_zonas;
  zona_loop: LOOP
    FETCH c_zonas INTO v_idZona,v_nombre;
    IF v_fin=1 THEN LEAVE zona_loop; END IF;
    SET v_vias=0,v_contenedores=0,v_atendidos=0,v_kg=0;
    BEGIN
      DECLARE v_fin_via INT DEFAULT 0;
      DECLARE v_idVia INT;
      DECLARE v_n INT;
      DECLARE v_at INT;
      DECLARE v_peso DECIMAL(18,2);
      DECLARE c_vias CURSOR FOR SELECT idVia FROM VIA WHERE idZona=v_idZona ORDER BY idVia;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_via=1;
      OPEN c_vias;
      via_loop: LOOP
        FETCH c_vias INTO v_idVia;
        IF v_fin_via=1 THEN LEAVE via_loop; END IF;
        SET v_vias=v_vias+1;
        SELECT COUNT(*) INTO v_n FROM CONTENEDOR WHERE idVia=v_idVia;
        SELECT COUNT(DISTINCT rc.idContenedor),COALESCE(SUM(rc.cantidad_kg),0)
          INTO v_at,v_peso
          FROM RECOLECTA rc JOIN CONTENEDOR co ON co.idContenedor=rc.idContenedor
          WHERE co.idVia=v_idVia AND rc.fecha BETWEEN p_desde AND p_hasta;
        SET v_contenedores=v_contenedores+v_n;
        SET v_atendidos=v_atendidos+v_at;
        SET v_kg=v_kg+v_peso;
      END LOOP;
      CLOSE c_vias;
    END;
    INSERT INTO tmp_c1_zonas VALUES(v_idZona,v_nombre,v_vias,v_contenedores,v_atendidos,
      v_kg,CASE WHEN v_contenedores=0 THEN 0
      ELSE ROUND(v_atendidos*100.0/v_contenedores,2) END);
  END LOOP;
  CLOSE c_zonas;
  SELECT * FROM tmp_c1_zonas ORDER BY cobertura_pct ASC,kg_recolectados DESC;
  DROP TEMPORARY TABLE IF EXISTS tmp_c1_zonas;
END$$

-- C2: RUTAS -> INTEGRA (relacion ternaria) -> RECOLECTA
-- Se cuentan contenedores distintos para evitar doble contabilizacion.
DROP PROCEDURE IF EXISTS c_reporte_rutas_contenedores$$
CREATE PROCEDURE c_reporte_rutas_contenedores(IN p_desde DATE,IN p_hasta DATE)
BEGIN
  DECLARE v_fin INT DEFAULT 0;
  DECLARE v_ruta INT; DECLARE v_zona INT; DECLARE v_km DECIMAL(12,2);
  DECLARE v_total INT; DECLARE v_atendidos INT; DECLARE v_kg DECIMAL(18,2);
  DECLARE v_via INT;
  DECLARE c_rutas CURSOR FOR SELECT idRuta,idZona,distancia_km FROM RUTA ORDER BY idRuta;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=1;
  IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='C2: rango de fechas invalido';
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_c2_rutas;
  CREATE TEMPORARY TABLE tmp_c2_rutas(
    idRuta INT PRIMARY KEY,idZona INT,distancia_km DECIMAL(12,2),
    contenedores_planificados INT,contenedores_atendidos INT,
    kg_recolectados DECIMAL(18,2),kg_por_km DECIMAL(18,2),cobertura_pct DECIMAL(7,2)
  );
  OPEN c_rutas;
  ruta_loop: LOOP
    FETCH c_rutas INTO v_ruta,v_zona,v_km;
    IF v_fin=1 THEN LEAVE ruta_loop; END IF;
    SET v_total=0,v_atendidos=0,v_kg=0;
    BEGIN
      DECLARE v_fin_c INT DEFAULT 0; DECLARE v_contenedor INT;
      DECLARE v_operaciones INT; DECLARE v_peso DECIMAL(18,2);
      DECLARE c_contenedores CURSOR FOR
        SELECT DISTINCT idContenedor FROM INTEGRA WHERE idRuta=v_ruta ORDER BY idContenedor;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_c=1;
      OPEN c_contenedores;
      cont_loop: LOOP
        FETCH c_contenedores INTO v_contenedor;
        IF v_fin_c=1 THEN LEAVE cont_loop; END IF;
        SET v_total=v_total+1;
        SELECT COUNT(*),COALESCE(SUM(cantidad_kg),0)
          INTO v_operaciones,v_peso FROM RECOLECTA
          WHERE idRuta=v_ruta AND idContenedor=v_contenedor
            AND fecha BETWEEN p_desde AND p_hasta;
        IF v_operaciones>0 THEN SET v_atendidos=v_atendidos+1; END IF;
        SET v_kg=v_kg+v_peso;
      END LOOP;
      CLOSE c_contenedores;
    END;
    INSERT INTO tmp_c2_rutas VALUES(v_ruta,v_zona,v_km,v_total,v_atendidos,v_kg,
      CASE WHEN v_km>0 THEN ROUND(v_kg/v_km,2) ELSE 0 END,
      CASE WHEN v_total>0 THEN ROUND(v_atendidos*100.0/v_total,2) ELSE 0 END);
  END LOOP;
  CLOSE c_rutas;
  SELECT * FROM tmp_c2_rutas ORDER BY cobertura_pct ASC,kg_recolectados DESC;
  DROP TEMPORARY TABLE IF EXISTS tmp_c2_rutas;
END$$

-- C3: BOTADEROS -> DESCARGAS -> TRANSPORTES (1:N y N:1)
DROP PROCEDURE IF EXISTS c_reporte_botaderos_descargas$$
CREATE PROCEDURE c_reporte_botaderos_descargas(IN p_desde DATE,IN p_hasta DATE)
BEGIN
  DECLARE v_fin INT DEFAULT 0; DECLARE v_bot INT; DECLARE v_nombre VARCHAR(100);
  DECLARE v_cap DECIMAL(15,2); DECLARE v_usada DECIMAL(15,2);
  DECLARE v_descargas INT; DECLARE v_kg DECIMAL(18,2); DECLARE v_camiones INT;
  DECLARE c_botaderos CURSOR FOR
    SELECT idBotadero,nombre,capacidad_maxima_kg,capacidad_utilizada
    FROM BOTADERO ORDER BY idBotadero;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=1;
  IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='C3: rango de fechas invalido';
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_c3_botaderos;
  CREATE TEMPORARY TABLE tmp_c3_botaderos(
    idBotadero INT PRIMARY KEY,nombre VARCHAR(100),descargas INT,
    transportes_distintos INT,kg_periodo DECIMAL(18,2),
    capacidad_maxima_kg DECIMAL(15,2),capacidad_utilizada_kg DECIMAL(15,2),
    ocupacion_actual_pct DECIMAL(7,2)
  );
  OPEN c_botaderos;
  bot_loop: LOOP
    FETCH c_botaderos INTO v_bot,v_nombre,v_cap,v_usada;
    IF v_fin=1 THEN LEAVE bot_loop; END IF;
    SET v_descargas=0,v_kg=0;
    BEGIN
      DECLARE v_fin_d INT DEFAULT 0;
      DECLARE v_transporte INT; DECLARE v_peso DECIMAL(12,2);
      DECLARE c_descargas CURSOR FOR
        SELECT d.idTransporte,d.cantidad_kg
        FROM DESCARGA_BOTADERO d JOIN TRANSPORTE t ON t.idTransporte=d.idTransporte
        WHERE d.idBotadero=v_bot AND d.estado='Confirmada'
          AND d.fecha >= p_desde AND d.fecha < DATE_ADD(p_hasta,INTERVAL 1 DAY)
        ORDER BY d.fecha,d.idDescarga;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_d=1;
      OPEN c_descargas;
      descarga_loop: LOOP
        FETCH c_descargas INTO v_transporte,v_peso;
        IF v_fin_d=1 THEN LEAVE descarga_loop; END IF;
        SET v_descargas=v_descargas+1;
        SET v_kg=v_kg+v_peso;
      END LOOP;
      CLOSE c_descargas;
    END;
    SELECT COUNT(DISTINCT idTransporte) INTO v_camiones
      FROM DESCARGA_BOTADERO
      WHERE idBotadero=v_bot AND estado='Confirmada'
        AND fecha >= p_desde AND fecha < DATE_ADD(p_hasta,INTERVAL 1 DAY);
    INSERT INTO tmp_c3_botaderos VALUES(v_bot,v_nombre,v_descargas,v_camiones,
      v_kg,v_cap,v_usada,
      CASE WHEN v_cap>0 THEN ROUND(v_usada*100.0/v_cap,2) ELSE 0 END);
  END LOOP;
  CLOSE c_botaderos;
  SELECT * FROM tmp_c3_botaderos ORDER BY ocupacion_actual_pct DESC,kg_periodo DESC;
  DROP TEMPORARY TABLE IF EXISTS tmp_c3_botaderos;
END$$

-- C4: RECOLECTOR -> TRABAJA (N:M con ZONA) -> RECOLECTA
-- El periodo se mide por fecha trabajada, no por total de dias calendario.
DROP PROCEDURE IF EXISTS c_reporte_personal_jornadas$$
CREATE PROCEDURE c_reporte_personal_jornadas(IN p_desde DATE,IN p_hasta DATE)
BEGIN
  DECLARE v_fin INT DEFAULT 0; DECLARE v_recolector INT;
  DECLARE v_nombre VARCHAR(160); DECLARE v_transporte INT;
  DECLARE v_jornadas INT; DECLARE v_ops INT; DECLARE v_kg DECIMAL(18,2);
  DECLARE v_zonas INT;
  DECLARE c_personal CURSOR FOR
    SELECT r.idrecolector,CONCAT(p.nombre,' ',p.paterno,' ',p.materno),r.idTransporte
    FROM RECOLECTOR r JOIN PERSONA p ON p.idPersona=r.idrecolector
    ORDER BY r.idrecolector;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=1;
  IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='C4: rango de fechas invalido';
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_c4_personal;
  CREATE TEMPORARY TABLE tmp_c4_personal(
    idrecolector INT PRIMARY KEY,nombre VARCHAR(160),idTransporte_actual INT,
    jornadas INT,zonas_distintas INT,operaciones INT,
    kg_recolectados DECIMAL(18,2),kg_por_jornada DECIMAL(18,2)
  );
  OPEN c_personal;
  personal_loop: LOOP
    FETCH c_personal INTO v_recolector,v_nombre,v_transporte;
    IF v_fin=1 THEN LEAVE personal_loop; END IF;
    SET v_jornadas=0,v_ops=0,v_kg=0;
    BEGIN
      DECLARE v_fin_j INT DEFAULT 0; DECLARE v_fecha DATE; DECLARE v_zona INT;
      DECLARE v_operaciones INT; DECLARE v_peso DECIMAL(18,2);
      DECLARE c_jornadas CURSOR FOR SELECT fecha,idZona FROM TRABAJA
        WHERE idrecolector=v_recolector AND fecha BETWEEN p_desde AND p_hasta
        ORDER BY fecha,idZona;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_j=1;
      OPEN c_jornadas;
      jornada_loop: LOOP
        FETCH c_jornadas INTO v_fecha,v_zona;
        IF v_fin_j=1 THEN LEAVE jornada_loop; END IF;
        SET v_jornadas=v_jornadas+1;
        SELECT COUNT(*),COALESCE(SUM(rc.cantidad_kg),0)
          INTO v_operaciones,v_peso
          FROM RECOLECTA rc JOIN RUTA ru ON ru.idRuta=rc.idRuta
          WHERE rc.idrecolector=v_recolector AND rc.fecha=v_fecha
            AND ru.idZona=v_zona;
        SET v_ops=v_ops+v_operaciones;
        SET v_kg=v_kg+v_peso;
      END LOOP;
      CLOSE c_jornadas;
    END;
    SELECT COUNT(DISTINCT idZona) INTO v_zonas FROM TRABAJA
      WHERE idrecolector=v_recolector AND fecha BETWEEN p_desde AND p_hasta;
    INSERT INTO tmp_c4_personal VALUES(v_recolector,v_nombre,v_transporte,
      v_jornadas,v_zonas,v_ops,v_kg,
      CASE WHEN v_jornadas>0 THEN ROUND(v_kg/v_jornadas,2) ELSE 0 END);
  END LOOP;
  CLOSE c_personal;
  SELECT * FROM tmp_c4_personal ORDER BY kg_recolectados DESC,jornadas DESC;
  DROP TEMPORARY TABLE IF EXISTS tmp_c4_personal;
END$$

-- C5: MATERIAL_TRABAJO -> DISPONE -> DEVOLUCION_MATERIAL (N:M via DISPONE)
-- y compras agregadas, preservando precio historico de cada entrega.
DROP PROCEDURE IF EXISTS c_reporte_materiales_movimientos$$
CREATE PROCEDURE c_reporte_materiales_movimientos(IN p_desde DATE,IN p_hasta DATE)
BEGIN
  DECLARE v_fin INT DEFAULT 0; DECLARE v_material INT; DECLARE v_nombre VARCHAR(100);
  DECLARE v_stock INT; DECLARE v_compra INT; DECLARE v_costo_compra DECIMAL(18,2);
  DECLARE v_entregadas INT; DECLARE v_devueltas INT; DECLARE v_danadas INT;
  DECLARE v_costo_entrega DECIMAL(18,2);
  DECLARE c_material CURSOR FOR SELECT idMaterial,nombre,stock_actual
    FROM MATERIAL_TRABAJO ORDER BY idMaterial;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=1;
  IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='C5: rango de fechas invalido';
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_c5_materiales;
  CREATE TEMPORARY TABLE tmp_c5_materiales(
    idMaterial INT PRIMARY KEY,nombre VARCHAR(100),unidades_compradas INT,
    costo_compras DECIMAL(18,2),unidades_entregadas INT,
    unidades_devueltas INT,unidades_danadas INT,
    costo_entregas DECIMAL(18,2),stock_actual INT,tasa_dano_pct DECIMAL(7,2)
  );
  OPEN c_material;
  material_loop: LOOP
    FETCH c_material INTO v_material,v_nombre,v_stock;
    IF v_fin=1 THEN LEAVE material_loop; END IF;
    SET v_entregadas=0,v_devueltas=0,v_danadas=0,v_costo_entrega=0;
    BEGIN
      DECLARE v_fin_a INT DEFAULT 0;
      DECLARE v_persona INT; DECLARE v_fecha DATE;
      DECLARE v_cantidad INT; DECLARE v_precio DECIMAL(10,2);
      DECLARE v_dev INT; DECLARE v_dan INT;
      DECLARE c_asignaciones CURSOR FOR
        SELECT idPersona,fecha,cantidad,precio_unitario_asignacion
        FROM DISPONE WHERE idMaterial=v_material AND fecha BETWEEN p_desde AND p_hasta
        ORDER BY fecha,idPersona;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin_a=1;
      OPEN c_asignaciones;
      asignacion_loop: LOOP
        FETCH c_asignaciones INTO v_persona,v_fecha,v_cantidad,v_precio;
        IF v_fin_a=1 THEN LEAVE asignacion_loop; END IF;
        SELECT COALESCE(SUM(cantidad_devuelta),0),COALESCE(SUM(cantidad_danada),0)
          INTO v_dev,v_dan
          FROM DEVOLUCION_MATERIAL
          WHERE idPersona=v_persona AND idMaterial=v_material
            AND fecha_asignacion=v_fecha
            AND fecha_devolucion BETWEEN p_desde AND p_hasta;
        SET v_entregadas=v_entregadas+v_cantidad;
        SET v_devueltas=v_devueltas+v_dev;
        SET v_danadas=v_danadas+v_dan;
        SET v_costo_entrega=v_costo_entrega+(v_cantidad*v_precio);
      END LOOP;
      CLOSE c_asignaciones;
    END;
    SELECT COALESCE(SUM(cantidad),0),COALESCE(SUM(total),0)
      INTO v_compra,v_costo_compra FROM COMPRA_MATERIAL
      WHERE idMaterial=v_material AND fecha BETWEEN p_desde AND p_hasta;
    INSERT INTO tmp_c5_materiales VALUES(v_material,v_nombre,v_compra,
      v_costo_compra,v_entregadas,v_devueltas,v_danadas,v_costo_entrega,
      v_stock,CASE WHEN v_devueltas>0 THEN ROUND(v_danadas*100.0/v_devueltas,2)
      ELSE 0 END);
  END LOOP;
  CLOSE c_material;
  SELECT * FROM tmp_c5_materiales ORDER BY tasa_dano_pct DESC,costo_compras DESC;
  DROP TEMPORARY TABLE IF EXISTS tmp_c5_materiales;
END$$
DELIMITER ;

-- PRUEBAS DE SOLO LECTURA (descomentar de una en una):
-- CALL c_reporte_zonas_vias_contenedores('2026-09-01','2026-09-30');
-- CALL c_reporte_rutas_contenedores('2026-09-01','2026-09-30');
-- CALL c_reporte_botaderos_descargas('2026-09-01','2026-09-30');
-- CALL c_reporte_personal_jornadas('2026-09-01','2026-09-30');
-- CALL c_reporte_materiales_movimientos('2026-09-01','2026-09-30');
-- Nota: en C5 se miden devoluciones realizadas DENTRO del periodo de
-- asignaciones del mismo periodo; no se mezclan entregas de otros periodos.
