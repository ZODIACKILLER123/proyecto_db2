-- ================================================================
-- FUNCIONES BASE DE DATOS II / EMPRESA RECOLECTORA / MySQL 8.0
-- Instalar DESPUES de empresa_recolectora_corregida_completa.sql
-- 14 funciones basicas + 10 intermedias + 5 complejas (JSON).
-- SOLO LECTURA: no modifican registros.
-- Las cantidades de carga, peso y desgaste de la muestra son SIMULADAS.
-- Cobertura = contenedores distintos atendidos al menos una vez en periodo.
-- Dias de trabajo = fechas distintas registradas en TRABAJA.
-- ================================================================
USE empresa_recolectora;
DELIMITER $$

-- BASICA: f_b_total_contenedores_zona
DROP FUNCTION IF EXISTS f_b_total_contenedores_zona$$
CREATE FUNCTION f_b_total_contenedores_zona(p_zona INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COUNT(*) INTO v FROM CONTENEDOR c
    JOIN VIA vi ON vi.idVia=c.idVia WHERE vi.idZona=p_zona;
    RETURN v;
END$$

-- BASICA: f_b_contenedores_atendidos_zona
DROP FUNCTION IF EXISTS f_b_contenedores_atendidos_zona$$
CREATE FUNCTION f_b_contenedores_atendidos_zona(p_zona INT, p_desde DATE, p_hasta DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COUNT(DISTINCT rc.idContenedor) INTO v FROM RECOLECTA rc
    JOIN CONTENEDOR c ON c.idContenedor=rc.idContenedor
    JOIN VIA vi ON vi.idVia=c.idVia
    WHERE vi.idZona=p_zona AND rc.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_personal_zona
DROP FUNCTION IF EXISTS f_b_personal_zona$$
CREATE FUNCTION f_b_personal_zona(p_zona INT, p_desde DATE, p_hasta DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COUNT(DISTINCT t.idrecolector) INTO v FROM TRABAJA t
    WHERE t.idZona=p_zona AND t.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_botadero_descargado
DROP FUNCTION IF EXISTS f_b_botadero_descargado$$
CREATE FUNCTION f_b_botadero_descargado(p_botadero INT)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v DECIMAL(15,2) DEFAULT 0;
    SELECT COALESCE(SUM(d.cantidad_kg),0) INTO v FROM DESCARGA_BOTADERO d
    WHERE d.idBotadero=p_botadero AND d.estado='Confirmada';
    RETURN v;
END$$

-- BASICA: f_b_capacidad_flota_botadero
DROP FUNCTION IF EXISTS f_b_capacidad_flota_botadero$$
CREATE FUNCTION f_b_capacidad_flota_botadero(p_botadero INT)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v DECIMAL(15,2) DEFAULT 0;
    SELECT COALESCE(SUM(t.capacidad_kg),0) INTO v FROM TRANSPORTE t
    WHERE t.idBotadero=p_botadero AND t.estado='Operativo';
    RETURN v;
END$$

-- BASICA: f_b_recolector_kg
DROP FUNCTION IF EXISTS f_b_recolector_kg$$
CREATE FUNCTION f_b_recolector_kg(p_recolector INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v DECIMAL(15,2) DEFAULT 0;
    SELECT COALESCE(SUM(rc.cantidad_kg),0) INTO v FROM RECOLECTA rc
    WHERE rc.idrecolector=p_recolector AND rc.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_recolector_dias
DROP FUNCTION IF EXISTS f_b_recolector_dias$$
CREATE FUNCTION f_b_recolector_dias(p_recolector INT, p_desde DATE, p_hasta DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COUNT(DISTINCT t.fecha) INTO v FROM TRABAJA t
    WHERE t.idrecolector=p_recolector AND t.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_recolector_operaciones
DROP FUNCTION IF EXISTS f_b_recolector_operaciones$$
CREATE FUNCTION f_b_recolector_operaciones(p_recolector INT, p_desde DATE, p_hasta DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COUNT(*) INTO v FROM RECOLECTA rc
    WHERE rc.idrecolector=p_recolector AND rc.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_material_costo_entregado
DROP FUNCTION IF EXISTS f_b_material_costo_entregado$$
CREATE FUNCTION f_b_material_costo_entregado(p_persona INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v DECIMAL(15,2) DEFAULT 0;
    SELECT COALESCE(SUM(d.cantidad*d.precio_unitario_asignacion),0) INTO v
    FROM DISPONE d WHERE d.idPersona=p_persona AND d.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_material_unidades_entregadas
DROP FUNCTION IF EXISTS f_b_material_unidades_entregadas$$
CREATE FUNCTION f_b_material_unidades_entregadas(p_persona INT, p_desde DATE, p_hasta DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COALESCE(SUM(d.cantidad),0) INTO v FROM DISPONE d
    WHERE d.idPersona=p_persona AND d.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_material_unidades_danadas
DROP FUNCTION IF EXISTS f_b_material_unidades_danadas$$
CREATE FUNCTION f_b_material_unidades_danadas(p_persona INT, p_desde DATE, p_hasta DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COALESCE(SUM(x.cantidad_danada),0) INTO v FROM DEVOLUCION_MATERIAL x
    WHERE x.idPersona=p_persona AND x.fecha_asignacion BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- BASICA: f_b_contenedores_ruta
DROP FUNCTION IF EXISTS f_b_contenedores_ruta$$
CREATE FUNCTION f_b_contenedores_ruta(p_ruta INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COUNT(DISTINCT i.idContenedor) INTO v FROM INTEGRA i WHERE i.idRuta=p_ruta;
    RETURN v;
END$$

-- BASICA: f_b_atendidos_ruta
DROP FUNCTION IF EXISTS f_b_atendidos_ruta$$
CREATE FUNCTION f_b_atendidos_ruta(p_ruta INT, p_desde DATE, p_hasta DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT COUNT(DISTINCT rc.idContenedor) INTO v FROM RECOLECTA rc
    WHERE rc.idRuta=p_ruta AND rc.fecha BETWEEN p_desde AND p_hasta
      AND EXISTS (SELECT 1 FROM INTEGRA i WHERE i.idRuta=p_ruta
                  AND i.idContenedor=rc.idContenedor);
    RETURN v;
END$$

-- BASICA: f_b_kg_ruta
DROP FUNCTION IF EXISTS f_b_kg_ruta$$
CREATE FUNCTION f_b_kg_ruta(p_ruta INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v DECIMAL(15,2) DEFAULT 0;
    SELECT COALESCE(SUM(rc.cantidad_kg),0) INTO v FROM RECOLECTA rc
    WHERE rc.idRuta=p_ruta AND rc.fecha BETWEEN p_desde AND p_hasta;
    RETURN v;
END$$

-- INTERMEDIA: f_i_cobertura_zona
DROP FUNCTION IF EXISTS f_i_cobertura_zona$$
CREATE FUNCTION f_i_cobertura_zona(p_zona INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(7,2)
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SET v_total=f_b_total_contenedores_zona(p_zona);
    IF v_total=0 THEN RETURN 0; END IF;
    RETURN LEAST(100,ROUND(100.0*f_b_contenedores_atendidos_zona(p_zona,p_desde,p_hasta)/v_total,2));
END$$

-- INTERMEDIA: f_i_carga_por_recolector_zona
DROP FUNCTION IF EXISTS f_i_carga_por_recolector_zona$$
CREATE FUNCTION f_i_carga_por_recolector_zona(p_zona INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_personal INT;
    SET v_personal=f_b_personal_zona(p_zona,p_desde,p_hasta);
    IF v_personal=0 THEN RETURN NULL; END IF;
    RETURN ROUND(f_b_total_contenedores_zona(p_zona)/v_personal,2);
END$$

-- INTERMEDIA: f_i_ocupacion_botadero
DROP FUNCTION IF EXISTS f_i_ocupacion_botadero$$
CREATE FUNCTION f_i_ocupacion_botadero(p_botadero INT)
RETURNS DECIMAL(7,2)
READS SQL DATA
BEGIN
    DECLARE v_max DECIMAL(15,2);
    DECLARE v_used DECIMAL(15,2);
    SELECT capacidad_maxima_kg,capacidad_utilizada INTO v_max,v_used
    FROM BOTADERO WHERE idBotadero=p_botadero;
    IF v_max IS NULL OR v_max<=0 THEN RETURN NULL; END IF;
    RETURN ROUND(100*v_used/v_max,2);
END$$

-- INTERMEDIA: f_i_margen_botadero
DROP FUNCTION IF EXISTS f_i_margen_botadero$$
CREATE FUNCTION f_i_margen_botadero(p_botadero INT)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v DECIMAL(15,2);
    SELECT GREATEST(0,capacidad_maxima_kg-capacidad_utilizada) INTO v
    FROM BOTADERO WHERE idBotadero=p_botadero;
    RETURN v;
END$$

-- INTERMEDIA: f_i_kg_por_dia_personal
DROP FUNCTION IF EXISTS f_i_kg_por_dia_personal$$
CREATE FUNCTION f_i_kg_por_dia_personal(p_recolector INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v_dias INT;
    SET v_dias=f_b_recolector_dias(p_recolector,p_desde,p_hasta);
    IF v_dias=0 THEN RETURN NULL; END IF;
    RETURN ROUND(f_b_recolector_kg(p_recolector,p_desde,p_hasta)/v_dias,2);
END$$

-- INTERMEDIA: f_i_operaciones_por_dia
DROP FUNCTION IF EXISTS f_i_operaciones_por_dia$$
CREATE FUNCTION f_i_operaciones_por_dia(p_recolector INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_dias INT;
    SET v_dias=f_b_recolector_dias(p_recolector,p_desde,p_hasta);
    IF v_dias=0 THEN RETURN NULL; END IF;
    RETURN ROUND(f_b_recolector_operaciones(p_recolector,p_desde,p_hasta)/v_dias,2);
END$$

-- INTERMEDIA: f_i_desgaste_material
DROP FUNCTION IF EXISTS f_i_desgaste_material$$
CREATE FUNCTION f_i_desgaste_material(p_persona INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(7,2)
READS SQL DATA
BEGIN
    DECLARE v_n INT;
    SET v_n=f_b_material_unidades_entregadas(p_persona,p_desde,p_hasta);
    IF v_n=0 THEN RETURN NULL; END IF;
    RETURN ROUND(100.0*f_b_material_unidades_danadas(p_persona,p_desde,p_hasta)/v_n,2);
END$$

-- INTERMEDIA: f_i_costo_por_unidad_entregada
DROP FUNCTION IF EXISTS f_i_costo_por_unidad_entregada$$
CREATE FUNCTION f_i_costo_por_unidad_entregada(p_persona INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v_n INT;
    SET v_n=f_b_material_unidades_entregadas(p_persona,p_desde,p_hasta);
    IF v_n=0 THEN RETURN NULL; END IF;
    RETURN ROUND(f_b_material_costo_entregado(p_persona,p_desde,p_hasta)/v_n,2);
END$$

-- INTERMEDIA: f_i_cobertura_ruta
DROP FUNCTION IF EXISTS f_i_cobertura_ruta$$
CREATE FUNCTION f_i_cobertura_ruta(p_ruta INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(7,2)
READS SQL DATA
BEGIN
    DECLARE v_n INT;
    SET v_n=f_b_contenedores_ruta(p_ruta);
    IF v_n=0 THEN RETURN 0; END IF;
    RETURN LEAST(100,ROUND(100.0*f_b_atendidos_ruta(p_ruta,p_desde,p_hasta)/v_n,2));
END$$

-- INTERMEDIA: f_i_kg_por_km_ruta
DROP FUNCTION IF EXISTS f_i_kg_por_km_ruta$$
CREATE FUNCTION f_i_kg_por_km_ruta(p_ruta INT, p_desde DATE, p_hasta DATE)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v_km DECIMAL(12,2);
    SELECT distancia_km INTO v_km FROM RUTA WHERE idRuta=p_ruta;
    IF v_km IS NULL OR v_km<=0 THEN RETURN NULL; END IF;
    -- Indicador = kg del periodo / longitud nominal de ruta, NO kg/km reales recorridos.
    RETURN ROUND(f_b_kg_ruta(p_ruta,p_desde,p_hasta)/v_km,2);
END$$

-- COMPLEJA 1/5: f_analisis_operativo_zona
DROP FUNCTION IF EXISTS f_analisis_operativo_zona$$
CREATE FUNCTION f_analisis_operativo_zona(p_zona INT, p_desde DATE, p_hasta DATE)
RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_cob DECIMAL(7,2);
    DECLARE v_carga DECIMAL(12,2);
    DECLARE v_total INT;
    DECLARE v_atendidos INT;
    DECLARE v_personal INT;
    DECLARE v_rutas INT;
    DECLARE v_vias INT;
    IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Periodo invalido para zona';
    END IF;
    SELECT nombre INTO v_nombre FROM ZONA WHERE idZona=p_zona;
    IF v_nombre IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Zona inexistente'; END IF;
    SET v_total=f_b_total_contenedores_zona(p_zona);
    SET v_atendidos=f_b_contenedores_atendidos_zona(p_zona,p_desde,p_hasta);
    SET v_personal=f_b_personal_zona(p_zona,p_desde,p_hasta);
    SET v_cob=f_i_cobertura_zona(p_zona,p_desde,p_hasta);
    SET v_carga=f_i_carga_por_recolector_zona(p_zona,p_desde,p_hasta);
    SELECT COUNT(*) INTO v_rutas FROM RUTA WHERE idZona=p_zona;
    SELECT COUNT(*) INTO v_vias FROM VIA WHERE idZona=p_zona;
    RETURN JSON_OBJECT('idZona',p_zona,'nombre',v_nombre,'desde',p_desde,'hasta',p_hasta,
       'vias',v_vias,'rutas',v_rutas,'contenedores',v_total,
       'atendidos',v_atendidos,'recolectores_distintos',v_personal,
       'cobertura_pct',v_cob,'contenedores_por_recolector',v_carga,
       'diagnostico',CASE WHEN v_total=0 THEN 'SIN CONTENEDORES'
           WHEN v_personal=0 THEN 'SIN PERSONAL'
           WHEN v_cob>=90 THEN 'ALTA COBERTURA'
           WHEN v_cob>=60 THEN 'COBERTURA MEDIA' ELSE 'COBERTURA BAJA' END);

END$$

-- COMPLEJA 2/5: f_analisis_capacidad_botadero
DROP FUNCTION IF EXISTS f_analisis_capacidad_botadero$$
CREATE FUNCTION f_analisis_capacidad_botadero(p_botadero INT)
RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_max DECIMAL(15,2);
    DECLARE v_used DECIMAL(15,2);
    DECLARE v_pct DECIMAL(7,2);
    DECLARE v_libre DECIMAL(15,2);
    DECLARE v_descargado DECIMAL(15,2);
    DECLARE v_flota DECIMAL(15,2);
    DECLARE v_activos INT DEFAULT 0;
    SELECT nombre,capacidad_maxima_kg,capacidad_utilizada
       INTO v_nombre,v_max,v_used FROM BOTADERO WHERE idBotadero=p_botadero;
    IF v_nombre IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Botadero inexistente'; END IF;
    SET v_pct=f_i_ocupacion_botadero(p_botadero);
    SET v_libre=f_i_margen_botadero(p_botadero);
    SET v_descargado=f_b_botadero_descargado(p_botadero);
    SET v_flota=f_b_capacidad_flota_botadero(p_botadero);
    SELECT COUNT(*) INTO v_activos FROM TRANSPORTE
    WHERE idBotadero=p_botadero AND estado='Operativo';
    RETURN JSON_OBJECT('idBotadero',p_botadero,'nombre',v_nombre,
      'capacidad_maxima_kg',v_max,'capacidad_utilizada_kg',v_used,
      'capacidad_disponible_kg',v_libre,'ocupacion_pct',v_pct,
      'descargas_confirmadas_kg',v_descargado,'flota_operativa',v_activos,
      'capacidad_nominal_flota_kg',v_flota,
      'estado',CASE WHEN v_pct>=100 THEN 'SATURADO'
                    WHEN v_pct>=90 THEN 'CRITICO'
                    WHEN v_pct>=70 THEN 'ADVERTENCIA' ELSE 'DISPONIBLE' END);

END$$

-- COMPLEJA 3/5: f_analisis_rendimiento_personal
DROP FUNCTION IF EXISTS f_analisis_rendimiento_personal$$
CREATE FUNCTION f_analisis_rendimiento_personal(p_recolector INT, p_desde DATE, p_hasta DATE)
RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(180);
    DECLARE v_kg DECIMAL(15,2);
    DECLARE v_dias INT;
    DECLARE v_ops INT;
    DECLARE v_diario DECIMAL(15,2);
    DECLARE v_opsdia DECIMAL(12,2);
    IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
       SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Periodo invalido para personal';
    END IF;
    SELECT CONCAT(p.nombre,' ',p.paterno,' ',p.materno) INTO v_nombre
    FROM PERSONA p JOIN RECOLECTOR r ON r.idrecolector=p.idPersona
    WHERE r.idrecolector=p_recolector;
    IF v_nombre IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Recolector inexistente'; END IF;
    SET v_kg=f_b_recolector_kg(p_recolector,p_desde,p_hasta);
    SET v_dias=f_b_recolector_dias(p_recolector,p_desde,p_hasta);
    SET v_ops=f_b_recolector_operaciones(p_recolector,p_desde,p_hasta);
    SET v_diario=f_i_kg_por_dia_personal(p_recolector,p_desde,p_hasta);
    SET v_opsdia=f_i_operaciones_por_dia(p_recolector,p_desde,p_hasta);
    RETURN JSON_OBJECT('idrecolector',p_recolector,'nombre',v_nombre,'desde',p_desde,'hasta',p_hasta,
      'kg_recolectados',v_kg,'dias_asignados',v_dias,'operaciones',v_ops,
      'kg_por_dia_asignado',v_diario,'operaciones_por_dia_asignado',v_opsdia,
      'clasificacion',CASE WHEN v_dias=0 THEN 'SIN JORNADAS'
        WHEN v_ops=0 THEN 'SIN RECOLECCIONES'
        ELSE 'ACTIVIDAD REGISTRADA' END);
    -- No se califica rendimiento alto/bajo sin metas acordadas.

END$$

-- COMPLEJA 4/5: f_analisis_costos_materiales
DROP FUNCTION IF EXISTS f_analisis_costos_materiales$$
CREATE FUNCTION f_analisis_costos_materiales(p_persona INT, p_desde DATE, p_hasta DATE)
RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(180);
    DECLARE v_total DECIMAL(15,2);
    DECLARE v_cantidad INT;
    DECLARE v_danadas INT;
    DECLARE v_desgaste DECIMAL(7,2);
    DECLARE v_costo_prom DECIMAL(15,2);
    DECLARE v_devoluciones INT;
    IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Periodo invalido para materiales';
    END IF;
    SELECT CONCAT(nombre,' ',paterno,' ',materno) INTO v_nombre FROM PERSONA WHERE idPersona=p_persona;
    IF v_nombre IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Persona inexistente'; END IF;
    SET v_total=f_b_material_costo_entregado(p_persona,p_desde,p_hasta);
    SET v_cantidad=f_b_material_unidades_entregadas(p_persona,p_desde,p_hasta);
    SET v_danadas=f_b_material_unidades_danadas(p_persona,p_desde,p_hasta);
    SET v_desgaste=f_i_desgaste_material(p_persona,p_desde,p_hasta);
    SET v_costo_prom=f_i_costo_por_unidad_entregada(p_persona,p_desde,p_hasta);
    SELECT COALESCE(SUM(x.cantidad_devuelta),0) INTO v_devoluciones FROM DEVOLUCION_MATERIAL x
    WHERE x.idPersona=p_persona AND x.fecha_asignacion BETWEEN p_desde AND p_hasta;
    RETURN JSON_OBJECT('idPersona',p_persona,'nombre',v_nombre,'desde',p_desde,'hasta',p_hasta,
      'unidades_entregadas',v_cantidad,'unidades_devueltas',v_devoluciones,
      'unidades_danadas',v_danadas,'costo_entregas_bs',v_total,
      'costo_medio_por_unidad_bs',v_costo_prom,'desgaste_pct_sobre_entregadas',v_desgaste,
      'observacion',CASE WHEN v_cantidad=0 THEN 'SIN ENTREGAS'
        WHEN v_devoluciones=0 THEN 'SIN DEVOLUCIONES REGISTRADAS'
        ELSE 'DEVOLUCIONES REGISTRADAS' END);
    -- El desgaste mide danados / entregados en el periodo; no uso real ni vida util.

END$$

-- COMPLEJA 5/5: f_analisis_eficiencia_rutas
DROP FUNCTION IF EXISTS f_analisis_eficiencia_rutas$$
CREATE FUNCTION f_analisis_eficiencia_rutas(p_ruta INT, p_desde DATE, p_hasta DATE)
RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE v_zona INT;
    DECLARE v_dist DECIMAL(12,2);
    DECLARE v_total INT;
    DECLARE v_atendidos INT;
    DECLARE v_kg DECIMAL(15,2);
    DECLARE v_cobertura DECIMAL(7,2);
    DECLARE v_ind DECIMAL(15,2);
    DECLARE v_salidas INT;
    IF p_desde IS NULL OR p_hasta IS NULL OR p_desde>p_hasta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Periodo invalido para rutas';
    END IF;
    SELECT idZona,distancia_km INTO v_zona,v_dist FROM RUTA WHERE idRuta=p_ruta;
    IF v_zona IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Ruta inexistente'; END IF;
    SET v_total=f_b_contenedores_ruta(p_ruta);
    SET v_atendidos=f_b_atendidos_ruta(p_ruta,p_desde,p_hasta);
    SET v_kg=f_b_kg_ruta(p_ruta,p_desde,p_hasta);
    SET v_cobertura=f_i_cobertura_ruta(p_ruta,p_desde,p_hasta);
    SET v_ind=f_i_kg_por_km_ruta(p_ruta,p_desde,p_hasta);
    SELECT COUNT(*) INTO v_salidas FROM PASA_POR pp
      WHERE pp.idRuta=p_ruta AND pp.fecha BETWEEN p_desde AND p_hasta;
    RETURN JSON_OBJECT('idRuta',p_ruta,'idZona',v_zona,'desde',p_desde,'hasta',p_hasta,
      'distancia_nominal_km',v_dist,'contenedores',v_total,'atendidos',v_atendidos,
      'pendientes',GREATEST(v_total-v_atendidos,0),'cobertura_pct',v_cobertura,
      'kg_recolectados',v_kg,'salidas_registradas',v_salidas,
      'kg_por_km_nominal',v_ind,
      'diagnostico',CASE WHEN v_total=0 THEN 'SIN CONTENEDORES'
         WHEN v_cobertura>=90 THEN 'COBERTURA ALTA'
         WHEN v_cobertura>=60 THEN 'COBERTURA MEDIA' ELSE 'COBERTURA BAJA' END);

END$$

DELIMITER ;

-- ================================================================
-- PRUEBAS: fechas disponibles en los datos de ejemplo 2026-09
-- ================================================================
SELECT JSON_PRETTY(f_analisis_operativo_zona(1,'2026-09-01','2026-09-30')) AS zona;
SELECT JSON_PRETTY(f_analisis_capacidad_botadero(1)) AS botadero;
SELECT JSON_PRETTY(f_analisis_rendimiento_personal(101,'2026-09-01','2026-09-30')) AS personal;
SELECT JSON_PRETTY(f_analisis_costos_materiales(150,'2026-01-01','2026-09-30')) AS materiales;
SELECT JSON_PRETTY(f_analisis_eficiencia_rutas(1,'2026-09-01','2026-09-30')) AS ruta;
