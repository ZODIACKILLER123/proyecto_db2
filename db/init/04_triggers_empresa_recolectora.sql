-- =====================================================================
-- BASE DE DATOS II | 5 TRIGGERS COMPLEJOS | MYSQL 8.0.16+
-- Instalar despues de 01 (tablas), 02 (funciones), 03 (procedimientos).
-- NO ALTERAN inventario ni cargas: los procedimientos principales ya lo hacen.
-- Las validaciones existentes CHECK/FK siguen siendo la defensa primaria.
-- =====================================================================
USE empresa_recolectora;
DELIMITER $$

-- T1 | INSERT RECOLECTA. Verifica especializacion, trabajo en zona, recorrido
-- en la fecha y pertenencia de contenedor a la ruta ternaria. El procedimiento
-- principal actualiza la carga de TRANSPORTE (este trigger NO la actualiza).
DROP TRIGGER IF EXISTS trg_01_validar_recoleccion$$
CREATE TRIGGER trg_01_validar_recoleccion
BEFORE INSERT ON RECOLECTA FOR EACH ROW
BEGIN
  DECLARE v_zona INT DEFAULT NULL;
  DECLARE v_via INT DEFAULT NULL;
  DECLARE v_transporte_actual INT DEFAULT NULL;
  DECLARE v_activo INT DEFAULT 0;
  DECLARE v_num INT DEFAULT 0;
  DECLARE v_capacidad DECIMAL(12,2) DEFAULT NULL;

  IF NEW.fecha IS NULL OR NEW.hora_recoleccion IS NULL
     OR NEW.cantidad_kg IS NULL OR NEW.cantidad_kg <= 0
     OR NEW.idRuta IS NULL OR NEW.idTransporte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: faltan fecha, hora, kg, ruta o transporte';
  END IF;
  SELECT MAX(idZona) INTO v_zona FROM RUTA WHERE idRuta = NEW.idRuta;
  SELECT MAX(idVia), MAX(capacidad_kg) INTO v_via,v_capacidad
    FROM CONTENEDOR WHERE idContenedor = NEW.idContenedor;
  SELECT MAX(idTransporte) INTO v_transporte_actual
    FROM RECOLECTOR WHERE idrecolector = NEW.idrecolector;
  IF v_zona IS NULL OR v_via IS NULL OR v_transporte_actual IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: ruta, contenedor o recolector inexistente';
  END IF;
  IF NEW.cantidad_kg > v_capacidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: peso supera capacidad nominal del contenedor';
  END IF;
  IF v_transporte_actual <> NEW.idTransporte THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: recolector no corresponde al transporte';
  END IF;
  SELECT COUNT(*) INTO v_activo FROM PERSONA p
    WHERE p.idPersona = NEW.idrecolector AND p.estado_laboral = 'Activo';
  IF v_activo = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: personal inactivo';
  END IF;
  SELECT COUNT(*) INTO v_num FROM INTEGRA i
    JOIN VIA vi ON vi.idVia = i.idVia
    WHERE i.idRuta = NEW.idRuta AND i.idContenedor = NEW.idContenedor
      AND i.idVia = v_via AND vi.idZona = v_zona;
  IF v_num = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: contenedor no integra la ruta y zona';
  END IF;
  SELECT COUNT(*) INTO v_num FROM PASA_POR
    WHERE idTransporte = NEW.idTransporte AND idRuta = NEW.idRuta AND fecha = NEW.fecha;
  IF v_num = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: transporte sin ruta programada en esa fecha';
  END IF;
  SELECT COUNT(*) INTO v_num FROM TRABAJA
    WHERE idrecolector = NEW.idrecolector AND idZona = v_zona AND fecha = NEW.fecha;
  IF v_num = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T1: recolector sin jornada en zona/fecha';
  END IF;
END$$

-- T2 | INSERT INTEGRA. Una asociacion ternaria es valida SOLO cuando VIA,
-- CONTENEDOR y RUTA pertenecen a una misma zona. No modifica otras tablas.
DROP TRIGGER IF EXISTS trg_02_validar_integra$$
CREATE TRIGGER trg_02_validar_integra
BEFORE INSERT ON INTEGRA FOR EACH ROW
BEGIN
  DECLARE v_zona_ruta INT DEFAULT NULL;
  DECLARE v_zona_via INT DEFAULT NULL;
  DECLARE v_via_contenedor INT DEFAULT NULL;
  SELECT MAX(idZona) INTO v_zona_ruta FROM RUTA WHERE idRuta=NEW.idRuta;
  SELECT MAX(idZona) INTO v_zona_via FROM VIA WHERE idVia=NEW.idVia;
  SELECT MAX(idVia) INTO v_via_contenedor FROM CONTENEDOR
    WHERE idContenedor=NEW.idContenedor;
  IF v_zona_ruta IS NULL OR v_zona_via IS NULL OR v_via_contenedor IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T2: ruta, via o contenedor no existe';
  END IF;
  IF v_zona_ruta<>v_zona_via OR v_via_contenedor<>NEW.idVia THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T2: relacion ternaria incongruente (zona/via/contenedor)';
  END IF;
END$$

-- T3 | INSERT DISPONE. Valida que la entrega sea a una persona activa,
-- respete su fecha de contratacion y tenga un valor unitario no negativo.
-- Stock ya es descontado por p_compra_materiales; no se toca aqui.
DROP TRIGGER IF EXISTS trg_03_validar_entrega_material$$
CREATE TRIGGER trg_03_validar_entrega_material
BEFORE INSERT ON DISPONE FOR EACH ROW
BEGIN
  DECLARE v_fecha DATE DEFAULT NULL;
  DECLARE v_activo VARCHAR(100) DEFAULT NULL;
  DECLARE v_stock INT DEFAULT NULL;
  IF NEW.cantidad IS NULL OR NEW.cantidad <= 0
     OR NEW.precio_unitario_asignacion IS NULL OR NEW.precio_unitario_asignacion < 0
     OR NEW.fecha IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T3: cantidad, precio o fecha de entrega invalida';
  END IF;
  SELECT MAX(fecha_contratacion),MAX(estado_laboral)
    INTO v_fecha,v_activo FROM PERSONA WHERE idPersona=NEW.idPersona;
  SELECT MAX(stock_actual) INTO v_stock FROM MATERIAL_TRABAJO
    WHERE idMaterial=NEW.idMaterial;
  IF v_fecha IS NULL OR v_stock IS NULL OR v_activo <> 'Activo' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T3: persona/material inexistente o persona inactiva';
  END IF;
  IF NEW.fecha < v_fecha THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T3: entrega anterior a fecha de contratacion';
  END IF;
  IF v_stock < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T3: inventario presenta saldo negativo';
  END IF;
END$$

-- T4 | INSERT DESCARGA_BOTADERO. Valida saldo de carga y cupo botadero
-- ANTES de generar movimiento. El procedimiento P4 descuenta/suma despues.
-- No imponemos botadero == destino habitual porque P4 permite reasignar.
DROP TRIGGER IF EXISTS trg_04_validar_descarga$$
CREATE TRIGGER trg_04_validar_descarga
BEFORE INSERT ON DESCARGA_BOTADERO FOR EACH ROW
BEGIN
  DECLARE v_carga DECIMAL(12,2) DEFAULT NULL;
  DECLARE v_estado_vehiculo VARCHAR(30) DEFAULT NULL;
  DECLARE v_max DECIMAL(15,2) DEFAULT NULL;
  DECLARE v_usada DECIMAL(15,2) DEFAULT NULL;
  DECLARE v_estado_botadero VARCHAR(50) DEFAULT NULL;
  IF NEW.fecha IS NULL OR NEW.cantidad_kg IS NULL OR NEW.cantidad_kg <= 0
     OR NEW.estado <> 'Confirmada' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T4: descarga debe ser confirmada, positiva y fechada';
  END IF;
  SELECT MAX(carga_actual_kg), MAX(estado) INTO v_carga,v_estado_vehiculo
    FROM TRANSPORTE WHERE idTransporte=NEW.idTransporte;
  SELECT MAX(capacidad_maxima_kg),MAX(capacidad_utilizada),MAX(estado_operativo)
    INTO v_max,v_usada,v_estado_botadero
    FROM BOTADERO WHERE idBotadero=NEW.idBotadero;
  IF v_carga IS NULL OR v_max IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T4: transporte o botadero inexistente';
  END IF;
  IF v_estado_vehiculo <> 'Operativo' OR v_estado_botadero = 'Saturado' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T4: transporte o botadero fuera de servicio';
  END IF;
  IF NEW.cantidad_kg > v_carga OR v_usada + NEW.cantidad_kg > v_max THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T4: descarga supera carga camion o capacidad botadero';
  END IF;
END$$

-- T5 | INSERT DEVOLUCION_MATERIAL. Impide devoluciones mayores a la entrega,
-- acumulando devoluciones previas de esa asignacion, y controla deterioros.
DROP TRIGGER IF EXISTS trg_05_validar_devolucion$$
CREATE TRIGGER trg_05_validar_devolucion
BEFORE INSERT ON DEVOLUCION_MATERIAL FOR EACH ROW
BEGIN
  DECLARE v_asignada INT DEFAULT NULL;
  DECLARE v_devuelta INT DEFAULT 0;
  DECLARE v_tipo VARCHAR(100) DEFAULT NULL;
  SELECT MAX(cantidad) INTO v_asignada FROM DISPONE
    WHERE idPersona=NEW.idPersona AND idMaterial=NEW.idMaterial
      AND fecha=NEW.fecha_asignacion;
  SELECT COALESCE(SUM(cantidad_devuelta),0) INTO v_devuelta
    FROM DEVOLUCION_MATERIAL
    WHERE idPersona=NEW.idPersona AND idMaterial=NEW.idMaterial
      AND fecha_asignacion=NEW.fecha_asignacion;
  SELECT MAX(tipo_uso) INTO v_tipo FROM MATERIAL_TRABAJO
    WHERE idMaterial=NEW.idMaterial;
  IF v_asignada IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T5: entrega original no encontrada';
  END IF;
  IF v_tipo <> 'Reutilizable' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T5: devolucion solo para materiales reutilizables';
  END IF;
  IF NEW.fecha_devolucion IS NULL OR NEW.fecha_devolucion<NEW.fecha_asignacion
     OR NEW.cantidad_devuelta IS NULL OR NEW.cantidad_devuelta<=0
     OR NEW.cantidad_danada IS NULL OR NEW.cantidad_danada<0
     OR NEW.cantidad_danada>NEW.cantidad_devuelta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T5: fechas y cantidades de devolucion invalidas';
  END IF;
  IF v_devuelta+NEW.cantidad_devuelta>v_asignada THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='T5: devoluciones acumuladas superan cantidad entregada';
  END IF;
END$$
DELIMITER ;

-- INSPECCION DE LOS 5 TRIGGERS:
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE() AND TRIGGER_NAME LIKE 'trg_0%'
ORDER BY TRIGGER_NAME;
-- Los triggers se prueban al ejecutar inserciones validas/invalidas en transacciones.
-- Nota: un trigger BEFORE INSERT no valida modificaciones hechas con UPDATE.
