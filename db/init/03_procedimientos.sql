-- Cinco procedimientos operativos, compatibles con las 19 tablas y los 5 triggers.
-- MySQL 8.0: los procedimientos realizan movimientos de stock/carga UNA sola vez.
USE empresa_recolectora;
DELIMITER $$

DROP PROCEDURE IF EXISTS p_programar_ruta$$
CREATE PROCEDURE p_programar_ruta(IN p_transporte INT, IN p_ruta INT, IN p_fecha DATE)
BEGIN
  DECLARE v_estado VARCHAR(30);
  DECLARE v_ruta_estado VARCHAR(50);
  DECLARE v_cnt INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_fecha IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Indique la fecha de programacion'; END IF;
  START TRANSACTION;
  SELECT MAX(estado) INTO v_estado FROM TRANSPORTE WHERE idTransporte=p_transporte;
  SELECT MAX(estado_operativo) INTO v_ruta_estado FROM RUTA WHERE idRuta=p_ruta;
  IF v_estado IS NULL OR v_estado <> 'Operativo' OR v_ruta_estado IS NULL OR v_ruta_estado <> 'Activa' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Transporte no operativo o ruta no activa';
  END IF;
  SELECT COUNT(*) INTO v_cnt FROM PASA_POR WHERE idTransporte=p_transporte AND idRuta=p_ruta AND fecha=p_fecha;
  IF v_cnt > 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La programacion ya existe para esta fecha'; END IF;
  INSERT INTO PASA_POR(idTransporte,idRuta,fecha) VALUES(p_transporte,p_ruta,p_fecha);
  COMMIT;
  SELECT 'Ruta programada correctamente' AS mensaje;
END$$

DROP PROCEDURE IF EXISTS p_registrar_recoleccion$$
CREATE PROCEDURE p_registrar_recoleccion(IN p_recolector INT, IN p_contenedor INT, IN p_ruta INT, IN p_fecha DATE, IN p_hora TIME, IN p_kg DECIMAL(12,2))
BEGIN
  DECLARE v_transporte INT DEFAULT NULL;
  DECLARE v_carga DECIMAL(12,2);
  DECLARE v_capacidad DECIMAL(12,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_kg IS NULL OR p_kg <= 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El peso debe ser mayor que cero'; END IF;
  START TRANSACTION;
  SELECT MAX(idTransporte) INTO v_transporte FROM RECOLECTOR WHERE idrecolector=p_recolector;
  IF v_transporte IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Recolector no encontrado'; END IF;
  SELECT carga_actual_kg,capacidad_kg INTO v_carga,v_capacidad FROM TRANSPORTE WHERE idTransporte=v_transporte FOR UPDATE;
  IF v_carga+p_kg > v_capacidad THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La recoleccion excede la capacidad del camion'; END IF;
  INSERT INTO RECOLECTA(idrecolector,idContenedor,fecha,cantidad_kg,idTransporte,idRuta,hora_recoleccion)
    VALUES(p_recolector,p_contenedor,p_fecha,p_kg,v_transporte,p_ruta,p_hora);
  UPDATE TRANSPORTE SET carga_actual_kg=carga_actual_kg+p_kg WHERE idTransporte=v_transporte;
  COMMIT;
  SELECT 'Recoleccion registrada y carga actualizada' AS mensaje;
END$$

DROP PROCEDURE IF EXISTS p_asignar_material$$
CREATE PROCEDURE p_asignar_material(IN p_persona INT,IN p_material INT,IN p_fecha DATE,IN p_cantidad INT)
BEGIN
  DECLARE v_stock INT;
  DECLARE v_precio DECIMAL(10,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_cantidad IS NULL OR p_cantidad<=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cantidad de material invalida'; END IF;
  START TRANSACTION;
  SELECT stock_actual,precio INTO v_stock,v_precio FROM MATERIAL_TRABAJO WHERE idMaterial=p_material FOR UPDATE;
  IF v_stock IS NULL OR v_stock<p_cantidad THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No hay stock suficiente'; END IF;
  INSERT INTO DISPONE(idPersona,idMaterial,fecha,cantidad,precio_unitario_asignacion)
    VALUES(p_persona,p_material,p_fecha,p_cantidad,v_precio);
  UPDATE MATERIAL_TRABAJO SET stock_actual=stock_actual-p_cantidad WHERE idMaterial=p_material;
  COMMIT;
  SELECT 'Entrega registrada y stock descontado' AS mensaje;
END$$

DROP PROCEDURE IF EXISTS p_registrar_descarga$$
CREATE PROCEDURE p_registrar_descarga(IN p_transporte INT,IN p_botadero INT,IN p_fecha DATETIME,IN p_kg DECIMAL(12,2))
BEGIN
  DECLARE v_carga DECIMAL(12,2);
  DECLARE v_libre DECIMAL(15,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_kg IS NULL OR p_kg<=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Peso de descarga invalido'; END IF;
  START TRANSACTION;
  SELECT carga_actual_kg INTO v_carga FROM TRANSPORTE WHERE idTransporte=p_transporte FOR UPDATE;
  SELECT capacidad_maxima_kg-capacidad_utilizada INTO v_libre FROM BOTADERO WHERE idBotadero=p_botadero FOR UPDATE;
  IF v_carga IS NULL OR v_libre IS NULL OR v_carga<p_kg OR v_libre<p_kg THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Carga insuficiente o capacidad disponible del botadero agotada';
  END IF;
  INSERT INTO DESCARGA_BOTADERO(idTransporte,idBotadero,fecha,cantidad_kg,estado)
    VALUES(p_transporte,p_botadero,p_fecha,p_kg,'Confirmada');
  UPDATE TRANSPORTE SET carga_actual_kg=carga_actual_kg-p_kg WHERE idTransporte=p_transporte;
  UPDATE BOTADERO SET capacidad_utilizada=capacidad_utilizada+p_kg WHERE idBotadero=p_botadero;
  COMMIT;
  SELECT 'Descarga registrada y capacidades actualizadas' AS mensaje;
END$$

DROP PROCEDURE IF EXISTS p_registrar_devolucion$$
CREATE PROCEDURE p_registrar_devolucion(IN p_persona INT,IN p_material INT,IN p_fecha_asignacion DATE,IN p_fecha_devolucion DATE,IN p_cantidad INT,IN p_danada INT)
BEGIN
  DECLARE v_stock INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_cantidad IS NULL OR p_cantidad<=0 OR p_danada IS NULL OR p_danada<0 OR p_danada>p_cantidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cantidades invalidas';
  END IF;
  START TRANSACTION;
  SELECT stock_actual INTO v_stock FROM MATERIAL_TRABAJO WHERE idMaterial=p_material FOR UPDATE;
  IF v_stock IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Material inexistente'; END IF;
  INSERT INTO DEVOLUCION_MATERIAL(idPersona,idMaterial,fecha_asignacion,fecha_devolucion,cantidad_devuelta,cantidad_danada,estado_devolucion)
    VALUES(p_persona,p_material,p_fecha_asignacion,p_fecha_devolucion,p_cantidad,p_danada,
      IF(p_danada>0,'Con danos','Sin danos'));
  UPDATE MATERIAL_TRABAJO SET stock_actual=stock_actual+(p_cantidad-p_danada) WHERE idMaterial=p_material;
  COMMIT;
  SELECT 'Devolucion registrada y material reutilizable reincorporado' AS mensaje;
END$$
DELIMITER ;
