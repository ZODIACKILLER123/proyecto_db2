-- ============================================================
-- 01_schema.sql  |  CREACION DE TABLAS (MySQL 8.0.16+)
-- UNIVERSO DEL DISCURSO: EMPRESA RECOLECTORA DE BASURA
-- Restricciones 1:N mediante FK; N:M mediante tablas puente con fecha.
-- INTEGRA es relacion ternaria (Ruta, Via, Contenedor).
-- ============================================================

CREATE DATABASE IF NOT EXISTS empresa_recolectora
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE empresa_recolectora;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS HISTORIAL_ASIGNACION;
DROP TABLE IF EXISTS DESCARGA_BOTADERO;
DROP TABLE IF EXISTS DEVOLUCION_MATERIAL;
DROP TABLE IF EXISTS COMPRA_MATERIAL;
DROP TABLE IF EXISTS TRABAJA;
DROP TABLE IF EXISTS INTEGRA;
DROP TABLE IF EXISTS PASA_POR;
DROP TABLE IF EXISTS RECOLECTA;
DROP TABLE IF EXISTS DISPONE;
DROP TABLE IF EXISTS RECOLECTOR;
DROP TABLE IF EXISTS CONDUCTOR;
DROP TABLE IF EXISTS RUTA;
DROP TABLE IF EXISTS TRANSPORTE;
DROP TABLE IF EXISTS CONTENEDOR;
DROP TABLE IF EXISTS VIA;
DROP TABLE IF EXISTS MATERIAL_TRABAJO;
DROP TABLE IF EXISTS PERSONA;
DROP TABLE IF EXISTS BOTADERO;
DROP TABLE IF EXISTS ZONA;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE ZONA (
    idZona INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ubicacion VARCHAR(150) NOT NULL,
    cantidad_calles INT NOT NULL CHECK (cantidad_calles >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE BOTADERO (
    idBotadero INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    extencion_terreno VARCHAR(50) NOT NULL,
    extension_hectareas DECIMAL(10,2) NOT NULL DEFAULT 0,
    capacidad_maxima_kg DECIMAL(15,2) NOT NULL DEFAULT 0,
    capacidad_utilizada DECIMAL(15,2) NOT NULL DEFAULT 0,
    estado_operativo VARCHAR(50) NOT NULL DEFAULT 'Disponible'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PERSONA (
    idPersona INT PRIMARY KEY,
    ci VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    paterno VARCHAR(50) NOT NULL,
    materno VARCHAR(50) NOT NULL,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    turno VARCHAR(20) NOT NULL,
    estado_laboral VARCHAR(100) NOT NULL DEFAULT 'Activo',
    fecha_contratacion DATE NOT NULL DEFAULT '2024-01-01'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE MATERIAL_TRABAJO (
    idMaterial INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    estado VARCHAR(30) NOT NULL,
    precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    tipo_uso VARCHAR(100) NOT NULL DEFAULT 'Reutilizable'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE VIA (
    idVia INT PRIMARY KEY,
    descripcion VARCHAR(150) NOT NULL,
    calle_avenida VARCHAR(10) NOT NULL,
    idZona INT NOT NULL,
    FOREIGN KEY (idZona) REFERENCES ZONA(idZona)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CONTENEDOR (
    idContenedor INT PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    capacidad VARCHAR(30) NOT NULL,
    capacidad_litros DECIMAL(12,2) NOT NULL DEFAULT 0,
    capacidad_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_operativo VARCHAR(50) NOT NULL DEFAULT 'Disponible',
    tamanio VARCHAR(30) NOT NULL,
    idVia INT NOT NULL,
    FOREIGN KEY (idVia) REFERENCES VIA(idVia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CONDUCTOR (
    idconductor INT PRIMARY KEY,
    nro_licencia VARCHAR(30) UNIQUE NOT NULL,
    categoria_licencia VARCHAR(10) NOT NULL,
    FOREIGN KEY (idconductor) REFERENCES PERSONA(idPersona)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE TRANSPORTE (
    idTransporte INT PRIMARY KEY,
    placa VARCHAR(15) UNIQUE NOT NULL,
    tipo_transporte VARCHAR(50) NOT NULL,
    capacidad VARCHAR(30) NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'Operativo',
    -- CORREGIDO: antes no tenia DEFAULT y los INSERT no lo enviaban (error 1364)
    capacidad_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
    carga_actual_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
    idconductor INT NOT NULL,
    idBotadero INT NOT NULL,
    FOREIGN KEY (idconductor) REFERENCES CONDUCTOR(idconductor),
    FOREIGN KEY (idBotadero) REFERENCES BOTADERO(idBotadero)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE RUTA (
    idRuta INT PRIMARY KEY,
    distancia_recorrida VARCHAR(30) NOT NULL,
    Horario VARCHAR(50) NOT NULL,
    idZona INT NOT NULL,
    distancia_km DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_operativo VARCHAR(50) NOT NULL DEFAULT 'Activa',
    FOREIGN KEY (idZona) REFERENCES ZONA(idZona)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE RECOLECTOR (
    idrecolector INT PRIMARY KEY,
    tipo_empleado VARCHAR(50) NOT NULL,
    sueldo DECIMAL(10,2) NOT NULL CHECK (sueldo >= 0),
    idTransporte INT NOT NULL,
    FOREIGN KEY (idrecolector) REFERENCES PERSONA(idPersona),
    FOREIGN KEY (idTransporte) REFERENCES TRANSPORTE(idTransporte)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE DISPONE (
    idPersona INT NOT NULL,
    idMaterial INT NOT NULL,
    fecha DATE NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario_asignacion DECIMAL(10,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (idPersona, idMaterial, fecha),
    FOREIGN KEY (idPersona) REFERENCES PERSONA(idPersona),
    FOREIGN KEY (idMaterial) REFERENCES MATERIAL_TRABAJO(idMaterial)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE RECOLECTA (
    idRecoleccion BIGINT AUTO_INCREMENT PRIMARY KEY,
    idrecolector INT NOT NULL,
    idContenedor INT NOT NULL,
    fecha DATE NOT NULL,
    cantidad_kg DECIMAL(12,2),
    idTransporte INT NULL,
    idRuta INT NULL,
    hora_recoleccion TIME,
    INDEX idx_recolecta_recolector_fecha (idrecolector, fecha),
    INDEX idx_recolecta_contenedor_fecha (idContenedor, fecha),
    FOREIGN KEY (idrecolector) REFERENCES RECOLECTOR(idrecolector),
    FOREIGN KEY (idContenedor) REFERENCES CONTENEDOR(idContenedor),
    FOREIGN KEY (idTransporte) REFERENCES TRANSPORTE(idTransporte),
    FOREIGN KEY (idRuta) REFERENCES RUTA(idRuta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PASA_POR (
    idTransporte INT NOT NULL,
    idRuta INT NOT NULL,
    fecha DATE NOT NULL,
    PRIMARY KEY (idTransporte, idRuta, fecha),
    FOREIGN KEY (idTransporte) REFERENCES TRANSPORTE(idTransporte),
    FOREIGN KEY (idRuta) REFERENCES RUTA(idRuta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE INTEGRA (
    idRuta INT NOT NULL,
    idVia INT NOT NULL,
    idContenedor INT NOT NULL,
    PRIMARY KEY (idRuta, idVia, idContenedor),
    FOREIGN KEY (idRuta) REFERENCES RUTA(idRuta),
    FOREIGN KEY (idVia) REFERENCES VIA(idVia),
    FOREIGN KEY (idContenedor) REFERENCES CONTENEDOR(idContenedor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Segun modelo relacional: TRABAJA(idrecolector, idZona, fecha).
CREATE TABLE TRABAJA (
    idrecolector INT NOT NULL,
    idZona INT NOT NULL,
    fecha DATE NOT NULL,
    PRIMARY KEY (idrecolector, idZona, fecha),
    FOREIGN KEY (idrecolector) REFERENCES RECOLECTOR(idrecolector),
    FOREIGN KEY (idZona) REFERENCES ZONA(idZona)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE COMPRA_MATERIAL (
    idCompra INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
    idMaterial INT NOT NULL,
    proveedor VARCHAR(100) NOT NULL,
    fecha DATE NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    total DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (idMaterial) REFERENCES MATERIAL_TRABAJO(idMaterial),
    CHECK (cantidad > 0 AND precio_unitario >= 0 AND total >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE DEVOLUCION_MATERIAL (
    idDEvolucion INT AUTO_INCREMENT PRIMARY KEY,
    idPersona INT NOT NULL,
    idMaterial INT NOT NULL,
    fecha_asignacion DATE NOT NULL,
    fecha_devolucion DATE NOT NULL,
    cantidad_devuelta INT NOT NULL,
    cantidad_danada INT NOT NULL,
    estado_devolucion VARCHAR(30),
    FOREIGN KEY (idPersona, idMaterial, fecha_asignacion) REFERENCES DISPONE(idPersona, idMaterial, fecha),
    CHECK (cantidad_devuelta > 0 AND cantidad_danada >= 0 AND cantidad_danada <= cantidad_devuelta),
    CHECK (fecha_devolucion >= fecha_asignacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE DESCARGA_BOTADERO (
    idDescarga INT AUTO_INCREMENT PRIMARY KEY,
    idTransporte INT NOT NULL,
    idBotadero INT NOT NULL,
    fecha DATETIME NOT NULL,
    cantidad_kg DECIMAL(12,2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Confirmada',
    FOREIGN KEY (idTransporte) REFERENCES TRANSPORTE(idTransporte),
    FOREIGN KEY (idBotadero) REFERENCES BOTADERO(idBotadero),
    CHECK (cantidad_kg > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE HISTORIAL_ASIGNACION (
    idHistorial INT AUTO_INCREMENT PRIMARY KEY,
    idrecolector INT NOT NULL,
    idTransporte INT NOT NULL,
    idZona INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME,
    motivo VARCHAR(255),
    FOREIGN KEY (idrecolector) REFERENCES RECOLECTOR(idrecolector),
    FOREIGN KEY (idTransporte) REFERENCES TRANSPORTE(idTransporte),
    FOREIGN KEY (idZona) REFERENCES ZONA(idZona),
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- INSERCION DE DATOS (orden respetando llaves foraneas)
-- ============================================================
START TRANSACTION;


-- ZONA  (100 filas)
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (1, 'Auquisamana', 'La Paz - Zona Sur', 15);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (2, 'Munaypata', 'La Paz - Zona Norte', 32);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (3, 'Villa Adela', 'Ciudad de El Alto', 45);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (4, 'Rio Seco', 'Ciudad de El Alto', 37);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (5, 'Tupac Katari', 'Ciudad de El Alto', 40);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (6, 'Mallasilla', 'La Paz - Zona Sur', 7);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (7, 'Challapampa', 'La Paz - Zona Central', 25);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (8, 'Villa Tunari', 'Ciudad de El Alto', 20);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (9, 'Cosmos 79', 'Ciudad de El Alto', 38);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (10, 'Ballivian', 'Ciudad de El Alto', 29);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (11, 'Gran Poder', 'La Paz - Zona Oeste', 40);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (12, 'Villa Esperanza', 'Ciudad de El Alto', 11);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (13, 'Alto Lima', 'Ciudad de El Alto', 35);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (14, 'Villa Salome', 'La Paz - Zona Oeste', 32);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (15, 'Villa Bolivar', 'Ciudad de El Alto', 15);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (16, 'Pasankeri', 'La Paz - Zona Oeste', 26);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (17, 'Kantutani', 'La Paz - Zona Central', 15);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (18, 'Achumani', 'La Paz - Zona Sur', 38);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (19, 'Villa Santiago', 'Ciudad de El Alto', 8);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (20, 'Ovejuyo', 'La Paz - Zona Sur', 36);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (21, 'Mallasa', 'La Paz - Zona Sur', 6);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (22, 'Villa Copacabana', 'La Paz - Zona Norte', 9);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (23, 'Jupapina', 'La Paz - Zona Sur', 12);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (24, 'Cotahuma', 'La Paz - Zona Oeste', 28);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (25, 'Calacoto', 'La Paz - Zona Sur', 43);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (26, 'La Ceja', 'Ciudad de El Alto', 22);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (27, 'Villa Remedios', 'Ciudad de El Alto', 27);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (28, 'Alto Tembladerani', 'La Paz - Zona Central', 7);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (29, 'Alto Pampahasi', 'La Paz - Zona Norte', 16);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (30, 'Prado', 'La Paz - Zona Central', 38);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (31, 'Tacagua', 'La Paz - Zona Norte', 18);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (32, 'Alto Tacagua', 'La Paz - Zona Norte', 11);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (33, 'Alto Llojeta', 'La Paz - Zona Norte', 33);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (34, 'Villa Tupac Amaru', 'Ciudad de El Alto', 33);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (35, 'Chasquipampa', 'La Paz - Zona Sur', 18);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (36, 'Chuquiaguillo', 'La Paz - Zona Norte', 16);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (37, 'Pedregal', 'La Paz - Zona Sur', 21);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (38, 'Villa Armonia', 'La Paz - Zona Norte', 20);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (39, 'Franz Tamayo', 'Ciudad de El Alto', 37);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (40, 'Rosales', 'La Paz - Zona Central', 19);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (41, '16 de Julio', 'Ciudad de El Alto', 29);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (42, 'German Busch', 'Ciudad de El Alto', 16);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (43, 'Pura Pura', 'La Paz - Zona Norte', 40);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (44, 'Rosas Pampa', 'Ciudad de El Alto', 33);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (45, 'Cementerio', 'La Paz - Zona Oeste', 33);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (46, 'Ciudad Satelite', 'Ciudad de El Alto', 35);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (47, 'Casco Viejo', 'La Paz - Zona Central', 29);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (48, 'Villa Exaltacion', 'Ciudad de El Alto', 19);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (49, '3 de Mayo', 'Ciudad de El Alto', 25);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (50, 'San Jorge', 'La Paz - Zona Central', 34);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (51, 'Kupini', 'La Paz - Zona Norte', 41);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (52, 'Villa Mercedes', 'Ciudad de El Alto', 44);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (53, 'Bella Vista', 'La Paz - Zona Central', 36);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (54, 'Alto Obrajes', 'La Paz - Zona Sur', 11);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (55, 'Tembladerani', 'La Paz - Zona Central', 19);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (56, 'Villa Brasil', 'Ciudad de El Alto', 18);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (57, 'Villa San Antonio', 'La Paz - Zona Norte', 13);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (58, 'Santa Rosa', 'La Paz - Zona Central', 11);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (59, 'Bolognia', 'La Paz - Zona Sur', 28);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (60, 'Pampahasi', 'La Paz - Zona Norte', 45);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (61, 'Santiago Segundo', 'Ciudad de El Alto', 16);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (62, 'Villa Pabon', 'La Paz - Zona Norte', 13);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (63, 'Villa Tejada Rectangular', 'Ciudad de El Alto', 17);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (64, 'Bajo Llojeta', 'La Paz - Zona Norte', 19);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (65, 'Villa Fatima', 'La Paz - Zona Norte', 33);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (66, 'Alto Irpavi', 'La Paz - Zona Sur', 18);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (67, '12 de Octubre', 'Ciudad de El Alto', 33);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (68, 'Huayna Potosi', 'Ciudad de El Alto', 7);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (69, 'Los Andes', 'La Paz - Zona Oeste', 41);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (70, 'El Tejar', 'La Paz - Zona Oeste', 15);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (71, 'Mercedario', 'Ciudad de El Alto', 23);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (72, 'Miraflores', 'La Paz - Zona Central', 24);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (73, 'Obrajes', 'La Paz - Zona Sur', 29);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (74, 'Villa Bella', 'Ciudad de El Alto', 31);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (75, 'Llojeta', 'La Paz - Zona Norte', 6);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (76, 'Alto Sopocachi', 'La Paz - Zona Central', 36);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (77, 'Callapa', 'La Paz - Zona Oeste', 39);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (78, 'Sopocachi', 'La Paz - Zona Central', 35);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (79, 'Irpavi', 'La Paz - Zona Sur', 23);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (80, 'Villa Aroma', 'Ciudad de El Alto', 28);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (81, 'Chijini', 'La Paz - Zona Oeste', 37);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (82, 'Villa 14 de Septiembre', 'Ciudad de El Alto', 14);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (83, 'Ciudad Juvenil', 'Ciudad de El Alto', 12);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (84, 'Nuevos Horizontes', 'Ciudad de El Alto', 15);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (85, 'Villa Victoria', 'La Paz - Zona Norte', 41);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (86, 'Senkata', 'Ciudad de El Alto', 20);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (87, 'Bajo Pampahasi', 'La Paz - Zona Norte', 28);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (88, 'Villa Bolivia', 'Ciudad de El Alto', 35);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (89, 'Villa Dolores', 'Ciudad de El Alto', 30);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (90, 'Pacajes', 'Ciudad de El Alto', 44);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (91, 'Villa Nuevo Potosi', 'La Paz - Zona Norte', 43);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (92, 'Villa Tejada Triangular', 'Ciudad de El Alto', 9);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (93, 'San Miguel', 'La Paz - Zona Sur', 41);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (94, 'Seguencoma', 'La Paz - Zona Sur', 26);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (95, 'Los Pinos', 'La Paz - Zona Sur', 22);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (96, 'Villa Ingenio', 'Ciudad de El Alto', 11);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (97, 'Cota Cota', 'La Paz - Zona Sur', 35);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (98, 'Alpacoma', 'La Paz - Zona Oeste', 35);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (99, 'Alto Calacoto', 'La Paz - Zona Sur', 28);
INSERT INTO ZONA (idZona, nombre, ubicacion, cantidad_calles) VALUES (100, 'Vino Tinto', 'La Paz - Zona Norte', 40);

-- BOTADERO  (100 filas)
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (1, 'Relleno Sanitario Alpacoma', 'Camino a Alpacoma, Zona Oeste, La Paz', '36 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (2, 'Botadero Municipal Mallasa', 'Carretera a Mallasa km 12, La Paz', '14.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (3, 'Relleno Sanitario Villa Ingenio', 'Distrito 8, Villa Ingenio, El Alto', '65 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (4, 'Botadero Temporal Huayna Potosi', 'Camino a Huayna Potosi, km 14', '14.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (5, 'Botadero Temporal Alto Lima', 'Camino a Alto Lima, km 8', '8.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (6, 'Botadero Temporal Chuquiaguillo', 'Camino a Chuquiaguillo, km 9', '26.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (7, 'Botadero Temporal Villa Armonia', 'Camino a Villa Armonia, km 17', '10.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (8, 'Botadero Temporal Tupac Katari', 'Camino a Tupac Katari, km 3', '10.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (9, 'Botadero Temporal Gran Poder', 'Camino a Gran Poder, km 2', '8.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (10, 'Botadero Temporal Alto Sopocachi', 'Camino a Alto Sopocachi, km 4', '30.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (11, 'Botadero Temporal Mallasilla', 'Camino a Mallasilla, km 18', '23.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (12, 'Botadero Temporal Cosmos 79', 'Camino a Cosmos 79, km 12', '30.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (13, 'Botadero Temporal Vino Tinto', 'Camino a Vino Tinto, km 17', '22.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (14, 'Botadero Temporal Santa Rosa', 'Camino a Santa Rosa, km 7', '22.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (15, 'Botadero Temporal Obrajes', 'Camino a Obrajes, km 2', '11.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (16, 'Botadero Temporal Villa Salome', 'Camino a Villa Salome, km 6', '22.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (17, 'Botadero Temporal San Jorge', 'Camino a San Jorge, km 9', '8.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (18, 'Botadero Temporal Ciudad Juvenil', 'Camino a Ciudad Juvenil, km 10', '21.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (19, 'Botadero Temporal Villa Bella', 'Camino a Villa Bella, km 16', '10.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (20, 'Botadero Temporal Bolognia', 'Camino a Bolognia, km 18', '7.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (21, 'Botadero Temporal Irpavi', 'Camino a Irpavi, km 17', '20.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (22, 'Botadero Temporal Villa Pabon', 'Camino a Villa Pabon, km 8', '17.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (23, 'Botadero Temporal El Tejar', 'Camino a El Tejar, km 18', '13.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (24, 'Botadero Temporal Villa Adela', 'Camino a Villa Adela, km 18', '14.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (25, 'Botadero Temporal Ovejuyo', 'Camino a Ovejuyo, km 3', '9.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (26, 'Botadero Temporal 16 de Julio', 'Camino a 16 de Julio, km 1', '15.6 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (27, 'Botadero Temporal Achumani', 'Camino a Achumani, km 18', '4.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (28, 'Botadero Temporal Rio Seco', 'Camino a Rio Seco, km 6', '7.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (29, 'Botadero Temporal Villa Bolivia', 'Camino a Villa Bolivia, km 6', '19.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (30, 'Botadero Temporal Kupini', 'Camino a Kupini, km 17', '26.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (31, 'Botadero Temporal Villa Esperanza', 'Camino a Villa Esperanza, km 13', '10.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (32, 'Botadero Temporal Villa Copacabana', 'Camino a Villa Copacabana, km 15', '4.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (33, 'Botadero Temporal Los Andes', 'Camino a Los Andes, km 12', '4.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (34, 'Botadero Temporal Alto Llojeta', 'Camino a Alto Llojeta, km 17', '26.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (35, 'Botadero Temporal Villa Aroma', 'Camino a Villa Aroma, km 16', '29.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (36, 'Botadero Temporal San Miguel', 'Camino a San Miguel, km 11', '7.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (37, 'Botadero Temporal Ballivian', 'Camino a Ballivian, km 18', '5.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (38, 'Botadero Temporal Pasankeri', 'Camino a Pasankeri, km 1', '28.6 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (39, 'Botadero Temporal Pura Pura', 'Camino a Pura Pura, km 3', '24.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (40, 'Botadero Temporal Senkata', 'Camino a Senkata, km 14', '23.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (41, 'Botadero Temporal Bajo Llojeta', 'Camino a Bajo Llojeta, km 11', '18.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (42, 'Botadero Temporal Villa 14 de Septiembre', 'Camino a Villa 14 de Septiembre, km 3', '25.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (43, 'Botadero Temporal Tacagua', 'Camino a Tacagua, km 1', '22.4 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (44, 'Botadero Temporal Alto Irpavi', 'Camino a Alto Irpavi, km 8', '5.6 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (45, 'Botadero Temporal Mallasa', 'Camino a Mallasa, km 8', '11.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (46, 'Botadero Temporal Ciudad Satelite', 'Camino a Ciudad Satelite, km 6', '11.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (47, 'Botadero Temporal Prado', 'Camino a Prado, km 1', '2.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (48, 'Botadero Temporal Cementerio', 'Camino a Cementerio, km 6', '24.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (49, 'Botadero Temporal Pampahasi', 'Camino a Pampahasi, km 4', '9.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (50, 'Botadero Temporal La Ceja', 'Camino a La Ceja, km 6', '21.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (51, 'Botadero Temporal Tembladerani', 'Camino a Tembladerani, km 16', '5.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (52, 'Botadero Temporal Chijini', 'Camino a Chijini, km 5', '2.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (53, 'Botadero Temporal Nuevos Horizontes', 'Camino a Nuevos Horizontes, km 17', '11.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (54, 'Botadero Temporal Villa Remedios', 'Camino a Villa Remedios, km 14', '10.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (55, 'Botadero Temporal Mercedario', 'Camino a Mercedario, km 15', '21.4 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (56, 'Botadero Temporal Alto Tacagua', 'Camino a Alto Tacagua, km 5', '14.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (57, 'Botadero Temporal Bella Vista', 'Camino a Bella Vista, km 15', '20.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (58, 'Botadero Temporal Franz Tamayo', 'Camino a Franz Tamayo, km 4', '9.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (59, 'Botadero Temporal Villa Dolores', 'Camino a Villa Dolores, km 15', '27.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (60, 'Botadero Temporal Alto Pampahasi', 'Camino a Alto Pampahasi, km 13', '10.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (61, 'Botadero Temporal Alto Calacoto', 'Camino a Alto Calacoto, km 15', '25.4 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (62, 'Botadero Temporal Villa Tunari', 'Camino a Villa Tunari, km 9', '16.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (63, 'Botadero Temporal Cota Cota', 'Camino a Cota Cota, km 14', '17.4 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (64, 'Botadero Temporal Santiago Segundo', 'Camino a Santiago Segundo, km 11', '28.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (65, 'Botadero Temporal Sopocachi', 'Camino a Sopocachi, km 4', '21.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (66, 'Botadero Temporal Calacoto', 'Camino a Calacoto, km 1', '8.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (67, 'Botadero Temporal Rosales', 'Camino a Rosales, km 10', '24.6 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (68, 'Botadero Temporal Villa Tupac Amaru', 'Camino a Villa Tupac Amaru, km 8', '29.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (69, 'Botadero Temporal Munaypata', 'Camino a Munaypata, km 6', '27.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (70, 'Botadero Temporal Villa Exaltacion', 'Camino a Villa Exaltacion, km 8', '14.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (71, 'Botadero Temporal Llojeta', 'Camino a Llojeta, km 11', '22.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (72, 'Botadero Temporal Pacajes', 'Camino a Pacajes, km 13', '8.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (73, 'Botadero Temporal Cotahuma', 'Camino a Cotahuma, km 18', '11.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (74, 'Botadero Temporal Chasquipampa', 'Camino a Chasquipampa, km 18', '14.4 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (75, 'Botadero Temporal Kantutani', 'Camino a Kantutani, km 12', '29.7 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (76, 'Botadero Temporal Villa Bolivar', 'Camino a Villa Bolivar, km 8', '7.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (77, 'Botadero Temporal Alto Obrajes', 'Camino a Alto Obrajes, km 10', '3.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (78, 'Botadero Temporal Villa Ingenio', 'Camino a Villa Ingenio, km 7', '11.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (79, 'Botadero Temporal 12 de Octubre', 'Camino a 12 de Octubre, km 14', '23.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (80, 'Botadero Temporal German Busch', 'Camino a German Busch, km 5', '16.6 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (81, 'Botadero Temporal Rosas Pampa', 'Camino a Rosas Pampa, km 16', '23.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (82, 'Botadero Temporal Los Pinos', 'Camino a Los Pinos, km 10', '25.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (83, 'Botadero Temporal Villa Tejada Triangular', 'Camino a Villa Tejada Triangular, km 17', '12.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (84, 'Botadero Temporal Villa Mercedes', 'Camino a Villa Mercedes, km 10', '28.6 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (85, 'Botadero Temporal Villa Santiago', 'Camino a Villa Santiago, km 8', '24.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (86, 'Botadero Temporal Auquisamana', 'Camino a Auquisamana, km 17', '11.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (87, 'Botadero Temporal Villa Brasil', 'Camino a Villa Brasil, km 17', '13.5 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (88, 'Botadero Temporal Villa Nuevo Potosi', 'Camino a Villa Nuevo Potosi, km 13', '18.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (89, 'Botadero Temporal Villa Victoria', 'Camino a Villa Victoria, km 1', '15.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (90, 'Botadero Temporal Villa San Antonio', 'Camino a Villa San Antonio, km 14', '14.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (91, 'Botadero Temporal Alpacoma', 'Camino a Alpacoma, km 12', '29.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (92, 'Botadero Temporal Casco Viejo', 'Camino a Casco Viejo, km 18', '20.6 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (93, 'Botadero Temporal Seguencoma', 'Camino a Seguencoma, km 12', '29.0 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (94, 'Botadero Temporal Villa Fatima', 'Camino a Villa Fatima, km 4', '9.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (95, 'Botadero Temporal Villa Tejada Rectangular', 'Camino a Villa Tejada Rectangular, km 6', '17.9 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (96, 'Botadero Temporal 3 de Mayo', 'Camino a 3 de Mayo, km 13', '17.2 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (97, 'Botadero Temporal Miraflores', 'Camino a Miraflores, km 14', '18.3 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (98, 'Botadero Temporal Challapampa', 'Camino a Challapampa, km 12', '2.8 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (99, 'Botadero Temporal Callapa', 'Camino a Callapa, km 3', '5.1 hectareas');
INSERT INTO BOTADERO (idBotadero, nombre, direccion, extencion_terreno) VALUES (100, 'Botadero Temporal Bajo Pampahasi', 'Camino a Bajo Pampahasi, km 7', '14.1 hectareas');

-- PERSONA: 1-100 conductores, 101-200 recolectores (especializacion disjunta)  (200 filas)
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (1, '8399294 LP', 'Julio', 'Lazo', 'Lazo', 'M', DATE '1985-02-14', '65401152', 'Av. Capitan Ravelo Nro. 1795, Zona Alto Lima', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (2, '3764745 LP', 'Walter', 'Mollo', 'Cori', 'M', DATE '1975-10-06', '61532771', 'Av. Inca Llojeta Nro. 3979, Zona Kantutani', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (3, '4416715 LP', 'Jorge', 'Navarro', 'Apaza', 'M', DATE '1966-08-16', '71062614', 'Calle Linares Nro. 546, Zona Cementerio', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (4, '7393548 LP', 'Limbert', 'Paco', 'Cruz', 'M', DATE '1987-04-12', '66199456', 'Av. Federico Zuazo Nro. 3137, Zona Sopocachi', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (5, '5070255 LP', 'Grover Franz', 'Rivera', 'Ticona', 'M', DATE '1974-07-24', '73972584', 'Av. Munoz Reyes Nro. 551, Zona Sopocachi', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (6, '6799116 SC', 'Percy', 'Limachi', 'Salazar', 'M', DATE '1985-02-22', '76697961', 'Av. Juan de la Riva Nro. 3195, Zona Villa Bolivia', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (7, '7569216 TJ', 'Saul', 'Flores', 'Vargas', 'M', DATE '1988-06-26', '77056709', 'Calle Ayacucho Nro. 1304, Zona El Tejar', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (8, '7500984 CB', 'Daniel Omar', 'Aguilar', 'Vera', 'M', DATE '1973-01-07', '60132059', 'Av. Panama Nro. 2868, Zona Irpavi', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (9, '6430552 LP', 'Pedro', 'Ramos', 'Mollo', 'M', DATE '1972-02-23', '61196027', 'Calle Inca Llojeta Nro. 3255, Zona Pedregal', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (10, '4232535 TJ', 'Luis', 'Mamani', 'Rodriguez', 'M', DATE '1969-05-21', '69601796', 'Av. Murillo Nro. 2703, Zona Villa 14 de Septiembre', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (11, '6279218 LP', 'Limbert Raul', 'Navarro', 'Mamani', 'M', DATE '1979-09-20', '63524013', 'Av. Almirante Grau Nro. 415, Zona Casco Viejo', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (12, '4432813 LP', 'Miguel Fernando', 'Ticona', 'Ramos', 'M', DATE '1971-06-09', '64881813', 'Av. Rosendo Gutierrez Nro. 1524, Zona Achumani', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (13, '5895315 LP', 'Daniel Isaac', 'Blanco', 'Garcia', 'M', DATE '1980-06-07', '62571929', 'Av. Loayza Nro. 301, Zona Miraflores', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (14, '4098467 CH', 'Jose', 'Rivera', 'Miranda', 'M', DATE '1969-05-15', '71341461', 'Av. Ismael Montes Nro. 1263, Zona Franz Tamayo', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (15, '6455463 PT', 'Hugo', 'Copa', 'Villca', 'M', DATE '1967-04-21', '68005305', 'Calle Indaburo Nro. 2143, Zona 12 de Octubre', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (16, '3678581 PT', 'Lino', 'Zapata', 'Patzi', 'M', DATE '1980-11-16', '70553848', 'Av. Ecuador Nro. 2300, Zona Alpacoma', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (17, '5334242 LP', 'Lino Eddy', 'Cori', 'Mollo', 'M', DATE '1966-08-05', '76151413', 'Av. Canaviri Nro. 2743, Zona Villa Remedios', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (18, '7665733 LP', 'Raul', 'Ticona', 'Gutierrez', 'M', DATE '1980-06-06', '72394246', 'Av. Linares Nro. 3463, Zona Villa Brasil', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (19, '4474803 LP', 'Pablo', 'Blanco', 'Gomez', 'M', DATE '1984-09-24', '74535813', 'Av. Venezuela Nro. 424, Zona Bolognia', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (20, '3767630 LP', 'Grover', 'Guarachi', 'Mollo', 'M', DATE '1979-01-09', '71047516', 'Av. Jaen Nro. 1387, Zona Alto Obrajes', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (21, '6857120 CB', 'Luis', 'Espinoza', 'Tarqui', 'M', DATE '1969-04-11', '73494042', 'Av. Chuquisaca Nro. 2070, Zona Chuquiaguillo', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (22, '9007334 LP', 'Marcelo Alvaro', 'Aguilar', 'Limachi', 'M', DATE '1977-01-06', '71956808', 'Calle Jacinto Benavente Nro. 324, Zona Villa Adela', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (23, '3303594 LP', 'Gustavo Carlos', 'Paco', 'Alanoca', 'M', DATE '1983-02-15', '63927330', 'Av. Victor Sanjines Nro. 234, Zona La Ceja', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (24, '5057955 CB', 'Ivan', 'Lopez', 'Condori', 'M', DATE '1968-07-23', '71146351', 'Calle Fernando Guachalla Nro. 860, Zona Rio Seco', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (25, '5053633 LP', 'Juan', 'Gutierrez', 'Patzi', 'M', DATE '1965-01-10', '66371671', 'Av. Sucre Nro. 830, Zona Alto Sopocachi', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (26, '3566582 CH', 'Jose', 'Patzi', 'Quenta', 'M', DATE '1967-03-25', '77057929', 'Calle Rafael Zubieta Nro. 2535, Zona Alto Irpavi', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (27, '8580055 LP', 'Luis', 'Sirpa', 'Lazo', 'M', DATE '1980-11-28', '68615812', 'Calle Quito Nro. 2102, Zona Villa Adela', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (28, '5137427 CB', 'Ronald', 'Blanco', 'Gutierrez', 'M', DATE '1966-07-13', '65167682', 'Av. Colombia Nro. 1999, Zona La Ceja', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (29, '8131677 TJ', 'Franz', 'Colque', 'Mamani', 'M', DATE '1986-11-23', '66436628', 'Calle Costanera Nro. 201, Zona Villa Victoria', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (30, '8429655 LP', 'Rene Ramiro', 'Villca', 'Paco', 'M', DATE '1965-12-10', '66283709', 'Av. Junin Nro. 1665, Zona Villa Tunari', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (31, '4632357 PT', 'Victor Franz', 'Sirpa', 'Paco', 'M', DATE '1982-01-27', '63325269', 'Av. Jaen Nro. 1890, Zona Seguencoma', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (32, '3351144 LP', 'David', 'Huanca', 'Calle', 'M', DATE '1985-09-05', '69612138', 'Av. Ecuador Nro. 349, Zona Bolognia', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (33, '9259291 LP', 'Saul', 'Vargas', 'Flores', 'M', DATE '1977-10-11', '64327465', 'Av. Bolivar Nro. 369, Zona La Ceja', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (34, '6079977 LP', 'Percy', 'Cardenas', 'Olmos', 'M', DATE '1967-12-23', '71124335', 'Calle Camacho Nro. 1487, Zona Mercedario', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (35, '5973660 LP', 'Juana', 'Mamani', 'Chambi', 'F', DATE '1975-05-07', '66103022', 'Av. Fernando Guachalla Nro. 740, Zona Villa Salome', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (36, '9185656 PT', 'Ronald', 'Choque', 'Lazo', 'M', DATE '1984-11-09', '68341908', 'Calle Rodriguez Nro. 2185, Zona Villa Mercedes', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (37, '8982441 LP', 'Marcelo', 'Chambi', 'Torrez', 'M', DATE '1988-03-06', '63863787', 'Av. Claudio Aliaga Nro. 288, Zona Villa Armonia', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (38, '8307178 OR', 'Daniel', 'Nina', 'Nina', 'M', DATE '1975-05-22', '64276412', 'Av. Munoz Reyes Nro. 1144, Zona Seguencoma', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (39, '6465187 LP', 'Raul', 'Copa', 'Poma', 'M', DATE '1972-10-08', '70550496', 'Av. Montes Nro. 144, Zona Villa Bella', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (40, '6351411 SC', 'Fernando Franz', 'Torrez', 'Jimenez', 'M', DATE '1990-11-20', '66877109', 'Av. Tiahuanacu Nro. 1142, Zona Pedregal', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (41, '9096278 LP', 'Franz Oscar', 'Villca', 'Flores', 'M', DATE '1978-09-08', '66607568', 'Av. Yanacocha Nro. 426, Zona Bella Vista', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (42, '8171776 OR', 'Edwin Gonzalo', 'Gutierrez', 'Vargas', 'M', DATE '1983-07-06', '60987695', 'Calle Chile Nro. 3834, Zona Villa Tejada Triangular', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (43, '8172718 LP', 'Alfredo', 'Vera', 'Paco', 'M', DATE '1990-08-14', '60282207', 'Calle Ingavi Nro. 2674, Zona Tembladerani', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (44, '4389212 PT', 'Gustavo', 'Mendoza', 'Vargas', 'M', DATE '1966-12-13', '64431774', 'Av. Almirante Grau Nro. 1211, Zona Villa Remedios', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (45, '4445098 LP', 'Rolando', 'Villca', 'Rivera', 'M', DATE '1970-02-10', '65344796', 'Av. Manuel Castillo Nro. 2727, Zona Cementerio', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (46, '3995948 LP', 'Roberto Marcelo', 'Patzi', 'Salazar', 'M', DATE '1988-07-23', '78692271', 'Calle Av. del Ejercito Nro. 872, Zona Alto Calacoto', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (47, '7773399 CB', 'Gustavo Jhonny', 'Ticona', 'Sirpa', 'M', DATE '1965-11-05', '72920742', 'Av. Almirante Grau Nro. 1415, Zona Bajo Llojeta', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (48, '5407360 LP', 'David Oscar', 'Condori', 'Lazo', 'M', DATE '1969-07-28', '66450114', 'Av. Comercio Nro. 3993, Zona Cota Cota', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (49, '9730221 LP', 'Susana', 'Choque', 'Jimenez', 'F', DATE '1975-12-25', '60748514', 'Calle Fernando Guachalla Nro. 556, Zona Villa Remedios', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (50, '3962284 SC', 'Rodrigo', 'Tarqui', 'Rivera', 'M', DATE '1965-09-23', '67819596', 'Calle Garita de Lima Nro. 388, Zona Villa Tunari', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (51, '5945212 LP', 'Hugo', 'Salazar', 'Navarro', 'M', DATE '1974-07-03', '71575392', 'Calle 16 de Julio Nro. 2838, Zona Villa Copacabana', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (52, '9626807 LP', 'Grover', 'Colque', 'Fernandez', 'M', DATE '1970-11-27', '68890499', 'Av. Belisario Salinas Nro. 3709, Zona Ballivian', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (53, '5227352 CH', 'Roberto', 'Alanoca', 'Mamani', 'M', DATE '1985-10-25', '79516854', 'Calle Asuncion Nro. 1990, Zona Franz Tamayo', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (54, '3636389 CB', 'Eddy', 'Jimenez', 'Cruz', 'M', DATE '1988-07-12', '78562528', 'Av. Tumusla Nro. 3264, Zona Villa Brasil', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (55, '4753718 LP', 'Isaac Miguel', 'Choque', 'Cori', 'M', DATE '1971-06-16', '70694266', 'Calle Mariscal Santa Cruz Nro. 1357, Zona Villa Victoria', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (56, '9217073 TJ', 'Fernando', 'Navarro', 'Guarachi', 'M', DATE '1980-05-15', '77638869', 'Calle Loayza Nro. 145, Zona Rosales', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (57, '8753374 LP', 'Limbert', 'Garcia', 'Blanco', 'M', DATE '1972-11-21', '70695631', 'Av. Pichincha Nro. 3460, Zona Llojeta', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (58, '4430520 LP', 'Sandra', 'Quenta', 'Suxo', 'F', DATE '1988-08-25', '76781724', 'Av. Ecuador Nro. 1312, Zona Ballivian', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (59, '7140991 CB', 'Alvaro', 'Perez', 'Salazar', 'M', DATE '1969-11-11', '62579781', 'Av. Tarapaca Nro. 2217, Zona Alto Irpavi', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (60, '7439499 LP', 'Victor', 'Rivera', 'Navarro', 'M', DATE '1979-09-28', '75756605', 'Av. Cochabamba Nro. 1294, Zona Ciudad Juvenil', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (61, '7368418 LP', 'Ronald', 'Cruz', 'Aguilar', 'M', DATE '1980-09-11', '61624487', 'Calle Sanjines Nro. 1954, Zona Villa Tupac Amaru', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (62, '6986620 OR', 'Wilson Jorge', 'Cori', 'Alanoca', 'M', DATE '1983-02-15', '62903575', 'Calle Ismael Montes Nro. 2275, Zona Mallasilla', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (63, '5353275 LP', 'Julio', 'Gomez', 'Vargas', 'M', DATE '1967-01-04', '79929383', 'Calle Victor Sanjines Nro. 464, Zona Villa Pabon', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (64, '4879092 LP', 'Victor Alfredo', 'Huanca', 'Espinoza', 'M', DATE '1971-08-21', '73667471', 'Av. Pando Nro. 900, Zona Achumani', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (65, '5338406 LP', 'Teodoro', 'Paco', 'Huanca', 'M', DATE '1980-08-04', '62744043', 'Calle Costanera Nro. 3291, Zona Alto Obrajes', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (66, '5451001 LP', 'Martha', 'Herrera', 'Herrera', 'F', DATE '1974-04-07', '79183814', 'Av. Calama Nro. 1256, Zona Cota Cota', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (67, '8715239 TJ', 'Daniel', 'Patzi', 'Tarqui', 'M', DATE '1985-08-03', '65204265', 'Calle Eloy Salmon Nro. 3466, Zona Bajo Pampahasi', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (68, '6337775 LP', 'Grover', 'Castro', 'Ortiz', 'M', DATE '1975-09-08', '79027105', 'Calle Evaristo Valle Nro. 3547, Zona Vino Tinto', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (69, '8888878 LP', 'Oscar Humberto', 'Mendoza', 'Navarro', 'M', DATE '1981-04-02', '60714655', 'Av. Victor Sanjines Nro. 3237, Zona Jupapina', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (70, '9736183 LP', 'Ivan', 'Mendoza', 'Mamani', 'M', DATE '1966-03-05', '75490898', 'Calle Canaviri Nro. 1066, Zona Villa Fatima', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (71, '9661241 LP', 'Cristian', 'Rodriguez', 'Aliaga', 'M', DATE '1965-12-14', '69227553', 'Av. Munoz Reyes Nro. 2391, Zona Tacagua', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (72, '4625307 CH', 'Julio Alfredo', 'Cruz', 'Gutierrez', 'M', DATE '1975-12-28', '79392981', 'Av. Junin Nro. 3206, Zona Los Pinos', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (73, '3952571 PT', 'Rolando Isaac', 'Jimenez', 'Zapata', 'M', DATE '1972-08-12', '66805786', 'Calle Tumusla Nro. 3106, Zona Cota Cota', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (74, '6948942 LP', 'Jhonny', 'Quispe', 'Alanoca', 'M', DATE '1968-03-11', '69825753', 'Av. Bolivar Nro. 3079, Zona Los Pinos', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (75, '7626338 TJ', 'Ronald', 'Mamani', 'Garcia', 'M', DATE '1970-08-15', '62644527', 'Av. Canaviri Nro. 1825, Zona Villa 14 de Septiembre', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (76, '5839256 OR', 'Hugo', 'Nina', 'Callisaya', 'M', DATE '1968-08-06', '71422515', 'Calle Bueno Nro. 1722, Zona Ciudad Juvenil', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (77, '9165544 LP', 'Ramiro', 'Callisaya', 'Sirpa', 'M', DATE '1965-06-18', '68858938', 'Calle Hernando Siles Nro. 2507, Zona Callapa', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (78, '6766752 SC', 'Fernando', 'Callisaya', 'Alanoca', 'M', DATE '1979-06-16', '66016967', 'Av. Buenos Aires Nro. 3807, Zona Chasquipampa', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (79, '8896186 LP', 'Henry', 'Condori', 'Colque', 'M', DATE '1989-02-15', '76034236', 'Av. Ayacucho Nro. 2463, Zona Alto Obrajes', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (80, '5375340 TJ', 'Gonzalo', 'Morales', 'Espinoza', 'M', DATE '1975-05-24', '74154773', 'Calle Antofagasta Nro. 869, Zona Bolognia', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (81, '7492923 LP', 'Jhonny', 'Quenta', 'Flores', 'M', DATE '1971-01-27', '74618118', 'Calle Rodriguez Nro. 503, Zona Santiago Segundo', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (82, '9342189 LP', 'Jhonny', 'Perez', 'Guarachi', 'M', DATE '1985-05-19', '65321687', 'Calle Pando Nro. 2156, Zona Villa Nuevo Potosi', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (83, '5730645 LP', 'Tania', 'Callisaya', 'Torrez', 'F', DATE '1979-04-14', '75127255', 'Av. Chile Nro. 2883, Zona Tembladerani', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (84, '6580626 LP', 'Marco', 'Quenta', 'Poma', 'M', DATE '1966-02-05', '62662797', 'Calle Camacho Nro. 1929, Zona Villa Victoria', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (85, '4769011 TJ', 'Daniel', 'Castro', 'Suxo', 'M', DATE '1980-04-03', '74891984', 'Calle 20 de Octubre Nro. 3546, Zona Callapa', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (86, '7599257 LP', 'Franz Daniel', 'Aliaga', 'Jimenez', 'M', DATE '1970-03-10', '79004718', 'Av. Mariscal Santa Cruz Nro. 3572, Zona Los Pinos', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (87, '5053799 CB', 'Eddy Julio', 'Rivera', 'Poma', 'M', DATE '1966-05-07', '74402521', 'Av. Junin Nro. 2057, Zona Villa Brasil', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (88, '8606994 SC', 'Victor', 'Aliaga', 'Guarachi', 'M', DATE '1966-05-16', '68761375', 'Calle Indaburo Nro. 3227, Zona Callapa', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (89, '7806654 PT', 'Jhonny Daniel', 'Miranda', 'Calle', 'M', DATE '1987-03-10', '61707887', 'Av. Landaeta Nro. 3133, Zona Villa Tupac Amaru', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (90, '7646063 LP', 'Marcelo Isaac', 'Jimenez', 'Callisaya', 'M', DATE '1975-01-21', '73519760', 'Av. Mercado Nro. 1274, Zona Villa Remedios', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (91, '4978324 LP', 'David', 'Lazo', 'Colque', 'M', DATE '1971-10-20', '76816210', 'Av. 6 de Agosto Nro. 561, Zona Villa Tunari', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (92, '8806732 LP', 'Rolando', 'Mamani', 'Alanoca', 'M', DATE '1966-01-12', '62977574', 'Av. Evaristo Valle Nro. 437, Zona Tupac Katari', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (93, '7475794 CH', 'Wilson Grover', 'Aliaga', 'Miranda', 'M', DATE '1988-04-02', '75477123', 'Av. Chuquisaca Nro. 1855, Zona Mallasa', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (94, '3267776 LP', 'Alvaro', 'Quenta', 'Huanca', 'M', DATE '1972-04-03', '71881443', 'Calle Murillo Nro. 1731, Zona Villa Adela', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (95, '7138095 PT', 'Humberto Daniel', 'Castro', 'Herrera', 'M', DATE '1977-07-04', '60559328', 'Calle Santa Cruz Nro. 3485, Zona Villa Adela', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (96, '8907324 LP', 'Marco', 'Morales', 'Quenta', 'M', DATE '1978-02-05', '75249138', 'Calle Tomas Frias Nro. 1210, Zona Villa Tejada Triangular', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (97, '3312962 LP', 'Freddy', 'Huanca', 'Salazar', 'M', DATE '1975-11-17', '62716339', 'Calle Loayza Nro. 1445, Zona Villa Salome', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (98, '9869234 LP', 'Edwin', 'Quenta', 'Tarqui', 'M', DATE '1974-03-04', '73135772', 'Calle Garita de Lima Nro. 3962, Zona Mercedario', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (99, '3854066 TJ', 'Saul', 'Gutierrez', 'Gomez', 'M', DATE '1983-10-28', '71953095', 'Av. Yungas Nro. 583, Zona Nuevos Horizontes', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (100, '8689158 LP', 'Gustavo', 'Herrera', 'Blanco', 'M', DATE '1982-11-11', '70156721', 'Av. Armentia Nro. 399, Zona Cotahuma', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (101, '4842607 CH', 'Cecilia', 'Rivera', 'Ortiz', 'F', DATE '1988-06-12', '71957083', 'Av. Uruguay Nro. 2632, Zona Los Andes', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (102, '3257974 TJ', 'Cristian Grover', 'Rodriguez', 'Blanco', 'M', DATE '1974-11-04', '67014784', 'Calle Bolivar Nro. 3969, Zona Villa Armonia', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (103, '6353256 CB', 'Juana Veronica', 'Garcia', 'Apaza', 'F', DATE '1991-12-02', '69196520', 'Calle Belisario Salinas Nro. 2730, Zona Villa Armonia', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (104, '6171252 LP', 'Fabiola Graciela', 'Mollo', 'Espinoza', 'F', DATE '1994-05-04', '72497705', 'Calle Federico Zuazo Nro. 1669, Zona Pura Pura', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (105, '4114969 OR', 'Pedro Rolando', 'Vargas', 'Espinoza', 'M', DATE '1990-04-02', '70015379', 'Calle Garita de Lima Nro. 494, Zona Santa Rosa', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (106, '3042044 CH', 'Rene', 'Zapata', 'Blanco', 'M', DATE '1988-10-28', '64529313', 'Calle Mercado Nro. 2453, Zona Rio Seco', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (107, '9576134 LP', 'Percy Humberto', 'Aguilar', 'Yujra', 'M', DATE '1977-09-14', '73606613', 'Calle Asuncion Nro. 2569, Zona San Miguel', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (108, '4076202 CH', 'Yolanda', 'Miranda', 'Limachi', 'F', DATE '1993-11-04', '79464321', 'Calle Mejillones Nro. 3450, Zona Pampahasi', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (109, '6751533 LP', 'Pablo', 'Condori', 'Aliaga', 'M', DATE '1972-10-02', '68303454', 'Calle Santa Cruz Nro. 718, Zona Villa Aroma', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (110, '9107162 LP', 'Cristian Carlos', 'Sirpa', 'Copa', 'M', DATE '1993-02-10', '68159641', 'Calle Pichincha Nro. 3089, Zona Chasquipampa', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (111, '8631123 LP', 'Walter', 'Alanoca', 'Copa', 'M', DATE '2003-12-11', '79036345', 'Av. Juan de la Riva Nro. 3489, Zona Ovejuyo', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (112, '9258692 OR', 'Roberto Pedro', 'Flores', 'Fernandez', 'M', DATE '1997-11-25', '66765052', 'Av. Santa Cruz Nro. 3870, Zona Villa Esperanza', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (113, '5394375 LP', 'Eva', 'Lazo', 'Aliaga', 'F', DATE '1995-06-07', '74823768', 'Av. Evaristo Valle Nro. 3130, Zona Alto Tembladerani', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (114, '7503147 LP', 'Isabel', 'Aguilar', 'Aliaga', 'F', DATE '1983-05-19', '70237296', 'Calle Busch Nro. 523, Zona Villa Pabon', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (115, '7895703 CB', 'Monica Reyna', 'Vera', 'Ticona', 'F', DATE '1977-09-17', '77855228', 'Av. Pichincha Nro. 2577, Zona Pura Pura', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (116, '3696770 LP', 'Daniel', 'Huanca', 'Gutierrez', 'M', DATE '1983-02-02', '71179027', 'Av. Sucre Nro. 3865, Zona Villa Santiago', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (117, '6516839 LP', 'Alicia', 'Suxo', 'Condori', 'F', DATE '1984-05-27', '69999596', 'Av. Indaburo Nro. 3260, Zona Ciudad Juvenil', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (118, '6187485 CH', 'Alvaro', 'Laura', 'Rivera', 'M', DATE '1990-09-14', '72238616', 'Calle Santa Cruz Nro. 2244, Zona Villa Bella', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (119, '6821572 CH', 'Zulema Maria', 'Quenta', 'Villca', 'F', DATE '1999-02-07', '73493686', 'Calle Ecuador Nro. 3149, Zona Los Pinos', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (120, '8549330 LP', 'Rene Gonzalo', 'Choque', 'Vera', 'M', DATE '1992-10-14', '78526818', 'Calle Manuel Castillo Nro. 225, Zona Tembladerani', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (121, '4505441 LP', 'Pedro Oscar', 'Gutierrez', 'Mamani', 'M', DATE '1979-05-19', '60751429', 'Calle Uruguay Nro. 2777, Zona Obrajes', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (122, '4897265 LP', 'Oscar', 'Paco', 'Patzi', 'M', DATE '1988-05-10', '70719646', 'Av. Aspiazu Nro. 2187, Zona Alto Calacoto', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (123, '9335528 LP', 'Raul', 'Mamani', 'Chambi', 'M', DATE '1976-05-11', '60254412', 'Calle Beni Nro. 2023, Zona Villa 14 de Septiembre', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (124, '8764484 LP', 'Ronald', 'Sirpa', 'Navarro', 'M', DATE '1970-05-06', '64687901', 'Calle Manuel Castillo Nro. 1390, Zona Villa Salome', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (125, '7347198 LP', 'Nelly', 'Cardenas', 'Poma', 'F', DATE '2002-07-25', '70267186', 'Av. Ingavi Nro. 2719, Zona Tembladerani', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (126, '8649143 CH', 'Franz Grover', 'Nina', 'Gutierrez', 'M', DATE '1975-10-16', '71005465', 'Av. Santa Cruz Nro. 2336, Zona Rosales', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (127, '8221501 CB', 'Rodrigo', 'Laura', 'Quispe', 'M', DATE '1982-03-15', '73812963', 'Av. Montes Nro. 1763, Zona Nuevos Horizontes', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (128, '8661435 SC', 'Isaac', 'Condori', 'Mendoza', 'M', DATE '1977-05-17', '71241574', 'Calle Pedro Salazar Nro. 3999, Zona Villa Nuevo Potosi', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (129, '9564609 LP', 'Ivonne Reyna', 'Navarro', 'Morales', 'F', DATE '2002-04-09', '69032719', 'Calle Calama Nro. 771, Zona Villa Tupac Amaru', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (130, '5720503 LP', 'Reyna', 'Quispe', 'Villca', 'F', DATE '1995-11-21', '77036427', 'Calle Pasoskanki Nro. 2104, Zona 16 de Julio', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (131, '7193544 LP', 'Reyna', 'Espinoza', 'Rivera', 'F', DATE '1991-01-16', '69292391', 'Calle Rafael Zubieta Nro. 3780, Zona Ballivian', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (132, '5135141 PT', 'Julia', 'Colque', 'Patzi', 'F', DATE '1986-11-16', '69668314', 'Av. Fernando Guachalla Nro. 2601, Zona Villa Remedios', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (133, '9653572 LP', 'Carlos', 'Callisaya', 'Mollo', 'M', DATE '1989-02-17', '73592846', 'Calle Eloy Salmon Nro. 793, Zona Ballivian', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (134, '8241018 LP', 'Limbert Luis', 'Paco', 'Gutierrez', 'M', DATE '1975-02-16', '74465122', 'Calle Esteban Arce Nro. 3051, Zona Villa Tejada Rectangular', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (135, '8414997 LP', 'Daniel Henry', 'Ticona', 'Colque', 'M', DATE '1986-02-25', '75486080', 'Calle Colon Nro. 815, Zona Seguencoma', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (136, '3914901 LP', 'Marco Juan', 'Ortiz', 'Garcia', 'M', DATE '1990-05-08', '74253120', 'Calle Peru Nro. 1334, Zona Ciudad Juvenil', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (137, '9647821 CB', 'Miguel', 'Chambi', 'Flores', 'M', DATE '1987-06-26', '75338232', 'Calle Sanjines Nro. 2049, Zona Franz Tamayo', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (138, '4598979 LP', 'Henry Freddy', 'Salazar', 'Mamani', 'M', DATE '2002-05-19', '67304652', 'Calle Colombia Nro. 261, Zona Cota Cota', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (139, '3833192 LP', 'Alvaro', 'Torrez', 'Quenta', 'M', DATE '1972-09-10', '74338399', 'Calle Brasil Nro. 3397, Zona Rosales', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (140, '5214841 LP', 'Roberto', 'Herrera', 'Garcia', 'M', DATE '1970-08-14', '73646048', 'Av. Ingavi Nro. 2064, Zona Mercedario', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (141, '9299204 OR', 'Paola', 'Quenta', 'Limachi', 'F', DATE '1996-06-09', '66817353', 'Calle Almirante Grau Nro. 3174, Zona Alto Lima', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (142, '8220733 LP', 'Saul', 'Espinoza', 'Limachi', 'M', DATE '1973-11-25', '70213311', 'Calle Sagarnaga Nro. 1541, Zona Villa Tupac Amaru', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (143, '5803957 PT', 'Jorge', 'Lopez', 'Aliaga', 'M', DATE '1998-04-08', '68694329', 'Av. Sagarnaga Nro. 1139, Zona 3 de Mayo', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (144, '3485604 LP', 'Juan', 'Castro', 'Suxo', 'M', DATE '1994-03-28', '61391412', 'Calle Landivar Nro. 2720, Zona Cementerio', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (145, '9105545 CH', 'Claudia', 'Choque', 'Lopez', 'F', DATE '1994-11-24', '63687648', 'Calle Calama Nro. 3358, Zona Villa Mercedes', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (146, '6662567 PT', 'Gustavo', 'Aliaga', 'Callisaya', 'M', DATE '1986-02-22', '75572854', 'Av. Claudio Aliaga Nro. 3752, Zona Bajo Pampahasi', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (147, '5547120 LP', 'Karen', 'Poma', 'Perez', 'F', DATE '1986-09-18', '60239351', 'Av. Federico Zuazo Nro. 3372, Zona Villa Exaltacion', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (148, '9937860 PT', 'Teresa Norma', 'Morales', 'Huanca', 'F', DATE '1988-12-08', '63049417', 'Calle Yanacocha Nro. 3897, Zona Villa Tejada Rectangular', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (149, '3700403 LP', 'Sandra Tania', 'Yujra', 'Herrera', 'F', DATE '1983-07-06', '70304618', 'Av. Camacho Nro. 2569, Zona Rosales', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (150, '9654451 LP', 'Dora', 'Sirpa', 'Sirpa', 'F', DATE '1982-06-10', '66408862', 'Calle Heroinas Nro. 3854, Zona 16 de Julio', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (151, '7843618 LP', 'Patricia', 'Gutierrez', 'Quispe', 'F', DATE '1989-07-26', '62102298', 'Av. Loayza Nro. 2315, Zona Huayna Potosi', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (152, '4464727 LP', 'Ramiro', 'Gomez', 'Lopez', 'M', DATE '1986-11-18', '65491465', 'Calle Santa Cruz Nro. 2164, Zona La Ceja', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (153, '8191034 LP', 'Walter', 'Guarachi', 'Nina', 'M', DATE '1989-12-16', '78424915', 'Calle Chile Nro. 2390, Zona Cosmos 79', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (154, '8405652 LP', 'Vilma', 'Colque', 'Mamani', 'F', DATE '1975-08-05', '72564933', 'Av. Sagarnaga Nro. 1518, Zona Villa Exaltacion', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (155, '3970022 LP', 'Teresa', 'Mendoza', 'Perez', 'F', DATE '1990-10-05', '70293258', 'Calle Evaristo Valle Nro. 3577, Zona Pura Pura', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (156, '8478943 LP', 'Alvaro', 'Navarro', 'Huanca', 'M', DATE '1989-03-24', '72987338', 'Calle Juan de la Riva Nro. 1832, Zona Villa Copacabana', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (157, '3759905 LP', 'Alicia Wendy', 'Miranda', 'Espinoza', 'F', DATE '1979-10-20', '78154785', 'Calle Peru Nro. 1300, Zona Villa Copacabana', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (158, '9825001 LP', 'Henry', 'Paco', 'Tarqui', 'M', DATE '2000-04-19', '67100171', 'Av. Evaristo Valle Nro. 1295, Zona Bajo Pampahasi', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (159, '6535991 LP', 'Vilma', 'Blanco', 'Mamani', 'F', DATE '1972-05-01', '71872524', 'Calle Camacho Nro. 2984, Zona El Tejar', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (160, '3542771 LP', 'Percy', 'Cruz', 'Navarro', 'M', DATE '1991-04-18', '60598134', 'Calle Sanjines Nro. 287, Zona Alto Tacagua', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (161, '7522417 SC', 'Fernando Grover', 'Sirpa', 'Mamani', 'M', DATE '1994-01-07', '68576337', 'Av. Pasoskanki Nro. 3551, Zona Bajo Llojeta', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (162, '5583782 LP', 'Isaac', 'Yujra', 'Gomez', 'M', DATE '1987-12-03', '62483407', 'Calle Quito Nro. 3918, Zona Kantutani', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (163, '5535871 LP', 'Edwin', 'Navarro', 'Cardenas', 'M', DATE '1981-06-12', '70537374', 'Calle Ladislao Cabrera Nro. 113, Zona Achumani', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (164, '8243548 LP', 'Carmen', 'Torrez', 'Rojas', 'F', DATE '2001-05-04', '63974150', 'Av. Garita de Lima Nro. 597, Zona Bajo Llojeta', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (165, '4803682 CH', 'Omar', 'Cori', 'Flores', 'M', DATE '1972-02-09', '79425526', 'Av. Tomas Frias Nro. 1806, Zona El Tejar', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (166, '4318898 TJ', 'Limbert Humberto', 'Poma', 'Copa', 'M', DATE '2004-03-18', '77299584', 'Av. Viacha Nro. 330, Zona Alto Calacoto', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (167, '5911970 LP', 'Marcelo Isaac', 'Yujra', 'Choque', 'M', DATE '1976-06-12', '76049642', 'Av. Victor Sanjines Nro. 3676, Zona Villa Nuevo Potosi', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (168, '9430173 LP', 'Hilda', 'Yujra', 'Quispe', 'F', DATE '2000-08-17', '79322695', 'Calle Heroinas Nro. 2950, Zona El Tejar', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (169, '3386839 LP', 'Freddy', 'Espinoza', 'Calle', 'M', DATE '2002-08-08', '65534312', 'Av. Santa Cruz Nro. 2905, Zona Villa Aroma', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (170, '6633806 CH', 'Gustavo', 'Cori', 'Calle', 'M', DATE '1998-10-15', '75655472', 'Calle Copacabana Nro. 3296, Zona Ciudad Satelite', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (171, '6179149 CB', 'Ivan', 'Callisaya', 'Rodriguez', 'M', DATE '2001-01-03', '65029933', 'Av. Panama Nro. 1908, Zona Villa Pabon', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (172, '7764615 LP', 'Beatriz Susana', 'Aguilar', 'Choque', 'F', DATE '1971-01-03', '73976998', 'Calle Chile Nro. 3096, Zona Villa Bolivar', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (173, '8986043 LP', 'Cristian Humberto', 'Vargas', 'Flores', 'M', DATE '1991-04-04', '63057178', 'Av. Esteban Arce Nro. 2739, Zona Seguencoma', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (174, '5090978 LP', 'Eva Alicia', 'Copa', 'Gomez', 'F', DATE '1982-04-27', '75512720', 'Calle Uruguay Nro. 3721, Zona Kantutani', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (175, '7922796 OR', 'Rolando', 'Mendoza', 'Lopez', 'M', DATE '1971-08-09', '67872828', 'Av. Victor Sanjines Nro. 684, Zona Villa Remedios', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (176, '3493814 PT', 'Eddy', 'Laura', 'Sirpa', 'M', DATE '1971-02-07', '70457656', 'Av. Asuncion Nro. 3110, Zona Bajo Llojeta', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (177, '8392303 SC', 'Julio', 'Vargas', 'Rivera', 'M', DATE '1986-02-18', '60349976', 'Calle Chile Nro. 1579, Zona Alto Obrajes', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (178, '3274324 PT', 'Oscar Franz', 'Ramos', 'Poma', 'M', DATE '1990-08-06', '66243667', 'Av. Santa Cruz Nro. 936, Zona Santiago Segundo', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (179, '4642969 OR', 'Marcelo Gustavo', 'Miranda', 'Poma', 'M', DATE '1980-09-03', '77603997', 'Calle Indaburo Nro. 2706, Zona 3 de Mayo', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (180, '3823108 LP', 'Omar', 'Ticona', 'Mollo', 'M', DATE '1990-04-01', '72772092', 'Calle Linares Nro. 3098, Zona Chasquipampa', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (181, '3058581 LP', 'Jhonny Wilson', 'Castro', 'Yujra', 'M', DATE '1992-06-13', '68208011', 'Calle Esteban Arce Nro. 3698, Zona Mallasilla', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (182, '3896126 TJ', 'Marlene Maria', 'Ramos', 'Flores', 'F', DATE '2002-09-13', '72115263', 'Av. Lima Nro. 3119, Zona Tacagua', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (183, '9656052 TJ', 'Ronald Luis', 'Guarachi', 'Chambi', 'M', DATE '2000-04-16', '72061766', 'Av. Viacha Nro. 1624, Zona Cotahuma', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (184, '4244680 CH', 'Gustavo', 'Laura', 'Apaza', 'M', DATE '1987-12-03', '65776311', 'Av. Yanacocha Nro. 2822, Zona Alto Lima', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (185, '4279754 LP', 'Saul Ronald', 'Nina', 'Huanca', 'M', DATE '2001-10-12', '62907777', 'Calle Rosendo Gutierrez Nro. 2193, Zona Alto Llojeta', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (186, '9672033 LP', 'Rodrigo Alvaro', 'Torrez', 'Miranda', 'M', DATE '1999-02-22', '61125736', 'Calle Murillo Nro. 2929, Zona La Ceja', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (187, '9608621 LP', 'Juan', 'Rojas', 'Villca', 'M', DATE '1983-04-25', '62319670', 'Av. Mariscal Santa Cruz Nro. 1236, Zona Villa Tupac Amaru', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (188, '6609875 LP', 'Oscar', 'Rodriguez', 'Flores', 'M', DATE '1971-03-27', '70094923', 'Av. Aspiazu Nro. 1877, Zona Bolognia', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (189, '6779268 LP', 'Saul Alvaro', 'Alanoca', 'Chambi', 'M', DATE '1999-11-26', '68790059', 'Calle Tumusla Nro. 1869, Zona Rosas Pampa', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (190, '9250126 SC', 'Raul Percy', 'Lopez', 'Colque', 'M', DATE '1977-12-23', '73741837', 'Calle Bolivar Nro. 841, Zona Alto Tacagua', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (191, '3138538 CB', 'Sandra', 'Suxo', 'Mamani', 'F', DATE '1997-07-09', '77266039', 'Av. Colon Nro. 214, Zona 3 de Mayo', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (192, '5474720 LP', 'Ana', 'Gomez', 'Yujra', 'F', DATE '1984-03-11', '67581478', 'Calle Chile Nro. 3589, Zona Villa Aroma', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (193, '7453768 TJ', 'Rolando', 'Vargas', 'Rojas', 'M', DATE '1993-10-07', '70351610', 'Av. Copacabana Nro. 2175, Zona Bajo Llojeta', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (194, '5544634 TJ', 'Omar', 'Vargas', 'Torrez', 'M', DATE '1992-03-05', '72704026', 'Av. Indaburo Nro. 2576, Zona Pura Pura', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (195, '6114275 OR', 'Mario Cristian', 'Cardenas', 'Aliaga', 'M', DATE '1983-01-08', '60328326', 'Av. Peru Nro. 2620, Zona Santa Rosa', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (196, '7766759 LP', 'Nelson Marcelo', 'Copa', 'Zapata', 'M', DATE '1983-12-12', '61706564', 'Av. Antofagasta Nro. 2478, Zona Alto Llojeta', 'Noche');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (197, '7262916 LP', 'Nancy', 'Quenta', 'Gutierrez', 'F', DATE '1983-08-28', '76782247', 'Av. Uruguay Nro. 2020, Zona Villa Salome', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (198, '8735814 CH', 'Walter', 'Gutierrez', 'Copa', 'M', DATE '1985-02-04', '70423616', 'Av. Buenos Aires Nro. 3346, Zona Bolognia', 'Manana');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (199, '9067992 OR', 'Isaac Alfredo', 'Huanca', 'Rojas', 'M', DATE '1988-08-09', '75786094', 'Av. Aspiazu Nro. 768, Zona Callapa', 'Tarde');
INSERT INTO PERSONA (idPersona, ci, nombre, paterno, materno, sexo, fecha_nacimiento, telefono, direccion, turno) VALUES (200, '3452460 TJ', 'Humberto', 'Lazo', 'Cori', 'M', DATE '1996-02-12', '68617214', 'Av. Jaen Nro. 1588, Zona Pedregal', 'Manana');

-- MATERIAL_TRABAJO  (100 filas)
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (1, 'Guantes de cuero reforzado talla M', 'Nuevo', 26.72);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (2, 'Chaleco reflectivo talla L verde', 'Nuevo', 30.26);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (3, 'Faja lumbar talla L', 'Nuevo', 79.19);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (4, 'Pantalon de trabajo reforzado talla 36', 'Regular', 98.5);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (5, 'Cinta reflectiva para brazo verde', 'Nuevo', 9.12);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (6, 'Chaleco reflectivo talla XL naranja', 'Regular', 38.99);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (7, 'Faja lumbar talla M', 'Regular', 77.7);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (8, 'Carretilla una rueda', 'Nuevo', 301.44);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (9, 'Guantes anticorte talla XL', 'Nuevo', 50.45);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (10, 'Cinta reflectiva para brazo amarilla', 'Bueno', 9.79);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (11, 'Escoba industrial mango largo', 'Bueno', 43.3);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (12, 'Guantes de nitrilo talla L', 'Regular', 8.56);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (13, 'Bolsas de residuos peligrosos (rollo x25) amarilla', 'Bueno', 46.35);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (14, 'Desinfectante para manos 500 ml', 'Bueno', 34.92);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (15, 'Capa de agua para lluvia talla L', 'Desgastado', 50.98);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (16, 'Overol de trabajo talla XXL', 'Regular', 227.54);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (17, 'Botiquin de primeros auxilios completo', 'Nuevo', 135.75);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (18, 'Tacho de recoleccion manual 80 L', 'Regular', 51.57);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (19, 'Lentes de proteccion lunas oscuras', 'Nuevo', 27.65);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (20, 'Overol de trabajo talla M', 'Nuevo', 172.22);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (21, 'Impermeable talla XL', 'Nuevo', 56.96);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (22, 'Gabardina de lluvia talla XL', 'Regular', 89.44);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (23, 'Camisa de trabajo manga larga talla L', 'Bueno', 74.47);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (24, 'Pantalon de trabajo reforzado talla 30', 'Desgastado', 134.01);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (25, 'Guantes anticorte talla L', 'Desgastado', 42.34);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (26, 'Tacho de basura con ruedas 120 L', 'Bueno', 320.38);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (27, 'Chaleco reflectivo talla L naranja', 'Regular', 45.4);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (28, 'Guantes de nitrilo talla M', 'Bueno', 10.86);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (29, 'Impermeable talla L', 'Regular', 67.41);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (30, 'Bolsas de residuos peligrosos (rollo x25) roja', 'Nuevo', 76.07);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (31, 'Calcetines termicos talla M', 'Bueno', 19.62);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (32, 'Cepillo de barrido cerdas plasticas', 'Bueno', 23.87);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (33, 'Overol de trabajo talla XL', 'Regular', 218.74);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (34, 'Casco de seguridad naranja', 'Bueno', 51.46);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (35, 'Lentes de proteccion antiempanante', 'Desgastado', 25.11);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (36, 'Calcetines termicos talla L', 'Nuevo', 18.51);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (37, 'Bidon de agua para personal 10 L', 'Nuevo', 45.48);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (38, 'Pantalon de trabajo reforzado talla 34', 'Regular', 153.52);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (39, 'Mascarilla con filtro cara completa', 'Bueno', 102.07);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (40, 'Guantes anticorte talla M', 'Regular', 35.89);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (41, 'Guantes de nitrilo talla XL', 'Regular', 9.87);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (42, 'Capa de agua para lluvia talla XL', 'Nuevo', 42.54);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (43, 'Guantes de nitrilo talla S', 'Nuevo', 9.44);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (44, 'Gorra con proteccion solar talla unica', 'Regular', 30.72);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (45, 'Impermeable talla M', 'Nuevo', 87.5);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (46, 'Botas de goma con punta de acero No 40', 'Regular', 125.64);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (47, 'Tacho de basura con ruedas 240 L', 'Regular', 440.06);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (48, 'Bolsas de residuos (rollo x50) calibre 4', 'Regular', 43.07);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (49, 'Guantes de cuero reforzado talla L', 'Bueno', 38.7);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (50, 'Casco de seguridad azul', 'Regular', 69.96);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (51, 'Botas de goma con punta de acero No 42', 'Nuevo', 226.85);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (52, 'Overol de trabajo talla L', 'Bueno', 164.03);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (53, 'Botas de goma con punta de acero No 38', 'Nuevo', 180.55);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (54, 'Overol de trabajo talla S', 'Nuevo', 257.6);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (55, 'Faja lumbar talla XL', 'Regular', 87.99);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (56, 'Linterna frontal a pilas', 'Nuevo', 63.52);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (57, 'Botas de goma con punta de acero No 44', 'Desgastado', 215.77);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (58, 'Rodilleras de proteccion tipo gel', 'Nuevo', 28.6);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (59, 'Gabardina de lluvia talla L', 'Nuevo', 88.95);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (60, 'Linterna frontal recargable', 'Desgastado', 29.95);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (61, 'Camisa de trabajo manga larga talla S', 'Nuevo', 95.54);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (62, 'Camisa de trabajo manga larga talla XL', 'Nuevo', 113.88);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (63, 'Chaleco reflectivo talla M verde', 'Regular', 48.94);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (64, 'Carretilla dos ruedas', 'Bueno', 311.5);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (65, 'Cepillo de barrido cerdas naturales', 'Bueno', 19.69);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (66, 'Escoba industrial cerdas duras', 'Bueno', 35.6);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (67, 'Mascarilla con filtro media cara', 'Nuevo', 112.12);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (68, 'Guantes de cuero reforzado talla XL', 'Regular', 26.94);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (69, 'Escoba industrial mango corto', 'Bueno', 40.55);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (70, 'Chaleco reflectivo talla M naranja', 'Regular', 36.87);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (71, 'Camisa de trabajo manga larga talla M', 'Nuevo', 73.94);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (72, 'Bolsas de residuos (rollo x50) calibre 3', 'Bueno', 65.68);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (73, 'Lentes de proteccion lunas claras', 'Regular', 24.53);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (74, 'Tacho de recoleccion manual 50 L', 'Bueno', 76.6);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (75, 'Pala recolectora mango de madera', 'Desgastado', 70.48);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (76, 'Bidon de agua para personal 20 L', 'Bueno', 31.03);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (77, 'Mascarilla con filtro N95', 'Regular', 95.55);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (78, 'Casco de seguridad amarillo', 'Nuevo', 78.68);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (79, 'Botiquin de primeros auxilios basico', 'Regular', 151.22);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (80, 'Pinza recogedora 90 cm', 'Nuevo', 37.93);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (81, 'Cinta reflectiva para brazo naranja', 'Nuevo', 14.7);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (82, 'Pinza recogedora 60 cm', 'Regular', 20.76);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (83, 'Gabardina de lluvia talla M', 'Regular', 87.58);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (84, 'Pala recolectora mango metalico', 'Bueno', 46.46);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (85, 'Botas de goma con punta de acero No 43', 'Bueno', 157.29);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (86, 'Desinfectante para manos 5 L', 'Regular', 70.07);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (87, 'Protector auditivo tipo copa', 'Nuevo', 21.28);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (88, 'Calcetines termicos talla XL', 'Bueno', 24.23);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (89, 'Botas de goma con punta de acero No 39', 'Nuevo', 225.32);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (90, 'Pantalon de trabajo reforzado talla 38', 'Nuevo', 129.53);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (91, 'Capa de agua para lluvia talla M', 'Regular', 48.73);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (92, 'Desinfectante para manos 1 L', 'Regular', 79.85);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (93, 'Casco de seguridad blanco', 'Regular', 77.55);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (94, 'Pantalon de trabajo reforzado talla 32', 'Bueno', 97.91);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (95, 'Rastrillo 12 dientes', 'Nuevo', 42.96);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (96, 'Botas de goma con punta de acero No 41', 'Bueno', 123.83);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (97, 'Protector auditivo tipo tapon', 'Bueno', 16.6);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (98, 'Rodilleras de proteccion talla unica', 'Bueno', 33.1);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (99, 'Rastrillo 16 dientes', 'Nuevo', 55.0);
INSERT INTO MATERIAL_TRABAJO (idMaterial, nombre, estado, precio) VALUES (100, 'Bolsas de residuos (rollo x50) calibre 5', 'Nuevo', 64.51);

-- VIA (distribucion coherente por zona y pertenencia)  (100 filas)
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (1, 'Avenida Fernando Guachalla, cuadras 4 a 5', 'Avenida', 1);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (2, 'Avenida Garita de Lima, cuadras 12 a 14', 'Avenida', 2);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (3, 'Avenida Argentina, cuadras 10 a 13', 'Avenida', 3);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (4, 'Calle Uruguay, cuadras 10 a 12', 'Calle', 4);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (5, 'Avenida Bolivar, cuadras 5 a 8', 'Avenida', 5);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (6, 'Avenida Junin, cuadras 3 a 4', 'Avenida', 6);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (7, 'Calle 16 de Julio, cuadras 2 a 4', 'Calle', 7);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (8, 'Calle Canada Strongest, cuadras 2 a 5', 'Calle', 8);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (9, 'Calle Jacinto Benavente, cuadras 6 a 9', 'Calle', 9);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (10, 'Calle Bueno, cuadras 11 a 14', 'Calle', 10);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (11, 'Calle Eloy Salmon, cuadras 9 a 11', 'Calle', 11);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (12, 'Calle Ingavi, cuadras 10 a 11', 'Calle', 12);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (13, 'Calle Beni, cuadras 6 a 7', 'Calle', 13);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (14, 'Calle Panama, cuadras 5 a 6', 'Calle', 14);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (15, 'Calle Armentia, cuadras 7 a 9', 'Calle', 15);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (16, 'Calle Tomas Frias, cuadras 1 a 2', 'Calle', 16);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (17, 'Calle Genaro Sanjines, cuadras 4 a 5', 'Calle', 17);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (18, 'Calle Manuel Castillo, cuadras 2 a 3', 'Calle', 18);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (19, 'Avenida Yungas, cuadras 9 a 12', 'Avenida', 19);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (20, 'Calle Landivar, cuadras 6 a 8', 'Calle', 20);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (21, 'Avenida Hernando Siles, cuadras 11 a 14', 'Avenida', 21);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (22, 'Avenida Lima, cuadras 10 a 11', 'Avenida', 22);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (23, 'Calle Caracas, cuadras 6 a 9', 'Calle', 23);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (24, 'Calle Venezuela, cuadras 10 a 12', 'Calle', 24);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (25, 'Calle Pichincha, cuadras 11 a 12', 'Calle', 25);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (26, 'Avenida Mercado, cuadras 6 a 9', 'Avenida', 26);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (27, 'Avenida Rafael Zubieta, cuadras 5 a 7', 'Avenida', 27);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (28, 'Calle Rodriguez, cuadras 6 a 7', 'Calle', 28);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (29, 'Avenida Canaviri, cuadras 12 a 14', 'Avenida', 29);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (30, 'Calle Federico Zuazo, cuadras 5 a 8', 'Calle', 30);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (31, 'Calle Busch, cuadras 5 a 8', 'Calle', 31);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (32, 'Calle Belisario Salinas, cuadras 5 a 7', 'Calle', 32);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (33, 'Calle Indaburo, cuadras 10 a 11', 'Calle', 33);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (34, 'Avenida Sagarnaga, cuadras 6 a 7', 'Avenida', 34);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (35, 'Avenida Asuncion, cuadras 1 a 4', 'Avenida', 35);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (36, 'Calle Guayaquil, cuadras 3 a 6', 'Calle', 36);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (37, 'Calle Tiahuanacu, cuadras 2 a 3', 'Calle', 37);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (38, 'Calle Quito, cuadras 9 a 11', 'Calle', 38);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (39, 'Avenida Buenos Aires, cuadras 11 a 14', 'Avenida', 39);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (40, 'Calle Munoz Reyes, cuadras 1 a 3', 'Calle', 40);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (41, 'Avenida Ismael Montes, cuadras 3 a 5', 'Avenida', 1);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (42, 'Calle Tumusla, cuadras 7 a 9', 'Calle', 2);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (43, 'Calle Santa Cruz, cuadras 7 a 10', 'Calle', 3);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (44, 'Calle Landaeta, cuadras 3 a 4', 'Calle', 4);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (45, 'Avenida Sucre, cuadras 1 a 4', 'Avenida', 5);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (46, 'Avenida Yanacocha, cuadras 9 a 12', 'Avenida', 6);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (47, 'Avenida Pasoskanki, cuadras 7 a 9', 'Avenida', 7);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (48, 'Calle Esteban Arce, cuadras 4 a 5', 'Calle', 8);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (49, 'Calle Tarapaca, cuadras 5 a 8', 'Calle', 9);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (50, 'Calle Almirante Grau, cuadras 7 a 9', 'Calle', 10);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (51, 'Calle Claudio Aliaga, cuadras 3 a 6', 'Calle', 11);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (52, 'Avenida Ecuador, cuadras 2 a 3', 'Avenida', 12);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (53, 'Avenida Max Paredes, cuadras 1 a 4', 'Avenida', 13);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (54, 'Avenida Camacho, cuadras 5 a 7', 'Avenida', 14);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (55, 'Avenida Linares, cuadras 9 a 12', 'Avenida', 15);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (56, 'Calle Juan de la Riva, cuadras 1 a 4', 'Calle', 16);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (57, 'Calle Murillo, cuadras 11 a 12', 'Calle', 17);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (58, 'Calle Victor Sanjines, cuadras 1 a 2', 'Calle', 18);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (59, 'Avenida Montes, cuadras 9 a 10', 'Avenida', 19);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (60, 'Avenida Pando, cuadras 7 a 10', 'Avenida', 20);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (61, 'Calle Calama, cuadras 4 a 7', 'Calle', 21);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (62, 'Calle Arce, cuadras 6 a 7', 'Calle', 22);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (63, 'Calle Sanjines, cuadras 6 a 8', 'Calle', 23);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (64, 'Avenida Mejillones, cuadras 8 a 11', 'Avenida', 24);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (65, 'Calle 6 de Agosto, cuadras 11 a 14', 'Calle', 25);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (66, 'Calle Brasil, cuadras 4 a 5', 'Calle', 26);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (67, 'Avenida Pedro Salazar, cuadras 7 a 8', 'Avenida', 27);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (68, 'Calle Av. del Ejercito, cuadras 1 a 3', 'Calle', 28);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (69, 'Avenida Loayza, cuadras 12 a 14', 'Avenida', 29);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (70, 'Calle Evaristo Valle, cuadras 11 a 12', 'Calle', 30);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (71, 'Calle Oruro, cuadras 5 a 7', 'Calle', 31);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (72, 'Avenida Rosendo Gutierrez, cuadras 12 a 14', 'Avenida', 32);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (73, 'Calle Bogota, cuadras 12 a 15', 'Calle', 33);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (74, 'Calle Costanera, cuadras 1 a 4', 'Calle', 34);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (75, 'Calle Colombia, cuadras 12 a 15', 'Calle', 35);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (76, 'Calle Ballivian, cuadras 10 a 11', 'Calle', 36);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (77, 'Calle Toledo, cuadras 7 a 10', 'Calle', 37);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (78, 'Avenida Tarija, cuadras 11 a 14', 'Avenida', 38);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (79, 'Calle Comercio, cuadras 9 a 10', 'Calle', 39);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (80, 'Calle 20 de Octubre, cuadras 3 a 6', 'Calle', 40);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (81, 'Calle Capitan Ravelo, cuadras 6 a 9', 'Calle', 1);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (82, 'Calle Antofagasta, cuadras 5 a 6', 'Calle', 2);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (83, 'Avenida Mariscal Santa Cruz, cuadras 10 a 13', 'Avenida', 3);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (84, 'Calle Mayor Rocha, cuadras 3 a 5', 'Calle', 4);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (85, 'Calle Heroinas, cuadras 9 a 11', 'Calle', 5);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (86, 'Calle Ladislao Cabrera, cuadras 3 a 5', 'Calle', 6);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (87, 'Calle Viacha, cuadras 12 a 15', 'Calle', 7);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (88, 'Calle Copacabana, cuadras 10 a 13', 'Calle', 8);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (89, 'Calle Zoilo Flores, cuadras 7 a 9', 'Calle', 9);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (90, 'Avenida Peru, cuadras 3 a 6', 'Avenida', 10);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (91, 'Avenida Ayacucho, cuadras 1 a 2', 'Avenida', 11);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (92, 'Calle Illampu, cuadras 9 a 10', 'Calle', 12);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (93, 'Calle Chile, cuadras 1 a 2', 'Calle', 13);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (94, 'Avenida Montevideo, cuadras 11 a 14', 'Avenida', 14);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (95, 'Avenida Colon, cuadras 1 a 3', 'Avenida', 15);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (96, 'Calle Jaen, cuadras 6 a 8', 'Calle', 16);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (97, 'Calle Inca Llojeta, cuadras 9 a 10', 'Calle', 17);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (98, 'Avenida Cochabamba, cuadras 10 a 11', 'Avenida', 18);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (99, 'Calle Aspiazu, cuadras 2 a 4', 'Calle', 19);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (100, 'Calle Chuquisaca, cuadras 2 a 5', 'Calle', 20);

-- CONTENEDOR (distribucion coherente por zona y pertenencia)  (100 filas)
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (1, 'Reciclable - plastico (amarillo)', '660 L', 'Mediano', 1);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (2, 'Reciclable - papel y carton (azul)', '5 m3', 'Grande', 2);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (3, 'Reciclable - papel y carton (azul)', '1100 L', 'Grande', 3);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (4, 'Organico (verde)', '3 m3', 'Grande', 4);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (5, 'Inorganico (gris)', '660 L', 'Mediano', 5);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (6, 'Reciclable - plastico (amarillo)', '3 m3', 'Grande', 6);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (7, 'Organico (verde)', '120 L', 'Pequeno', 7);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (8, 'Organico (verde)', '1100 L', 'Grande', 8);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (9, 'Reciclable - papel y carton (azul)', '660 L', 'Mediano', 9);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (10, 'Mixto (negro)', '240 L', 'Pequeno', 10);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (11, 'Reciclable - papel y carton (azul)', '1100 L', 'Grande', 11);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (12, 'Reciclable - vidrio (blanco)', '660 L', 'Mediano', 12);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (13, 'Mixto (negro)', '5 m3', 'Grande', 13);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (14, 'Reciclable - plastico (amarillo)', '660 L', 'Mediano', 14);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (15, 'Inorganico (gris)', '1100 L', 'Grande', 15);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (16, 'Mixto (negro)', '660 L', 'Mediano', 16);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (17, 'Reciclable - papel y carton (azul)', '1100 L', 'Grande', 17);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (18, 'Reciclable - plastico (amarillo)', '240 L', 'Pequeno', 18);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (19, 'Reciclable - plastico (amarillo)', '5 m3', 'Grande', 19);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (20, 'Mixto (negro)', '5 m3', 'Grande', 20);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (21, 'Reciclable - plastico (amarillo)', '660 L', 'Mediano', 21);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (22, 'Organico (verde)', '660 L', 'Mediano', 22);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (23, 'Reciclable - plastico (amarillo)', '660 L', 'Mediano', 23);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (24, 'Reciclable - vidrio (blanco)', '5 m3', 'Grande', 24);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (25, 'Inorganico (gris)', '660 L', 'Mediano', 25);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (26, 'Reciclable - vidrio (blanco)', '120 L', 'Pequeno', 26);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (27, 'Reciclable - papel y carton (azul)', '3 m3', 'Grande', 27);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (28, 'Mixto (negro)', '1100 L', 'Grande', 28);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (29, 'Organico (verde)', '3 m3', 'Grande', 29);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (30, 'Reciclable - papel y carton (azul)', '5 m3', 'Grande', 30);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (31, 'Reciclable - papel y carton (azul)', '120 L', 'Pequeno', 31);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (32, 'Reciclable - plastico (amarillo)', '5 m3', 'Grande', 32);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (33, 'Mixto (negro)', '3 m3', 'Grande', 33);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (34, 'Inorganico (gris)', '1100 L', 'Grande', 34);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (35, 'Mixto (negro)', '660 L', 'Mediano', 35);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (36, 'Reciclable - plastico (amarillo)', '5 m3', 'Grande', 36);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (37, 'Organico (verde)', '660 L', 'Mediano', 37);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (38, 'Mixto (negro)', '660 L', 'Mediano', 38);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (39, 'Reciclable - papel y carton (azul)', '3 m3', 'Grande', 39);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (40, 'Reciclable - vidrio (blanco)', '1100 L', 'Grande', 40);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (41, 'Reciclable - plastico (amarillo)', '1100 L', 'Grande', 41);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (42, 'Organico (verde)', '120 L', 'Pequeno', 42);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (43, 'Inorganico (gris)', '5 m3', 'Grande', 43);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (44, 'Mixto (negro)', '660 L', 'Mediano', 44);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (45, 'Organico (verde)', '240 L', 'Pequeno', 45);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (46, 'Reciclable - vidrio (blanco)', '660 L', 'Mediano', 46);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (47, 'Mixto (negro)', '660 L', 'Mediano', 47);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (48, 'Reciclable - vidrio (blanco)', '5 m3', 'Grande', 48);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (49, 'Reciclable - vidrio (blanco)', '120 L', 'Pequeno', 49);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (50, 'Inorganico (gris)', '660 L', 'Mediano', 50);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (51, 'Reciclable - plastico (amarillo)', '240 L', 'Pequeno', 51);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (52, 'Mixto (negro)', '240 L', 'Pequeno', 52);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (53, 'Reciclable - papel y carton (azul)', '120 L', 'Pequeno', 53);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (54, 'Reciclable - plastico (amarillo)', '5 m3', 'Grande', 54);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (55, 'Mixto (negro)', '3 m3', 'Grande', 55);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (56, 'Inorganico (gris)', '120 L', 'Pequeno', 56);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (57, 'Reciclable - papel y carton (azul)', '1100 L', 'Grande', 57);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (58, 'Inorganico (gris)', '3 m3', 'Grande', 58);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (59, 'Reciclable - vidrio (blanco)', '240 L', 'Pequeno', 59);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (60, 'Mixto (negro)', '5 m3', 'Grande', 60);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (61, 'Reciclable - papel y carton (azul)', '660 L', 'Mediano', 61);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (62, 'Reciclable - vidrio (blanco)', '1100 L', 'Grande', 62);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (63, 'Reciclable - plastico (amarillo)', '660 L', 'Mediano', 63);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (64, 'Organico (verde)', '5 m3', 'Grande', 64);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (65, 'Inorganico (gris)', '120 L', 'Pequeno', 65);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (66, 'Reciclable - papel y carton (azul)', '660 L', 'Mediano', 1);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (67, 'Reciclable - plastico (amarillo)', '240 L', 'Pequeno', 2);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (68, 'Reciclable - papel y carton (azul)', '3 m3', 'Grande', 3);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (69, 'Reciclable - plastico (amarillo)', '660 L', 'Mediano', 4);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (70, 'Reciclable - vidrio (blanco)', '120 L', 'Pequeno', 5);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (71, 'Organico (verde)', '5 m3', 'Grande', 6);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (72, 'Mixto (negro)', '5 m3', 'Grande', 7);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (73, 'Mixto (negro)', '3 m3', 'Grande', 8);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (74, 'Reciclable - papel y carton (azul)', '1100 L', 'Grande', 9);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (75, 'Organico (verde)', '3 m3', 'Grande', 10);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (76, 'Reciclable - vidrio (blanco)', '660 L', 'Mediano', 11);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (77, 'Reciclable - papel y carton (azul)', '5 m3', 'Grande', 12);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (78, 'Reciclable - papel y carton (azul)', '240 L', 'Pequeno', 13);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (79, 'Reciclable - vidrio (blanco)', '240 L', 'Pequeno', 14);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (80, 'Reciclable - papel y carton (azul)', '3 m3', 'Grande', 15);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (81, 'Reciclable - plastico (amarillo)', '5 m3', 'Grande', 16);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (82, 'Reciclable - vidrio (blanco)', '240 L', 'Pequeno', 17);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (83, 'Reciclable - plastico (amarillo)', '240 L', 'Pequeno', 18);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (84, 'Reciclable - plastico (amarillo)', '3 m3', 'Grande', 19);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (85, 'Inorganico (gris)', '3 m3', 'Grande', 20);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (86, 'Reciclable - papel y carton (azul)', '5 m3', 'Grande', 21);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (87, 'Inorganico (gris)', '3 m3', 'Grande', 22);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (88, 'Reciclable - papel y carton (azul)', '660 L', 'Mediano', 23);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (89, 'Reciclable - plastico (amarillo)', '3 m3', 'Grande', 24);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (90, 'Mixto (negro)', '3 m3', 'Grande', 25);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (91, 'Inorganico (gris)', '3 m3', 'Grande', 26);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (92, 'Mixto (negro)', '240 L', 'Pequeno', 27);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (93, 'Inorganico (gris)', '240 L', 'Pequeno', 28);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (94, 'Reciclable - vidrio (blanco)', '120 L', 'Pequeno', 29);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (95, 'Organico (verde)', '660 L', 'Mediano', 30);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (96, 'Inorganico (gris)', '240 L', 'Pequeno', 31);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (97, 'Reciclable - vidrio (blanco)', '5 m3', 'Grande', 32);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (98, 'Inorganico (gris)', '1100 L', 'Grande', 33);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (99, 'Inorganico (gris)', '5 m3', 'Grande', 34);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, tamanio, idVia) VALUES (100, 'Inorganico (gris)', '5 m3', 'Grande', 35);

-- CONDUCTOR (especializacion PERSONA)  (100 filas)
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (1, '3208492', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (2, '8288157', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (3, '4218412', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (4, '3619859', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (5, '4983700', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (6, '8377584', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (7, '6683798', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (8, '4594126', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (9, '3522827', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (10, '5579477', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (11, '9703525', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (12, '2856408', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (13, '2423731', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (14, '3948653', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (15, '1997818', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (16, '4242107', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (17, '4641146', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (18, '8647303', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (19, '1439960', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (20, '7432469', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (21, '1378451', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (22, '6549830', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (23, '8125873', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (24, '5987298', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (25, '1509931', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (26, '3213632', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (27, '2302360', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (28, '2367941', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (29, '9582446', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (30, '2375903', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (31, '2616557', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (32, '9730886', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (33, '9011637', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (34, '5783671', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (35, '2565524', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (36, '5553337', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (37, '8534860', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (38, '8715601', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (39, '8549565', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (40, '6726576', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (41, '1931893', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (42, '3033530', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (43, '5443865', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (44, '6787822', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (45, '5380768', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (46, '4417834', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (47, '7229406', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (48, '7115167', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (49, '9815730', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (50, '5957161', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (51, '6055309', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (52, '3549613', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (53, '5104829', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (54, '6429469', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (55, '8469808', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (56, '4511305', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (57, '9121324', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (58, '6405257', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (59, '2353391', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (60, '9393438', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (61, '7454359', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (62, '3698332', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (63, '5294752', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (64, '8706395', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (65, '3919835', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (66, '5038984', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (67, '6786946', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (68, '2563432', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (69, '3127270', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (70, '6957236', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (71, '7717965', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (72, '7173915', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (73, '1636346', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (74, '5559749', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (75, '6766677', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (76, '6713375', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (77, '8096795', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (78, '8130403', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (79, '7267122', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (80, '4459135', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (81, '1594037', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (82, '2160278', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (83, '3093647', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (84, '7070351', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (85, '4951670', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (86, '7913139', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (87, '8304167', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (88, '2561447', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (89, '3380938', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (90, '2824216', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (91, '3898625', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (92, '8014538', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (93, '1414189', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (94, '2160771', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (95, '4863226', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (96, '8335856', 'C');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (97, '9939117', 'A');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (98, '5482433', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (99, '7867461', 'B');
INSERT INTO CONDUCTOR (idconductor, nro_licencia, categoria_licencia) VALUES (100, '8434501', 'C');

-- TRANSPORTE (conductor 1:N y botadero 1:N)  (100 filas)
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (1, '9735-XXD', 'Camion compactador', '12 toneladas', 'Operativo', 1, 1);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (2, '4293-AXN', 'Camioneta recolectora', '2 toneladas', 'Operativo', 2, 2);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (3, '1253-BVD', 'Camion compactador', '15 toneladas', 'Operativo', 3, 3);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (4, '2581-RMV', 'Volqueta', '10 toneladas', 'Operativo', 4, 4);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (5, '1876-RAJ', 'Camion compactador', '10 toneladas', 'En mantenimiento', 5, 5);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (6, '9820-AUH', 'Camion compactador', '10 toneladas', 'En mantenimiento', 6, 6);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (7, '7293-MGP', 'Camion baranda', '6 toneladas', 'Operativo', 7, 7);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (8, '2065-AVZ', 'Camion compactador', '10 toneladas', 'Operativo', 8, 8);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (9, '5351-YEL', 'Volqueta', '8 toneladas', 'Fuera de servicio', 9, 9);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (10, '8434-VUB', 'Volqueta', '10 toneladas', 'Operativo', 10, 10);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (11, '8301-JHF', 'Camion baranda', '5 toneladas', 'Operativo', 11, 11);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (12, '4066-AYG', 'Camion compactador', '12 toneladas', 'Operativo', 12, 12);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (13, '1815-RHT', 'Camion baranda', '6 toneladas', 'En mantenimiento', 13, 13);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (14, '7965-FKA', 'Camion compactador', '15 toneladas', 'En mantenimiento', 14, 14);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (15, '1241-ADP', 'Camion compactador', '15 toneladas', 'Operativo', 15, 15);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (16, '2432-UMF', 'Camion compactador', '10 toneladas', 'Operativo', 16, 16);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (17, '7800-MDD', 'Camion baranda', '5 toneladas', 'Fuera de servicio', 17, 17);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (18, '6447-JAJ', 'Camion baranda', '6 toneladas', 'Operativo', 18, 18);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (19, '5455-KYZ', 'Camion compactador', '10 toneladas', 'En mantenimiento', 19, 19);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (20, '1368-TPE', 'Volqueta', '8 toneladas', 'Operativo', 20, 20);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (21, '3542-JEP', 'Camion baranda', '5 toneladas', 'Operativo', 21, 21);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (22, '1319-FLR', 'Camion compactador', '15 toneladas', 'Operativo', 22, 22);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (23, '9243-LFT', 'Camioneta recolectora', '2 toneladas', 'Operativo', 23, 23);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (24, '2404-CAM', 'Camion compactador', '15 toneladas', 'Operativo', 24, 24);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (25, '1372-CVY', 'Volqueta', '8 toneladas', 'Operativo', 25, 25);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (26, '4799-GPB', 'Volqueta', '8 toneladas', 'Operativo', 26, 26);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (27, '7116-HZX', 'Camion compactador', '15 toneladas', 'En mantenimiento', 27, 27);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (28, '5005-ZUN', 'Camion compactador', '12 toneladas', 'Operativo', 28, 28);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (29, '8426-MZA', 'Camion compactador', '12 toneladas', 'Operativo', 29, 29);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (30, '7146-LBA', 'Camion compactador', '15 toneladas', 'Operativo', 30, 30);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (31, '4154-SMC', 'Camioneta recolectora', '2 toneladas', 'Operativo', 31, 31);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (32, '3281-DFX', 'Camion compactador', '10 toneladas', 'Operativo', 32, 32);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (33, '4104-MCU', 'Camion baranda', '6 toneladas', 'Operativo', 33, 33);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (34, '4597-HFE', 'Volqueta', '8 toneladas', 'Operativo', 34, 34);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (35, '1537-URG', 'Volqueta', '8 toneladas', 'Fuera de servicio', 35, 35);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (36, '3573-TYV', 'Volqueta', '10 toneladas', 'Operativo', 36, 1);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (37, '6876-FBY', 'Camion baranda', '5 toneladas', 'Operativo', 37, 2);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (38, '1642-HDA', 'Camion baranda', '5 toneladas', 'Operativo', 38, 3);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (39, '6180-MNP', 'Camion compactador', '15 toneladas', 'Operativo', 39, 4);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (40, '9151-NBK', 'Camioneta recolectora', '1.5 toneladas', 'Operativo', 40, 5);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (41, '4624-NRH', 'Camion compactador', '15 toneladas', 'Fuera de servicio', 41, 6);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (42, '9956-RJB', 'Camion compactador', '10 toneladas', 'Operativo', 42, 7);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (43, '9550-MEE', 'Volqueta', '10 toneladas', 'En mantenimiento', 43, 8);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (44, '9549-EPD', 'Camion compactador', '12 toneladas', 'Operativo', 44, 9);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (45, '1433-RZA', 'Camion compactador', '12 toneladas', 'Operativo', 45, 10);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (46, '7790-UHU', 'Camion compactador', '12 toneladas', 'En mantenimiento', 46, 11);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (47, '4916-ZLG', 'Camion compactador', '15 toneladas', 'Operativo', 47, 12);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (48, '7751-RHA', 'Volqueta', '10 toneladas', 'Operativo', 48, 13);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (49, '6757-RKX', 'Camioneta recolectora', '2 toneladas', 'En mantenimiento', 49, 14);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (50, '6323-LHF', 'Camion compactador', '10 toneladas', 'Operativo', 50, 15);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (51, '1995-JLR', 'Camion compactador', '12 toneladas', 'Operativo', 51, 16);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (52, '6832-JDT', 'Camion compactador', '10 toneladas', 'Operativo', 52, 17);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (53, '7032-KKD', 'Camion compactador', '10 toneladas', 'Operativo', 53, 18);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (54, '2084-FLD', 'Camion compactador', '15 toneladas', 'Operativo', 54, 19);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (55, '2366-NSS', 'Volqueta', '10 toneladas', 'Operativo', 55, 20);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (56, '8147-LBN', 'Camion compactador', '10 toneladas', 'Operativo', 56, 21);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (57, '5714-DRG', 'Camion baranda', '5 toneladas', 'En mantenimiento', 57, 22);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (58, '5296-PEG', 'Camion compactador', '12 toneladas', 'Operativo', 58, 23);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (59, '6035-FZG', 'Camion compactador', '15 toneladas', 'En mantenimiento', 59, 24);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (60, '9611-UFV', 'Volqueta', '10 toneladas', 'En mantenimiento', 60, 25);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (61, '7593-HPY', 'Volqueta', '10 toneladas', 'En mantenimiento', 61, 26);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (62, '1536-SBK', 'Camion baranda', '6 toneladas', 'En mantenimiento', 62, 27);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (63, '4651-MAT', 'Camion compactador', '15 toneladas', 'En mantenimiento', 63, 28);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (64, '1830-EPE', 'Camion baranda', '6 toneladas', 'Operativo', 64, 29);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (65, '8295-KMB', 'Camioneta recolectora', '2 toneladas', 'Operativo', 65, 30);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (66, '7785-JMX', 'Camion baranda', '5 toneladas', 'En mantenimiento', 1, 31);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (67, '6603-TJV', 'Camion compactador', '10 toneladas', 'Operativo', 2, 32);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (68, '3437-FPT', 'Camioneta recolectora', '1.5 toneladas', 'En mantenimiento', 3, 33);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (69, '3003-XRM', 'Camion compactador', '15 toneladas', 'Operativo', 4, 34);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (70, '5852-MGN', 'Camion compactador', '15 toneladas', 'Operativo', 5, 35);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (71, '3388-SRH', 'Camion compactador', '12 toneladas', 'Operativo', 6, 1);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (72, '8731-DLN', 'Volqueta', '10 toneladas', 'Operativo', 7, 2);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (73, '7176-GHZ', 'Camion baranda', '5 toneladas', 'Operativo', 8, 3);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (74, '9160-YJR', 'Camioneta recolectora', '1.5 toneladas', 'Operativo', 9, 4);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (75, '4072-DVV', 'Camion compactador', '12 toneladas', 'Operativo', 10, 5);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (76, '6223-PEZ', 'Camion compactador', '12 toneladas', 'En mantenimiento', 11, 6);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (77, '2160-YDG', 'Camion compactador', '10 toneladas', 'En mantenimiento', 12, 7);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (78, '7344-DUX', 'Camion compactador', '12 toneladas', 'Operativo', 13, 8);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (79, '4464-MPY', 'Camion compactador', '10 toneladas', 'Operativo', 14, 9);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (80, '3532-MBC', 'Camioneta recolectora', '2 toneladas', 'Operativo', 15, 10);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (81, '4618-DMR', 'Camion compactador', '12 toneladas', 'Operativo', 16, 11);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (82, '9975-XMX', 'Camion baranda', '6 toneladas', 'Operativo', 17, 12);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (83, '3825-HCC', 'Camion baranda', '6 toneladas', 'En mantenimiento', 18, 13);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (84, '5363-ELM', 'Camioneta recolectora', '2 toneladas', 'Operativo', 19, 14);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (85, '6039-BRC', 'Camion baranda', '5 toneladas', 'Operativo', 20, 15);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (86, '1591-MLH', 'Camion compactador', '15 toneladas', 'Operativo', 21, 16);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (87, '5394-ZPG', 'Volqueta', '8 toneladas', 'Operativo', 22, 17);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (88, '7261-MAY', 'Camion compactador', '15 toneladas', 'Operativo', 23, 18);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (89, '9882-NJY', 'Volqueta', '10 toneladas', 'Operativo', 24, 19);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (90, '8138-JVA', 'Camioneta recolectora', '1.5 toneladas', 'Operativo', 25, 20);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (91, '3001-LLD', 'Camion compactador', '12 toneladas', 'Operativo', 26, 21);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (92, '3099-VRA', 'Camion compactador', '15 toneladas', 'Operativo', 27, 22);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (93, '9967-PJN', 'Camion compactador', '12 toneladas', 'Operativo', 28, 23);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (94, '8389-JCC', 'Camioneta recolectora', '1.5 toneladas', 'Operativo', 29, 24);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (95, '8488-ETV', 'Camion compactador', '15 toneladas', 'Operativo', 30, 25);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (96, '8951-YDD', 'Camion baranda', '6 toneladas', 'Operativo', 31, 26);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (97, '9234-FRU', 'Camion compactador', '10 toneladas', 'Operativo', 32, 27);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (98, '4336-MMH', 'Camion compactador', '12 toneladas', 'En mantenimiento', 33, 28);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (99, '8751-TFF', 'Volqueta', '8 toneladas', 'Operativo', 34, 29);
INSERT INTO TRANSPORTE (idTransporte, placa, tipo_transporte, capacidad, estado, idconductor, idBotadero) VALUES (100, '4795-HXF', 'Camion compactador', '10 toneladas', 'En mantenimiento', 35, 30);

-- RECOLECTOR (especializacion PERSONA; dos por transporte asignado)  (100 filas)
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (101, 'Cargador', 3930.0, 1);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (102, 'Recolector', 4060.0, 2);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (103, 'Recolector', 3760.0, 3);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (104, 'Recolector', 3060.0, 4);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (105, 'Recolector', 3130.0, 5);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (106, 'Recolector', 3390.0, 6);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (107, 'Recolector', 3390.0, 7);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (108, 'Recolector', 3510.0, 8);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (109, 'Recolector', 3120.0, 9);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (110, 'Recolector', 3620.0, 10);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (111, 'Recolector', 3760.0, 11);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (112, 'Recolector', 3660.0, 12);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (113, 'Ayudante de recoleccion', 3240.0, 13);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (114, 'Recolector', 3640.0, 14);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (115, 'Recolector', 4170.0, 15);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (116, 'Recolector', 3020.0, 16);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (117, 'Recolector', 3880.0, 17);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (118, 'Cargador', 3230.0, 18);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (119, 'Ayudante de recoleccion', 3140.0, 19);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (120, 'Recolector', 3870.0, 20);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (121, 'Recolector', 2940.0, 21);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (122, 'Ayudante de recoleccion', 3490.0, 22);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (123, 'Recolector', 4100.0, 23);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (124, 'Ayudante de recoleccion', 3150.0, 24);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (125, 'Recolector', 3620.0, 25);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (126, 'Ayudante de recoleccion', 2930.0, 26);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (127, 'Ayudante de recoleccion', 3050.0, 27);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (128, 'Recolector', 3000.0, 28);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (129, 'Ayudante de recoleccion', 3180.0, 29);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (130, 'Ayudante de recoleccion', 3310.0, 30);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (131, 'Recolector', 3800.0, 31);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (132, 'Cargador', 2920.0, 32);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (133, 'Recolector', 3910.0, 33);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (134, 'Ayudante de recoleccion', 3470.0, 34);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (135, 'Cargador', 4200.0, 35);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (136, 'Recolector', 2990.0, 36);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (137, 'Ayudante de recoleccion', 4190.0, 37);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (138, 'Recolector', 3680.0, 38);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (139, 'Ayudante de recoleccion', 4100.0, 39);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (140, 'Recolector', 3300.0, 40);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (141, 'Ayudante de recoleccion', 2810.0, 41);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (142, 'Recolector', 3340.0, 42);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (143, 'Cargador', 3570.0, 43);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (144, 'Recolector', 2820.0, 44);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (145, 'Cargador', 3520.0, 45);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (146, 'Ayudante de recoleccion', 2950.0, 46);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (147, 'Cargador', 4050.0, 47);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (148, 'Recolector', 3780.0, 48);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (149, 'Ayudante de recoleccion', 3620.0, 49);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (150, 'Cargador', 3030.0, 50);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (151, 'Ayudante de recoleccion', 4100.0, 1);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (152, 'Recolector', 2800.0, 2);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (153, 'Ayudante de recoleccion', 2860.0, 3);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (154, 'Ayudante de recoleccion', 2940.0, 4);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (155, 'Cargador', 4040.0, 5);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (156, 'Recolector', 3600.0, 6);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (157, 'Recolector', 3670.0, 7);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (158, 'Recolector', 3520.0, 8);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (159, 'Recolector', 4200.0, 9);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (160, 'Ayudante de recoleccion', 3400.0, 10);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (161, 'Recolector', 2910.0, 11);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (162, 'Ayudante de recoleccion', 3400.0, 12);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (163, 'Recolector', 2940.0, 13);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (164, 'Ayudante de recoleccion', 4180.0, 14);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (165, 'Recolector', 3980.0, 15);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (166, 'Cargador', 3720.0, 16);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (167, 'Recolector', 4200.0, 17);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (168, 'Ayudante de recoleccion', 3120.0, 18);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (169, 'Ayudante de recoleccion', 2900.0, 19);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (170, 'Recolector', 3270.0, 20);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (171, 'Ayudante de recoleccion', 3300.0, 21);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (172, 'Cargador', 3500.0, 22);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (173, 'Recolector', 3240.0, 23);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (174, 'Recolector', 2980.0, 24);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (175, 'Recolector', 3060.0, 25);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (176, 'Recolector', 3300.0, 26);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (177, 'Recolector', 3410.0, 27);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (178, 'Ayudante de recoleccion', 3180.0, 28);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (179, 'Recolector', 3240.0, 29);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (180, 'Recolector', 4140.0, 30);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (181, 'Recolector', 3580.0, 31);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (182, 'Recolector', 3200.0, 32);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (183, 'Ayudante de recoleccion', 3930.0, 33);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (184, 'Ayudante de recoleccion', 3880.0, 34);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (185, 'Ayudante de recoleccion', 2960.0, 35);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (186, 'Recolector', 3540.0, 36);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (187, 'Recolector', 2870.0, 37);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (188, 'Recolector', 3040.0, 38);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (189, 'Cargador', 3810.0, 39);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (190, 'Ayudante de recoleccion', 3670.0, 40);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (191, 'Recolector', 3640.0, 41);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (192, 'Recolector', 2940.0, 42);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (193, 'Recolector', 3060.0, 43);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (194, 'Ayudante de recoleccion', 2920.0, 44);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (195, 'Recolector', 3190.0, 45);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (196, 'Recolector', 3370.0, 46);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (197, 'Recolector', 2870.0, 47);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (198, 'Recolector', 3140.0, 48);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (199, 'Ayudante de recoleccion', 3600.0, 49);
INSERT INTO RECOLECTOR (idrecolector, tipo_empleado, sueldo, idTransporte) VALUES (200, 'Recolector', 2940.0, 50);

-- RUTA (distribucion coherente por zona y pertenencia)  (100 filas)
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (1, '16.8 km', '22:00 - 04:00', 1);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (2, '12.6 km', '14:00 - 20:00', 2);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (3, '18.7 km', '13:00 - 18:00', 3);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (4, '22.8 km', '07:00 - 13:00', 4);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (5, '10.0 km', '07:00 - 13:00', 5);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (6, '15.9 km', '13:00 - 18:00', 6);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (7, '22.3 km', '13:00 - 18:00', 7);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (8, '15.9 km', '05:00 - 09:00', 8);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (9, '17.0 km', '22:00 - 04:00', 9);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (10, '11.1 km', '07:00 - 13:00', 10);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (11, '12.4 km', '13:00 - 18:00', 11);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (12, '10.2 km', '13:00 - 18:00', 12);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (13, '20.5 km', '06:00 - 12:00', 13);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (14, '4.2 km', '13:00 - 18:00', 14);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (15, '7.5 km', '22:00 - 04:00', 15);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (16, '4.8 km', '22:00 - 04:00', 16);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (17, '24.3 km', '19:00 - 23:00', 17);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (18, '19.1 km', '07:00 - 13:00', 18);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (19, '4.8 km', '05:00 - 09:00', 19);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (20, '12.8 km', '07:00 - 13:00', 20);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (21, '11.2 km', '14:00 - 20:00', 21);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (22, '4.7 km', '22:00 - 04:00', 22);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (23, '20.8 km', '06:00 - 12:00', 23);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (24, '7.6 km', '19:00 - 23:00', 24);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (25, '13.3 km', '06:00 - 12:00', 25);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (26, '21.8 km', '19:00 - 23:00', 26);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (27, '10.8 km', '07:00 - 13:00', 27);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (28, '12.2 km', '22:00 - 04:00', 28);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (29, '25.1 km', '19:00 - 23:00', 29);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (30, '23.5 km', '06:00 - 12:00', 30);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (31, '11.6 km', '07:00 - 13:00', 31);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (32, '10.5 km', '05:00 - 09:00', 32);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (33, '26.5 km', '05:00 - 09:00', 33);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (34, '9.2 km', '13:00 - 18:00', 34);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (35, '13.5 km', '06:00 - 12:00', 35);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (36, '7.5 km', '05:00 - 09:00', 36);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (37, '11.4 km', '22:00 - 04:00', 37);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (38, '12.7 km', '06:00 - 12:00', 38);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (39, '24.5 km', '13:00 - 18:00', 39);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (40, '18.3 km', '19:00 - 23:00', 40);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (41, '15.2 km', '06:00 - 12:00', 1);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (42, '5.5 km', '06:00 - 12:00', 2);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (43, '10.2 km', '07:00 - 13:00', 3);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (44, '9.9 km', '07:00 - 13:00', 4);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (45, '26.3 km', '07:00 - 13:00', 5);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (46, '16.9 km', '19:00 - 23:00', 6);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (47, '13.5 km', '13:00 - 18:00', 7);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (48, '19.2 km', '05:00 - 09:00', 8);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (49, '8.9 km', '05:00 - 09:00', 9);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (50, '15.0 km', '06:00 - 12:00', 10);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (51, '20.5 km', '19:00 - 23:00', 11);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (52, '26.1 km', '14:00 - 20:00', 12);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (53, '11.3 km', '14:00 - 20:00', 13);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (54, '24.2 km', '22:00 - 04:00', 14);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (55, '7.2 km', '19:00 - 23:00', 15);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (56, '10.0 km', '22:00 - 04:00', 16);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (57, '7.3 km', '13:00 - 18:00', 17);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (58, '25.8 km', '14:00 - 20:00', 18);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (59, '13.4 km', '22:00 - 04:00', 19);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (60, '26.3 km', '13:00 - 18:00', 20);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (61, '27.6 km', '22:00 - 04:00', 21);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (62, '16.8 km', '19:00 - 23:00', 22);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (63, '6.1 km', '14:00 - 20:00', 23);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (64, '18.2 km', '22:00 - 04:00', 24);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (65, '12.6 km', '14:00 - 20:00', 25);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (66, '12.7 km', '22:00 - 04:00', 26);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (67, '19.5 km', '05:00 - 09:00', 27);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (68, '4.1 km', '13:00 - 18:00', 28);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (69, '27.3 km', '06:00 - 12:00', 29);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (70, '16.9 km', '05:00 - 09:00', 30);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (71, '6.4 km', '22:00 - 04:00', 31);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (72, '24.2 km', '05:00 - 09:00', 32);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (73, '4.9 km', '19:00 - 23:00', 33);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (74, '22.5 km', '19:00 - 23:00', 34);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (75, '14.2 km', '05:00 - 09:00', 35);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (76, '26.0 km', '07:00 - 13:00', 36);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (77, '22.1 km', '14:00 - 20:00', 37);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (78, '21.6 km', '06:00 - 12:00', 38);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (79, '9.9 km', '13:00 - 18:00', 39);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (80, '16.6 km', '14:00 - 20:00', 40);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (81, '19.7 km', '19:00 - 23:00', 1);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (82, '9.4 km', '22:00 - 04:00', 2);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (83, '26.6 km', '06:00 - 12:00', 3);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (84, '26.9 km', '06:00 - 12:00', 4);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (85, '24.9 km', '07:00 - 13:00', 5);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (86, '16.1 km', '05:00 - 09:00', 6);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (87, '23.6 km', '13:00 - 18:00', 7);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (88, '23.1 km', '06:00 - 12:00', 8);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (89, '12.3 km', '14:00 - 20:00', 9);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (90, '6.9 km', '13:00 - 18:00', 10);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (91, '4.0 km', '07:00 - 13:00', 11);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (92, '11.7 km', '07:00 - 13:00', 12);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (93, '26.2 km', '19:00 - 23:00', 13);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (94, '7.6 km', '13:00 - 18:00', 14);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (95, '11.0 km', '14:00 - 20:00', 15);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (96, '11.0 km', '05:00 - 09:00', 16);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (97, '12.4 km', '07:00 - 13:00', 17);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (98, '21.0 km', '19:00 - 23:00', 18);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (99, '12.2 km', '13:00 - 18:00', 19);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona) VALUES (100, '22.7 km', '13:00 - 18:00', 20);

-- DISPONE  (PERSONA N:M MATERIAL_TRABAJO)  (100 filas)
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (11, 43, DATE '2026-01-05', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (194, 96, DATE '2026-01-14', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (3, 41, DATE '2026-01-24', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (163, 40, DATE '2026-01-24', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (53, 68, DATE '2026-01-25', 9);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (121, 54, DATE '2026-01-28', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (171, 92, DATE '2026-01-30', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (45, 52, DATE '2026-02-03', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (20, 96, DATE '2026-02-06', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (167, 73, DATE '2026-02-06', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (75, 68, DATE '2026-02-10', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (4, 48, DATE '2026-02-15', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (36, 47, DATE '2026-02-21', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (150, 8, DATE '2026-02-23', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (156, 90, DATE '2026-02-26', 9);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (29, 98, DATE '2026-03-01', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (94, 63, DATE '2026-03-01', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (182, 83, DATE '2026-03-05', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (179, 84, DATE '2026-03-09', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (29, 8, DATE '2026-03-11', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (53, 58, DATE '2026-03-11', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (112, 5, DATE '2026-03-11', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (190, 53, DATE '2026-03-13', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (68, 1, DATE '2026-03-19', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (140, 98, DATE '2026-03-19', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (151, 27, DATE '2026-03-19', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (174, 74, DATE '2026-04-07', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (62, 70, DATE '2026-04-09', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (117, 45, DATE '2026-04-13', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (186, 9, DATE '2026-04-14', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (42, 11, DATE '2026-04-15', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (114, 33, DATE '2026-04-16', 9);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (113, 94, DATE '2026-04-19', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (183, 18, DATE '2026-04-22', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (27, 22, DATE '2026-04-25', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (55, 39, DATE '2026-04-30', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (28, 79, DATE '2026-05-06', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (164, 15, DATE '2026-05-08', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (67, 58, DATE '2026-05-11', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (184, 56, DATE '2026-05-12', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (144, 52, DATE '2026-05-15', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (53, 47, DATE '2026-05-17', 9);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (199, 27, DATE '2026-05-20', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (174, 63, DATE '2026-05-24', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (66, 6, DATE '2026-05-27', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (46, 7, DATE '2026-05-28', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (79, 25, DATE '2026-05-28', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (10, 53, DATE '2026-06-01', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (180, 78, DATE '2026-06-01', 9);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (150, 57, DATE '2026-06-04', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (83, 19, DATE '2026-06-05', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (11, 52, DATE '2026-06-06', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (79, 15, DATE '2026-06-08', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (144, 57, DATE '2026-06-18', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (22, 93, DATE '2026-06-29', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (66, 64, DATE '2026-07-06', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (108, 95, DATE '2026-07-09', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (125, 49, DATE '2026-07-09', 9);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (133, 96, DATE '2026-07-12', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (11, 23, DATE '2026-07-16', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (42, 35, DATE '2026-07-16', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (49, 95, DATE '2026-07-18', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (198, 46, DATE '2026-07-18', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (70, 42, DATE '2026-07-21', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (88, 10, DATE '2026-07-21', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (158, 50, DATE '2026-07-21', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (83, 95, DATE '2026-07-24', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (194, 50, DATE '2026-07-26', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (72, 45, DATE '2026-07-28', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (142, 100, DATE '2026-07-28', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (95, 12, DATE '2026-07-29', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (42, 61, DATE '2026-08-01', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (150, 20, DATE '2026-08-02', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (184, 52, DATE '2026-08-03', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (16, 61, DATE '2026-08-05', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (85, 14, DATE '2026-08-08', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (196, 20, DATE '2026-08-09', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (31, 57, DATE '2026-08-10', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (88, 78, DATE '2026-08-12', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (58, 3, DATE '2026-08-13', 9);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (119, 65, DATE '2026-08-15', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (190, 38, DATE '2026-08-15', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (167, 30, DATE '2026-08-17', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (34, 62, DATE '2026-08-18', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (116, 19, DATE '2026-08-20', 6);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (187, 62, DATE '2026-08-23', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (157, 18, DATE '2026-08-24', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (168, 50, DATE '2026-08-25', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (126, 78, DATE '2026-08-26', 5);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (69, 6, DATE '2026-09-03', 8);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (92, 65, DATE '2026-09-03', 7);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (3, 61, DATE '2026-09-06', 1);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (120, 19, DATE '2026-09-07', 2);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (173, 58, DATE '2026-09-08', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (187, 60, DATE '2026-09-09', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (199, 88, DATE '2026-09-12', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (157, 77, DATE '2026-09-13', 3);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (156, 44, DATE '2026-09-18', 10);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (24, 15, DATE '2026-09-22', 4);
INSERT INTO DISPONE (idPersona, idMaterial, fecha, cantidad) VALUES (16, 18, DATE '2026-09-23', 2);

-- INTEGRA (ruta + via + contenedor de la misma zona)  (260 filas)
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (1, 1, 1);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (1, 1, 66);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (1, 41, 41);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (2, 2, 2);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (2, 2, 67);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (2, 42, 42);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (3, 3, 3);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (3, 3, 68);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (3, 43, 43);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (4, 4, 4);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (4, 4, 69);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (4, 44, 44);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (5, 5, 5);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (5, 5, 70);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (5, 45, 45);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (6, 6, 6);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (6, 6, 71);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (6, 46, 46);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (7, 7, 7);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (7, 7, 72);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (7, 47, 47);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (8, 8, 8);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (8, 8, 73);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (8, 48, 48);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (9, 9, 9);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (9, 9, 74);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (9, 49, 49);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (10, 10, 10);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (10, 10, 75);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (10, 50, 50);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (11, 11, 11);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (11, 11, 76);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (11, 51, 51);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (12, 12, 12);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (12, 12, 77);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (12, 52, 52);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (13, 13, 13);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (13, 13, 78);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (13, 53, 53);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (14, 14, 14);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (14, 14, 79);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (14, 54, 54);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (15, 15, 15);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (15, 15, 80);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (15, 55, 55);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (16, 16, 16);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (16, 16, 81);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (16, 56, 56);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (17, 17, 17);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (17, 17, 82);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (17, 57, 57);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (18, 18, 18);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (18, 18, 83);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (18, 58, 58);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (19, 19, 19);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (19, 19, 84);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (19, 59, 59);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (20, 20, 20);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (20, 20, 85);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (20, 60, 60);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (21, 21, 21);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (21, 21, 86);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (21, 61, 61);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (22, 22, 22);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (22, 22, 87);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (22, 62, 62);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (23, 23, 23);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (23, 23, 88);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (23, 63, 63);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (24, 24, 24);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (24, 24, 89);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (24, 64, 64);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (25, 25, 25);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (25, 25, 90);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (25, 65, 65);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (26, 26, 26);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (26, 26, 91);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (27, 27, 27);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (27, 27, 92);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (28, 28, 28);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (28, 28, 93);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (29, 29, 29);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (29, 29, 94);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (30, 30, 30);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (30, 30, 95);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (31, 31, 31);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (31, 31, 96);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (32, 32, 32);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (32, 32, 97);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (33, 33, 33);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (33, 33, 98);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (34, 34, 34);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (34, 34, 99);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (35, 35, 35);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (35, 35, 100);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (36, 36, 36);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (37, 37, 37);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (38, 38, 38);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (39, 39, 39);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (40, 40, 40);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (41, 1, 1);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (41, 1, 66);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (41, 41, 41);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (42, 2, 2);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (42, 2, 67);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (42, 42, 42);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (43, 3, 3);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (43, 3, 68);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (43, 43, 43);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (44, 4, 4);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (44, 4, 69);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (44, 44, 44);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (45, 5, 5);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (45, 5, 70);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (45, 45, 45);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (46, 6, 6);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (46, 6, 71);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (46, 46, 46);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (47, 7, 7);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (47, 7, 72);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (47, 47, 47);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (48, 8, 8);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (48, 8, 73);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (48, 48, 48);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (49, 9, 9);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (49, 9, 74);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (49, 49, 49);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (50, 10, 10);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (50, 10, 75);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (50, 50, 50);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (51, 11, 11);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (51, 11, 76);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (51, 51, 51);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (52, 12, 12);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (52, 12, 77);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (52, 52, 52);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (53, 13, 13);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (53, 13, 78);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (53, 53, 53);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (54, 14, 14);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (54, 14, 79);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (54, 54, 54);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (55, 15, 15);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (55, 15, 80);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (55, 55, 55);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (56, 16, 16);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (56, 16, 81);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (56, 56, 56);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (57, 17, 17);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (57, 17, 82);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (57, 57, 57);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (58, 18, 18);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (58, 18, 83);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (58, 58, 58);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (59, 19, 19);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (59, 19, 84);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (59, 59, 59);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (60, 20, 20);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (60, 20, 85);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (60, 60, 60);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (61, 21, 21);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (61, 21, 86);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (61, 61, 61);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (62, 22, 22);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (62, 22, 87);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (62, 62, 62);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (63, 23, 23);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (63, 23, 88);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (63, 63, 63);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (64, 24, 24);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (64, 24, 89);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (64, 64, 64);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (65, 25, 25);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (65, 25, 90);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (65, 65, 65);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (66, 26, 26);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (66, 26, 91);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (67, 27, 27);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (67, 27, 92);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (68, 28, 28);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (68, 28, 93);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (69, 29, 29);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (69, 29, 94);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (70, 30, 30);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (70, 30, 95);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (71, 31, 31);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (71, 31, 96);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (72, 32, 32);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (72, 32, 97);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (73, 33, 33);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (73, 33, 98);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (74, 34, 34);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (74, 34, 99);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (75, 35, 35);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (75, 35, 100);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (76, 36, 36);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (77, 37, 37);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (78, 38, 38);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (79, 39, 39);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (80, 40, 40);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (81, 1, 1);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (81, 1, 66);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (81, 41, 41);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (82, 2, 2);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (82, 2, 67);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (82, 42, 42);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (83, 3, 3);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (83, 3, 68);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (83, 43, 43);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (84, 4, 4);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (84, 4, 69);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (84, 44, 44);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (85, 5, 5);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (85, 5, 70);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (85, 45, 45);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (86, 6, 6);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (86, 6, 71);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (86, 46, 46);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (87, 7, 7);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (87, 7, 72);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (87, 47, 47);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (88, 8, 8);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (88, 8, 73);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (88, 48, 48);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (89, 9, 9);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (89, 9, 74);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (89, 49, 49);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (90, 10, 10);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (90, 10, 75);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (90, 50, 50);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (91, 11, 11);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (91, 11, 76);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (91, 51, 51);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (92, 12, 12);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (92, 12, 77);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (92, 52, 52);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (93, 13, 13);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (93, 13, 78);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (93, 53, 53);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (94, 14, 14);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (94, 14, 79);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (94, 54, 54);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (95, 15, 15);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (95, 15, 80);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (95, 55, 55);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (96, 16, 16);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (96, 16, 81);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (96, 56, 56);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (97, 17, 17);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (97, 17, 82);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (97, 57, 57);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (98, 18, 18);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (98, 18, 83);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (98, 58, 58);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (99, 19, 19);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (99, 19, 84);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (99, 59, 59);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (100, 20, 20);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (100, 20, 85);
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (100, 60, 60);

-- PASA_POR (transportes recorren rutas en fechas concretas)  (112 filas)
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (7, 10, DATE '2026-09-01');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (8, 17, DATE '2026-09-01');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (10, 24, DATE '2026-09-01');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (11, 31, DATE '2026-09-01');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (12, 19, DATE '2026-09-02');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (15, 26, DATE '2026-09-02');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (16, 33, DATE '2026-09-02');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (18, 40, DATE '2026-09-02');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (20, 28, DATE '2026-09-03');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (21, 35, DATE '2026-09-03');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (22, 42, DATE '2026-09-03');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (23, 49, DATE '2026-09-03');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (24, 37, DATE '2026-09-04');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (25, 44, DATE '2026-09-04');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (26, 51, DATE '2026-09-04');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (28, 58, DATE '2026-09-04');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (29, 46, DATE '2026-09-05');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (30, 53, DATE '2026-09-05');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (31, 60, DATE '2026-09-05');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (32, 67, DATE '2026-09-05');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (33, 55, DATE '2026-09-06');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (34, 62, DATE '2026-09-06');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (36, 69, DATE '2026-09-06');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (37, 76, DATE '2026-09-06');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (38, 64, DATE '2026-09-07');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (39, 71, DATE '2026-09-07');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (40, 78, DATE '2026-09-07');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (42, 85, DATE '2026-09-07');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (44, 73, DATE '2026-09-08');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (45, 80, DATE '2026-09-08');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (47, 87, DATE '2026-09-08');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (48, 94, DATE '2026-09-08');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (1, 89, DATE '2026-09-09');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (2, 96, DATE '2026-09-09');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (3, 3, DATE '2026-09-09');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (50, 82, DATE '2026-09-09');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (4, 91, DATE '2026-09-10');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (7, 98, DATE '2026-09-10');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (8, 5, DATE '2026-09-10');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (10, 12, DATE '2026-09-10');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (11, 100, DATE '2026-09-11');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (12, 7, DATE '2026-09-11');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (15, 14, DATE '2026-09-11');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (16, 21, DATE '2026-09-11');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (18, 9, DATE '2026-09-12');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (20, 16, DATE '2026-09-12');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (21, 23, DATE '2026-09-12');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (22, 30, DATE '2026-09-12');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (23, 18, DATE '2026-09-13');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (24, 25, DATE '2026-09-13');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (25, 32, DATE '2026-09-13');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (26, 39, DATE '2026-09-13');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (28, 27, DATE '2026-09-14');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (29, 34, DATE '2026-09-14');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (30, 41, DATE '2026-09-14');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (31, 48, DATE '2026-09-14');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (32, 36, DATE '2026-09-15');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (33, 43, DATE '2026-09-15');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (34, 50, DATE '2026-09-15');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (36, 57, DATE '2026-09-15');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (37, 45, DATE '2026-09-16');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (38, 52, DATE '2026-09-16');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (39, 59, DATE '2026-09-16');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (40, 66, DATE '2026-09-16');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (42, 54, DATE '2026-09-17');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (44, 61, DATE '2026-09-17');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (45, 68, DATE '2026-09-17');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (47, 75, DATE '2026-09-17');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (1, 77, DATE '2026-09-18');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (2, 84, DATE '2026-09-18');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (48, 63, DATE '2026-09-18');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (50, 70, DATE '2026-09-18');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (3, 72, DATE '2026-09-19');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (4, 79, DATE '2026-09-19');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (7, 86, DATE '2026-09-19');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (8, 93, DATE '2026-09-19');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (10, 81, DATE '2026-09-20');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (11, 88, DATE '2026-09-20');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (12, 95, DATE '2026-09-20');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (15, 2, DATE '2026-09-20');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (16, 90, DATE '2026-09-21');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (18, 97, DATE '2026-09-21');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (20, 4, DATE '2026-09-21');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (21, 11, DATE '2026-09-21');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (22, 99, DATE '2026-09-22');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (23, 6, DATE '2026-09-22');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (24, 13, DATE '2026-09-22');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (25, 20, DATE '2026-09-22');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (26, 8, DATE '2026-09-23');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (28, 15, DATE '2026-09-23');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (29, 22, DATE '2026-09-23');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (30, 29, DATE '2026-09-23');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (31, 17, DATE '2026-09-24');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (32, 24, DATE '2026-09-24');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (33, 31, DATE '2026-09-24');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (34, 38, DATE '2026-09-24');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (36, 26, DATE '2026-09-25');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (37, 33, DATE '2026-09-25');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (38, 40, DATE '2026-09-25');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (39, 47, DATE '2026-09-25');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (40, 35, DATE '2026-09-26');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (42, 42, DATE '2026-09-26');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (44, 49, DATE '2026-09-26');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (45, 56, DATE '2026-09-26');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (1, 65, DATE '2026-09-27');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (47, 44, DATE '2026-09-27');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (48, 51, DATE '2026-09-27');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (50, 58, DATE '2026-09-27');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (2, 53, DATE '2026-09-28');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (3, 60, DATE '2026-09-28');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (4, 67, DATE '2026-09-28');
INSERT INTO PASA_POR (idTransporte, idRuta, fecha) VALUES (7, 74, DATE '2026-09-28');

-- TRABAJA (recolector N:M zona; zona atendida por su transporte)  (224 filas)
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (107, 10, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (108, 17, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (110, 24, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (111, 31, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (157, 10, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (158, 17, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (160, 24, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (161, 31, DATE '2026-09-01');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (112, 19, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (115, 26, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (116, 33, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (118, 40, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (162, 19, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (165, 26, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (166, 33, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (168, 40, DATE '2026-09-02');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (120, 28, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (121, 35, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (122, 2, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (123, 9, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (170, 28, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (171, 35, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (172, 2, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (173, 9, DATE '2026-09-03');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (124, 37, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (125, 4, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (126, 11, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (128, 18, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (174, 37, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (175, 4, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (176, 11, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (178, 18, DATE '2026-09-04');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (129, 6, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (130, 13, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (131, 20, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (132, 27, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (179, 6, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (180, 13, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (181, 20, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (182, 27, DATE '2026-09-05');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (133, 15, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (134, 22, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (136, 29, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (137, 36, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (183, 15, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (184, 22, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (186, 29, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (187, 36, DATE '2026-09-06');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (138, 24, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (139, 31, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (140, 38, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (142, 5, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (188, 24, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (189, 31, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (190, 38, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (192, 5, DATE '2026-09-07');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (144, 33, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (145, 40, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (147, 7, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (148, 14, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (194, 33, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (195, 40, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (197, 7, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (198, 14, DATE '2026-09-08');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (101, 9, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (102, 16, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (103, 3, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (150, 2, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (151, 9, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (152, 16, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (153, 3, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (200, 2, DATE '2026-09-09');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (104, 11, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (107, 18, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (108, 5, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (110, 12, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (154, 11, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (157, 18, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (158, 5, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (160, 12, DATE '2026-09-10');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (111, 20, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (112, 7, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (115, 14, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (116, 21, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (161, 20, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (162, 7, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (165, 14, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (166, 21, DATE '2026-09-11');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (118, 9, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (120, 16, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (121, 23, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (122, 30, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (168, 9, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (170, 16, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (171, 23, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (172, 30, DATE '2026-09-12');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (123, 18, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (124, 25, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (125, 32, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (126, 39, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (173, 18, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (174, 25, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (175, 32, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (176, 39, DATE '2026-09-13');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (128, 27, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (129, 34, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (130, 1, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (131, 8, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (178, 27, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (179, 34, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (180, 1, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (181, 8, DATE '2026-09-14');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (132, 36, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (133, 3, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (134, 10, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (136, 17, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (182, 36, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (183, 3, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (184, 10, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (186, 17, DATE '2026-09-15');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (137, 5, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (138, 12, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (139, 19, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (140, 26, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (187, 5, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (188, 12, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (189, 19, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (190, 26, DATE '2026-09-16');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (142, 14, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (144, 21, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (145, 28, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (147, 35, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (192, 14, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (194, 21, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (195, 28, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (197, 35, DATE '2026-09-17');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (101, 37, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (102, 4, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (148, 23, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (150, 30, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (151, 37, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (152, 4, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (198, 23, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (200, 30, DATE '2026-09-18');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (103, 32, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (104, 39, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (107, 6, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (108, 13, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (153, 32, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (154, 39, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (157, 6, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (158, 13, DATE '2026-09-19');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (110, 1, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (111, 8, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (112, 15, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (115, 2, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (160, 1, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (161, 8, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (162, 15, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (165, 2, DATE '2026-09-20');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (116, 10, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (118, 17, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (120, 4, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (121, 11, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (166, 10, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (168, 17, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (170, 4, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (171, 11, DATE '2026-09-21');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (122, 19, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (123, 6, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (124, 13, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (125, 20, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (172, 19, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (173, 6, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (174, 13, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (175, 20, DATE '2026-09-22');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (126, 8, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (128, 15, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (129, 22, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (130, 29, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (176, 8, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (178, 15, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (179, 22, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (180, 29, DATE '2026-09-23');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (131, 17, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (132, 24, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (133, 31, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (134, 38, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (181, 17, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (182, 24, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (183, 31, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (184, 38, DATE '2026-09-24');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (136, 26, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (137, 33, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (138, 40, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (139, 7, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (186, 26, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (187, 33, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (188, 40, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (189, 7, DATE '2026-09-25');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (140, 35, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (142, 2, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (144, 9, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (145, 16, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (190, 35, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (192, 2, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (194, 9, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (195, 16, DATE '2026-09-26');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (101, 25, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (147, 4, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (148, 11, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (150, 18, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (151, 25, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (197, 4, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (198, 11, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (200, 18, DATE '2026-09-27');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (102, 13, DATE '2026-09-28');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (103, 20, DATE '2026-09-28');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (104, 27, DATE '2026-09-28');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (107, 34, DATE '2026-09-28');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (152, 13, DATE '2026-09-28');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (153, 20, DATE '2026-09-28');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (154, 27, DATE '2026-09-28');
INSERT INTO TRABAJA (idrecolector, idZona, fecha) VALUES (157, 34, DATE '2026-09-28');

-- RECOLECTA (recolector N:M contenedor de una ruta atendida)  (224 filas)
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (107, 50, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (108, 17, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (110, 64, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (111, 96, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (157, 75, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (158, 57, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (160, 89, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (161, 96, DATE '2026-09-01');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (112, 84, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (115, 91, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (116, 33, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (118, 40, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (162, 19, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (165, 91, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (166, 33, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (168, 40, DATE '2026-09-02');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (120, 28, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (121, 100, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (122, 42, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (123, 9, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (170, 28, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (171, 100, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (172, 67, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (173, 49, DATE '2026-09-03');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (124, 37, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (125, 44, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (126, 11, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (128, 58, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (174, 37, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (175, 69, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (176, 51, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (178, 83, DATE '2026-09-04');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (129, 6, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (130, 78, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (131, 60, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (132, 27, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (179, 46, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (180, 13, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (181, 85, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (182, 27, DATE '2026-09-05');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (133, 80, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (134, 62, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (136, 29, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (137, 36, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (183, 15, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (184, 87, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (186, 29, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (187, 36, DATE '2026-09-06');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (138, 24, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (139, 96, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (140, 38, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (142, 70, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (188, 64, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (189, 96, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (190, 38, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (192, 5, DATE '2026-09-07');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (144, 33, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (145, 40, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (147, 7, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (148, 79, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (194, 33, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (195, 40, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (197, 47, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (198, 14, DATE '2026-09-08');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (101, 49, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (102, 16, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (103, 68, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (150, 2, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (151, 74, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (152, 56, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (153, 3, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (200, 42, DATE '2026-09-09');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (104, 76, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (107, 83, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (108, 45, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (110, 77, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (154, 11, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (157, 18, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (158, 70, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (160, 12, DATE '2026-09-10');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (111, 60, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (112, 7, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (115, 14, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (116, 86, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (161, 85, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (162, 47, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (165, 54, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (166, 21, DATE '2026-09-11');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (118, 9, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (120, 56, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (121, 23, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (122, 95, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (168, 49, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (170, 81, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (171, 63, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (172, 95, DATE '2026-09-12');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (123, 58, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (124, 25, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (125, 32, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (126, 39, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (173, 83, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (174, 65, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (175, 32, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (176, 39, DATE '2026-09-13');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (128, 92, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (129, 34, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (130, 1, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (131, 73, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (178, 92, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (179, 34, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (180, 41, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (181, 8, DATE '2026-09-14');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (132, 36, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (133, 3, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (134, 75, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (136, 17, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (182, 36, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (183, 43, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (184, 10, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (186, 57, DATE '2026-09-15');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (137, 70, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (138, 52, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (139, 19, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (140, 91, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (187, 5, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (188, 77, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (189, 59, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (190, 91, DATE '2026-09-16');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (142, 14, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (144, 61, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (145, 28, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (147, 35, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (192, 54, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (194, 86, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (195, 28, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (197, 35, DATE '2026-09-17');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (101, 37, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (102, 44, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (148, 23, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (150, 95, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (151, 37, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (152, 69, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (198, 63, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (200, 95, DATE '2026-09-18');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (103, 32, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (104, 39, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (107, 71, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (108, 53, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (153, 32, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (154, 39, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (157, 6, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (158, 78, DATE '2026-09-19');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (110, 1, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (111, 73, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (112, 55, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (115, 42, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (160, 41, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (161, 8, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (162, 80, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (165, 67, DATE '2026-09-20');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (116, 10, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (118, 57, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (120, 69, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (121, 51, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (166, 50, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (168, 82, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (170, 4, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (171, 76, DATE '2026-09-21');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (122, 19, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (123, 71, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (124, 53, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (125, 20, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (172, 59, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (173, 6, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (174, 78, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (175, 60, DATE '2026-09-22');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (126, 73, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (128, 15, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (129, 87, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (130, 29, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (176, 8, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (178, 55, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (179, 22, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (180, 29, DATE '2026-09-23');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (131, 17, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (132, 89, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (133, 96, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (134, 38, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (181, 57, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (182, 24, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (183, 96, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (184, 38, DATE '2026-09-24');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (136, 26, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (137, 98, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (138, 40, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (139, 47, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (186, 26, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (187, 98, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (188, 40, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (189, 72, DATE '2026-09-25');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (140, 35, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (142, 42, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (144, 74, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (145, 56, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (190, 35, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (192, 67, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (194, 9, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (195, 81, DATE '2026-09-26');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (101, 25, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (147, 69, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (148, 51, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (150, 83, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (151, 65, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (197, 4, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (198, 76, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (200, 18, DATE '2026-09-27');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (102, 78, DATE '2026-09-28');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (103, 60, DATE '2026-09-28');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (104, 27, DATE '2026-09-28');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (107, 99, DATE '2026-09-28');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (152, 13, DATE '2026-09-28');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (153, 85, DATE '2026-09-28');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (154, 27, DATE '2026-09-28');
INSERT INTO RECOLECTA (idrecolector, idContenedor, fecha) VALUES (157, 99, DATE '2026-09-28');


-- ====================================================================
-- AMPLIACION DE DATOS DE PRUEBA Y CORRECCION DE CARDINALIDADES
-- Los pesos, capacidades, fechas de compra y condiciones son SIMULADOS.
-- No representan mediciones fisicas ni datos historicos reales.
-- ====================================================================

-- Backfill de las columnas NOT NULL nuevas cuyos INSERT historicos
-- no suministraban valores. Se conservan los 200 empleados y otros
-- registros de origen, salvo la adicion de atributos calculados.
UPDATE BOTADERO
SET extension_hectareas = CAST(SUBSTRING_INDEX(extencion_terreno, ' ', 1) AS DECIMAL(10,2)),
    capacidad_maxima_kg = CAST(SUBSTRING_INDEX(extencion_terreno, ' ', 1) AS DECIMAL(15,2)) * 500000,
    capacidad_utilizada = 0,
    estado_operativo = 'Disponible';

UPDATE PERSONA
SET fecha_contratacion = GREATEST('2020-01-01', DATE_ADD(fecha_nacimiento, INTERVAL 19 YEAR)),
    estado_laboral = 'Activo';

UPDATE MATERIAL_TRABAJO
SET stock_minimo = 5,
    tipo_uso = CASE WHEN LOWER(nombre) REGEXP 'bolsas|nitrilo|desinfectante|mascarilla|cinta reflectiva|calcetines'
        THEN 'Consumible' ELSE 'Reutilizable' END;

UPDATE CONTENEDOR
SET capacidad_litros = CAST(SUBSTRING_INDEX(capacidad, ' ', 1) AS DECIMAL(12,2)) *
    CASE WHEN capacidad LIKE '%m3' THEN 1000 ELSE 1 END,
    -- Equivalencia teorica SIMULADA 0.20 kg/L (no se deduce del volumen)
    capacidad_kg = CAST(SUBSTRING_INDEX(capacidad, ' ', 1) AS DECIMAL(12,2)) *
    CASE WHEN capacidad LIKE '%m3' THEN 1000 ELSE 1 END * 0.20,
    estado_operativo = 'Disponible';

UPDATE TRANSPORTE
SET capacidad_kg = CAST(SUBSTRING_INDEX(capacidad, ' ', 1) AS DECIMAL(12,2)) * 1000,
    carga_actual_kg = 0;

UPDATE RUTA
SET distancia_km = CAST(SUBSTRING_INDEX(distancia_recorrida, ' ', 1) AS DECIMAL(12,2)),
    estado_operativo = 'Activa';

UPDATE DISPONE AS d
JOIN MATERIAL_TRABAJO AS m ON m.idMaterial = d.idMaterial
SET d.precio_unitario_asignacion = m.precio;

-- 60 zonas originalmente carecian de vias/rutas/contenedores en los datos.
-- Se crean dos vias/rutas/contenedores por cada zona 41..100,
-- asegurando ejemplos de la relacion 1:N y de la relacion ternaria.

INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (101, 'Calle de prueba 1 en zona 41', 'Calle', 41);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (101, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 101);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (101, '14.7 km', '07:00 - 13:00', 41, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (101, 101, 101);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (102, 'Avenida de prueba 2 en zona 41', 'Avenida', 41);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (102, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 102);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (102, '15.4 km', '14:00 - 20:00', 41, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (102, 102, 102);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (103, 'Calle de prueba 1 en zona 42', 'Calle', 42);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (103, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 103);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (103, '15.4 km', '07:00 - 13:00', 42, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (103, 103, 103);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (104, 'Avenida de prueba 2 en zona 42', 'Avenida', 42);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (104, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 104);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (104, '16.1 km', '14:00 - 20:00', 42, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (104, 104, 104);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (105, 'Calle de prueba 1 en zona 43', 'Calle', 43);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (105, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 105);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (105, '16.1 km', '07:00 - 13:00', 43, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (105, 105, 105);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (106, 'Avenida de prueba 2 en zona 43', 'Avenida', 43);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (106, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 106);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (106, '16.8 km', '14:00 - 20:00', 43, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (106, 106, 106);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (107, 'Calle de prueba 1 en zona 44', 'Calle', 44);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (107, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 107);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (107, '16.8 km', '07:00 - 13:00', 44, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (107, 107, 107);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (108, 'Avenida de prueba 2 en zona 44', 'Avenida', 44);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (108, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 108);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (108, '7.0 km', '14:00 - 20:00', 44, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (108, 108, 108);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (109, 'Calle de prueba 1 en zona 45', 'Calle', 45);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (109, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 109);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (109, '7.0 km', '07:00 - 13:00', 45, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (109, 109, 109);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (110, 'Avenida de prueba 2 en zona 45', 'Avenida', 45);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (110, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 110);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (110, '7.7 km', '14:00 - 20:00', 45, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (110, 110, 110);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (111, 'Calle de prueba 1 en zona 46', 'Calle', 46);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (111, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 111);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (111, '7.7 km', '07:00 - 13:00', 46, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (111, 111, 111);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (112, 'Avenida de prueba 2 en zona 46', 'Avenida', 46);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (112, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 112);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (112, '8.4 km', '14:00 - 20:00', 46, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (112, 112, 112);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (113, 'Calle de prueba 1 en zona 47', 'Calle', 47);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (113, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 113);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (113, '8.4 km', '07:00 - 13:00', 47, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (113, 113, 113);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (114, 'Avenida de prueba 2 en zona 47', 'Avenida', 47);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (114, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 114);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (114, '9.1 km', '14:00 - 20:00', 47, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (114, 114, 114);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (115, 'Calle de prueba 1 en zona 48', 'Calle', 48);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (115, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 115);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (115, '9.1 km', '07:00 - 13:00', 48, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (115, 115, 115);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (116, 'Avenida de prueba 2 en zona 48', 'Avenida', 48);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (116, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 116);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (116, '9.8 km', '14:00 - 20:00', 48, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (116, 116, 116);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (117, 'Calle de prueba 1 en zona 49', 'Calle', 49);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (117, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 117);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (117, '9.8 km', '07:00 - 13:00', 49, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (117, 117, 117);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (118, 'Avenida de prueba 2 en zona 49', 'Avenida', 49);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (118, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 118);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (118, '10.5 km', '14:00 - 20:00', 49, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (118, 118, 118);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (119, 'Calle de prueba 1 en zona 50', 'Calle', 50);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (119, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 119);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (119, '10.5 km', '07:00 - 13:00', 50, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (119, 119, 119);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (120, 'Avenida de prueba 2 en zona 50', 'Avenida', 50);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (120, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 120);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (120, '11.2 km', '14:00 - 20:00', 50, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (120, 120, 120);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (121, 'Calle de prueba 1 en zona 51', 'Calle', 51);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (121, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 121);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (121, '11.2 km', '07:00 - 13:00', 51, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (121, 121, 121);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (122, 'Avenida de prueba 2 en zona 51', 'Avenida', 51);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (122, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 122);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (122, '11.9 km', '14:00 - 20:00', 51, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (122, 122, 122);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (123, 'Calle de prueba 1 en zona 52', 'Calle', 52);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (123, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 123);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (123, '11.9 km', '07:00 - 13:00', 52, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (123, 123, 123);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (124, 'Avenida de prueba 2 en zona 52', 'Avenida', 52);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (124, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 124);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (124, '12.6 km', '14:00 - 20:00', 52, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (124, 124, 124);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (125, 'Calle de prueba 1 en zona 53', 'Calle', 53);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (125, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 125);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (125, '12.6 km', '07:00 - 13:00', 53, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (125, 125, 125);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (126, 'Avenida de prueba 2 en zona 53', 'Avenida', 53);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (126, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 126);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (126, '13.3 km', '14:00 - 20:00', 53, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (126, 126, 126);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (127, 'Calle de prueba 1 en zona 54', 'Calle', 54);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (127, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 127);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (127, '13.3 km', '07:00 - 13:00', 54, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (127, 127, 127);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (128, 'Avenida de prueba 2 en zona 54', 'Avenida', 54);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (128, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 128);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (128, '14.0 km', '14:00 - 20:00', 54, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (128, 128, 128);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (129, 'Calle de prueba 1 en zona 55', 'Calle', 55);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (129, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 129);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (129, '14.0 km', '07:00 - 13:00', 55, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (129, 129, 129);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (130, 'Avenida de prueba 2 en zona 55', 'Avenida', 55);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (130, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 130);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (130, '14.7 km', '14:00 - 20:00', 55, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (130, 130, 130);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (131, 'Calle de prueba 1 en zona 56', 'Calle', 56);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (131, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 131);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (131, '14.7 km', '07:00 - 13:00', 56, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (131, 131, 131);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (132, 'Avenida de prueba 2 en zona 56', 'Avenida', 56);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (132, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 132);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (132, '15.4 km', '14:00 - 20:00', 56, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (132, 132, 132);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (133, 'Calle de prueba 1 en zona 57', 'Calle', 57);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (133, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 133);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (133, '15.4 km', '07:00 - 13:00', 57, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (133, 133, 133);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (134, 'Avenida de prueba 2 en zona 57', 'Avenida', 57);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (134, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 134);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (134, '16.1 km', '14:00 - 20:00', 57, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (134, 134, 134);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (135, 'Calle de prueba 1 en zona 58', 'Calle', 58);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (135, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 135);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (135, '16.1 km', '07:00 - 13:00', 58, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (135, 135, 135);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (136, 'Avenida de prueba 2 en zona 58', 'Avenida', 58);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (136, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 136);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (136, '16.8 km', '14:00 - 20:00', 58, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (136, 136, 136);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (137, 'Calle de prueba 1 en zona 59', 'Calle', 59);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (137, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 137);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (137, '16.8 km', '07:00 - 13:00', 59, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (137, 137, 137);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (138, 'Avenida de prueba 2 en zona 59', 'Avenida', 59);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (138, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 138);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (138, '7.0 km', '14:00 - 20:00', 59, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (138, 138, 138);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (139, 'Calle de prueba 1 en zona 60', 'Calle', 60);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (139, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 139);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (139, '7.0 km', '07:00 - 13:00', 60, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (139, 139, 139);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (140, 'Avenida de prueba 2 en zona 60', 'Avenida', 60);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (140, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 140);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (140, '7.7 km', '14:00 - 20:00', 60, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (140, 140, 140);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (141, 'Calle de prueba 1 en zona 61', 'Calle', 61);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (141, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 141);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (141, '7.7 km', '07:00 - 13:00', 61, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (141, 141, 141);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (142, 'Avenida de prueba 2 en zona 61', 'Avenida', 61);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (142, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 142);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (142, '8.4 km', '14:00 - 20:00', 61, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (142, 142, 142);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (143, 'Calle de prueba 1 en zona 62', 'Calle', 62);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (143, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 143);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (143, '8.4 km', '07:00 - 13:00', 62, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (143, 143, 143);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (144, 'Avenida de prueba 2 en zona 62', 'Avenida', 62);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (144, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 144);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (144, '9.1 km', '14:00 - 20:00', 62, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (144, 144, 144);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (145, 'Calle de prueba 1 en zona 63', 'Calle', 63);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (145, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 145);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (145, '9.1 km', '07:00 - 13:00', 63, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (145, 145, 145);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (146, 'Avenida de prueba 2 en zona 63', 'Avenida', 63);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (146, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 146);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (146, '9.8 km', '14:00 - 20:00', 63, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (146, 146, 146);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (147, 'Calle de prueba 1 en zona 64', 'Calle', 64);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (147, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 147);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (147, '9.8 km', '07:00 - 13:00', 64, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (147, 147, 147);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (148, 'Avenida de prueba 2 en zona 64', 'Avenida', 64);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (148, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 148);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (148, '10.5 km', '14:00 - 20:00', 64, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (148, 148, 148);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (149, 'Calle de prueba 1 en zona 65', 'Calle', 65);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (149, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 149);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (149, '10.5 km', '07:00 - 13:00', 65, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (149, 149, 149);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (150, 'Avenida de prueba 2 en zona 65', 'Avenida', 65);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (150, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 150);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (150, '11.2 km', '14:00 - 20:00', 65, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (150, 150, 150);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (151, 'Calle de prueba 1 en zona 66', 'Calle', 66);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (151, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 151);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (151, '11.2 km', '07:00 - 13:00', 66, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (151, 151, 151);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (152, 'Avenida de prueba 2 en zona 66', 'Avenida', 66);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (152, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 152);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (152, '11.9 km', '14:00 - 20:00', 66, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (152, 152, 152);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (153, 'Calle de prueba 1 en zona 67', 'Calle', 67);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (153, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 153);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (153, '11.9 km', '07:00 - 13:00', 67, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (153, 153, 153);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (154, 'Avenida de prueba 2 en zona 67', 'Avenida', 67);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (154, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 154);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (154, '12.6 km', '14:00 - 20:00', 67, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (154, 154, 154);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (155, 'Calle de prueba 1 en zona 68', 'Calle', 68);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (155, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 155);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (155, '12.6 km', '07:00 - 13:00', 68, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (155, 155, 155);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (156, 'Avenida de prueba 2 en zona 68', 'Avenida', 68);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (156, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 156);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (156, '13.3 km', '14:00 - 20:00', 68, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (156, 156, 156);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (157, 'Calle de prueba 1 en zona 69', 'Calle', 69);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (157, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 157);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (157, '13.3 km', '07:00 - 13:00', 69, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (157, 157, 157);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (158, 'Avenida de prueba 2 en zona 69', 'Avenida', 69);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (158, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 158);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (158, '14.0 km', '14:00 - 20:00', 69, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (158, 158, 158);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (159, 'Calle de prueba 1 en zona 70', 'Calle', 70);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (159, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 159);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (159, '14.0 km', '07:00 - 13:00', 70, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (159, 159, 159);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (160, 'Avenida de prueba 2 en zona 70', 'Avenida', 70);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (160, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 160);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (160, '14.7 km', '14:00 - 20:00', 70, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (160, 160, 160);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (161, 'Calle de prueba 1 en zona 71', 'Calle', 71);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (161, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 161);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (161, '14.7 km', '07:00 - 13:00', 71, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (161, 161, 161);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (162, 'Avenida de prueba 2 en zona 71', 'Avenida', 71);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (162, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 162);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (162, '15.4 km', '14:00 - 20:00', 71, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (162, 162, 162);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (163, 'Calle de prueba 1 en zona 72', 'Calle', 72);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (163, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 163);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (163, '15.4 km', '07:00 - 13:00', 72, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (163, 163, 163);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (164, 'Avenida de prueba 2 en zona 72', 'Avenida', 72);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (164, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 164);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (164, '16.1 km', '14:00 - 20:00', 72, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (164, 164, 164);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (165, 'Calle de prueba 1 en zona 73', 'Calle', 73);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (165, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 165);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (165, '16.1 km', '07:00 - 13:00', 73, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (165, 165, 165);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (166, 'Avenida de prueba 2 en zona 73', 'Avenida', 73);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (166, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 166);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (166, '16.8 km', '14:00 - 20:00', 73, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (166, 166, 166);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (167, 'Calle de prueba 1 en zona 74', 'Calle', 74);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (167, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 167);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (167, '16.8 km', '07:00 - 13:00', 74, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (167, 167, 167);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (168, 'Avenida de prueba 2 en zona 74', 'Avenida', 74);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (168, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 168);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (168, '7.0 km', '14:00 - 20:00', 74, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (168, 168, 168);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (169, 'Calle de prueba 1 en zona 75', 'Calle', 75);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (169, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 169);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (169, '7.0 km', '07:00 - 13:00', 75, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (169, 169, 169);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (170, 'Avenida de prueba 2 en zona 75', 'Avenida', 75);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (170, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 170);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (170, '7.7 km', '14:00 - 20:00', 75, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (170, 170, 170);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (171, 'Calle de prueba 1 en zona 76', 'Calle', 76);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (171, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 171);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (171, '7.7 km', '07:00 - 13:00', 76, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (171, 171, 171);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (172, 'Avenida de prueba 2 en zona 76', 'Avenida', 76);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (172, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 172);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (172, '8.4 km', '14:00 - 20:00', 76, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (172, 172, 172);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (173, 'Calle de prueba 1 en zona 77', 'Calle', 77);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (173, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 173);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (173, '8.4 km', '07:00 - 13:00', 77, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (173, 173, 173);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (174, 'Avenida de prueba 2 en zona 77', 'Avenida', 77);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (174, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 174);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (174, '9.1 km', '14:00 - 20:00', 77, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (174, 174, 174);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (175, 'Calle de prueba 1 en zona 78', 'Calle', 78);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (175, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 175);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (175, '9.1 km', '07:00 - 13:00', 78, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (175, 175, 175);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (176, 'Avenida de prueba 2 en zona 78', 'Avenida', 78);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (176, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 176);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (176, '9.8 km', '14:00 - 20:00', 78, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (176, 176, 176);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (177, 'Calle de prueba 1 en zona 79', 'Calle', 79);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (177, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 177);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (177, '9.8 km', '07:00 - 13:00', 79, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (177, 177, 177);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (178, 'Avenida de prueba 2 en zona 79', 'Avenida', 79);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (178, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 178);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (178, '10.5 km', '14:00 - 20:00', 79, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (178, 178, 178);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (179, 'Calle de prueba 1 en zona 80', 'Calle', 80);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (179, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 179);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (179, '10.5 km', '07:00 - 13:00', 80, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (179, 179, 179);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (180, 'Avenida de prueba 2 en zona 80', 'Avenida', 80);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (180, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 180);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (180, '11.2 km', '14:00 - 20:00', 80, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (180, 180, 180);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (181, 'Calle de prueba 1 en zona 81', 'Calle', 81);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (181, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 181);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (181, '11.2 km', '07:00 - 13:00', 81, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (181, 181, 181);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (182, 'Avenida de prueba 2 en zona 81', 'Avenida', 81);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (182, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 182);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (182, '11.9 km', '14:00 - 20:00', 81, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (182, 182, 182);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (183, 'Calle de prueba 1 en zona 82', 'Calle', 82);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (183, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 183);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (183, '11.9 km', '07:00 - 13:00', 82, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (183, 183, 183);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (184, 'Avenida de prueba 2 en zona 82', 'Avenida', 82);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (184, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 184);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (184, '12.6 km', '14:00 - 20:00', 82, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (184, 184, 184);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (185, 'Calle de prueba 1 en zona 83', 'Calle', 83);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (185, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 185);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (185, '12.6 km', '07:00 - 13:00', 83, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (185, 185, 185);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (186, 'Avenida de prueba 2 en zona 83', 'Avenida', 83);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (186, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 186);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (186, '13.3 km', '14:00 - 20:00', 83, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (186, 186, 186);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (187, 'Calle de prueba 1 en zona 84', 'Calle', 84);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (187, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 187);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (187, '13.3 km', '07:00 - 13:00', 84, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (187, 187, 187);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (188, 'Avenida de prueba 2 en zona 84', 'Avenida', 84);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (188, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 188);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (188, '14.0 km', '14:00 - 20:00', 84, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (188, 188, 188);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (189, 'Calle de prueba 1 en zona 85', 'Calle', 85);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (189, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 189);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (189, '14.0 km', '07:00 - 13:00', 85, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (189, 189, 189);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (190, 'Avenida de prueba 2 en zona 85', 'Avenida', 85);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (190, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 190);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (190, '14.7 km', '14:00 - 20:00', 85, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (190, 190, 190);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (191, 'Calle de prueba 1 en zona 86', 'Calle', 86);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (191, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 191);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (191, '14.7 km', '07:00 - 13:00', 86, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (191, 191, 191);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (192, 'Avenida de prueba 2 en zona 86', 'Avenida', 86);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (192, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 192);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (192, '15.4 km', '14:00 - 20:00', 86, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (192, 192, 192);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (193, 'Calle de prueba 1 en zona 87', 'Calle', 87);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (193, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 193);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (193, '15.4 km', '07:00 - 13:00', 87, 15.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (193, 193, 193);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (194, 'Avenida de prueba 2 en zona 87', 'Avenida', 87);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (194, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 194);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (194, '16.1 km', '14:00 - 20:00', 87, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (194, 194, 194);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (195, 'Calle de prueba 1 en zona 88', 'Calle', 88);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (195, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 195);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (195, '16.1 km', '07:00 - 13:00', 88, 16.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (195, 195, 195);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (196, 'Avenida de prueba 2 en zona 88', 'Avenida', 88);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (196, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 196);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (196, '16.8 km', '14:00 - 20:00', 88, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (196, 196, 196);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (197, 'Calle de prueba 1 en zona 89', 'Calle', 89);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (197, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 197);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (197, '16.8 km', '07:00 - 13:00', 89, 16.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (197, 197, 197);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (198, 'Avenida de prueba 2 en zona 89', 'Avenida', 89);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (198, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 198);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (198, '7.0 km', '14:00 - 20:00', 89, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (198, 198, 198);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (199, 'Calle de prueba 1 en zona 90', 'Calle', 90);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (199, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 199);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (199, '7.0 km', '07:00 - 13:00', 90, 7.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (199, 199, 199);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (200, 'Avenida de prueba 2 en zona 90', 'Avenida', 90);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (200, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 200);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (200, '7.7 km', '14:00 - 20:00', 90, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (200, 200, 200);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (201, 'Calle de prueba 1 en zona 91', 'Calle', 91);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (201, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 201);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (201, '7.7 km', '07:00 - 13:00', 91, 7.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (201, 201, 201);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (202, 'Avenida de prueba 2 en zona 91', 'Avenida', 91);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (202, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 202);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (202, '8.4 km', '14:00 - 20:00', 91, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (202, 202, 202);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (203, 'Calle de prueba 1 en zona 92', 'Calle', 92);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (203, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 203);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (203, '8.4 km', '07:00 - 13:00', 92, 8.40, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (203, 203, 203);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (204, 'Avenida de prueba 2 en zona 92', 'Avenida', 92);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (204, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 204);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (204, '9.1 km', '14:00 - 20:00', 92, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (204, 204, 204);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (205, 'Calle de prueba 1 en zona 93', 'Calle', 93);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (205, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 205);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (205, '9.1 km', '07:00 - 13:00', 93, 9.10, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (205, 205, 205);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (206, 'Avenida de prueba 2 en zona 93', 'Avenida', 93);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (206, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 206);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (206, '9.8 km', '14:00 - 20:00', 93, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (206, 206, 206);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (207, 'Calle de prueba 1 en zona 94', 'Calle', 94);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (207, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 207);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (207, '9.8 km', '07:00 - 13:00', 94, 9.80, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (207, 207, 207);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (208, 'Avenida de prueba 2 en zona 94', 'Avenida', 94);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (208, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 208);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (208, '10.5 km', '14:00 - 20:00', 94, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (208, 208, 208);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (209, 'Calle de prueba 1 en zona 95', 'Calle', 95);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (209, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 209);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (209, '10.5 km', '07:00 - 13:00', 95, 10.50, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (209, 209, 209);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (210, 'Avenida de prueba 2 en zona 95', 'Avenida', 95);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (210, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 210);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (210, '11.2 km', '14:00 - 20:00', 95, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (210, 210, 210);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (211, 'Calle de prueba 1 en zona 96', 'Calle', 96);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (211, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 211);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (211, '11.2 km', '07:00 - 13:00', 96, 11.20, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (211, 211, 211);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (212, 'Avenida de prueba 2 en zona 96', 'Avenida', 96);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (212, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 212);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (212, '11.9 km', '14:00 - 20:00', 96, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (212, 212, 212);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (213, 'Calle de prueba 1 en zona 97', 'Calle', 97);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (213, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 213);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (213, '11.9 km', '07:00 - 13:00', 97, 11.90, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (213, 213, 213);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (214, 'Avenida de prueba 2 en zona 97', 'Avenida', 97);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (214, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 214);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (214, '12.6 km', '14:00 - 20:00', 97, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (214, 214, 214);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (215, 'Calle de prueba 1 en zona 98', 'Calle', 98);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (215, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 215);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (215, '12.6 km', '07:00 - 13:00', 98, 12.60, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (215, 215, 215);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (216, 'Avenida de prueba 2 en zona 98', 'Avenida', 98);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (216, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 216);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (216, '13.3 km', '14:00 - 20:00', 98, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (216, 216, 216);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (217, 'Calle de prueba 1 en zona 99', 'Calle', 99);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (217, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 217);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (217, '13.3 km', '07:00 - 13:00', 99, 13.30, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (217, 217, 217);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (218, 'Avenida de prueba 2 en zona 99', 'Avenida', 99);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (218, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 218);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (218, '14.0 km', '14:00 - 20:00', 99, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (218, 218, 218);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (219, 'Calle de prueba 1 en zona 100', 'Calle', 100);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (219, 'Mixto (negro)', '660 L', 660, 132.00, 'Disponible', 'Mediano', 219);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (219, '14.0 km', '07:00 - 13:00', 100, 14.00, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (219, 219, 219);
INSERT INTO VIA (idVia, descripcion, calle_avenida, idZona) VALUES (220, 'Avenida de prueba 2 en zona 100', 'Avenida', 100);
INSERT INTO CONTENEDOR (idContenedor, tipo, capacidad, capacidad_litros, capacidad_kg, estado_operativo, tamanio, idVia) VALUES (220, 'Mixto (negro)', '1100 L', 1100, 220.00, 'Disponible', 'Mediano', 220);
INSERT INTO RUTA (idRuta, distancia_recorrida, Horario, idZona, distancia_km, estado_operativo) VALUES (220, '14.7 km', '14:00 - 20:00', 100, 14.70, 'Activa');
INSERT INTO INTEGRA (idRuta, idVia, idContenedor) VALUES (220, 220, 220);

-- Sincronizar el atributo derivado cantidad_calles con las vias
-- que efectivamente existen (evita cantidades declaradas inconsistentes).
UPDATE ZONA AS z
SET z.cantidad_calles = (
    SELECT COUNT(*) FROM VIA AS v WHERE v.idZona = z.idZona
);

-- Backfill de RECOLECTA con el transporte y la ruta existentes
-- en PASA_POR durante la misma fecha. Todas las 224 recolecciones
-- originales coinciden con TRABAJA, INTEGRA y la zona de la ruta.
-- Hora y kg se completan solo como DATOS DE PRUEBA sinteticos.
UPDATE RECOLECTA AS rc
JOIN RECOLECTOR AS r ON r.idrecolector = rc.idrecolector
JOIN PASA_POR AS pp
  ON pp.idTransporte = r.idTransporte AND pp.fecha = rc.fecha
JOIN RUTA AS ru ON ru.idRuta = pp.idRuta
JOIN CONTENEDOR AS c ON c.idContenedor = rc.idContenedor
JOIN VIA AS v ON v.idVia = c.idVia AND v.idZona = ru.idZona
JOIN INTEGRA AS i ON i.idRuta = ru.idRuta
  AND i.idContenedor = rc.idContenedor AND i.idVia = v.idVia
SET rc.idTransporte = pp.idTransporte,
    rc.idRuta = pp.idRuta,
    rc.hora_recoleccion = TIME(DATE_ADD(
       CONCAT(rc.fecha, ' ', SUBSTRING_INDEX(ru.Horario, ' - ', 1), ':00'),
       INTERVAL MOD(rc.idContenedor * 7, 180) MINUTE)),
    rc.cantidad_kg = ROUND(c.capacidad_kg *
       (0.26 + MOD(rc.idrecolector + rc.idContenedor, 16) / 100), 2);

-- En la base de pruebas las 224 filas son enlazables; ahora
-- el transporte y ruta se convierten en obligatorios.
ALTER TABLE RECOLECTA
    MODIFY COLUMN idTransporte INT NOT NULL,
    MODIFY COLUMN idRuta INT NOT NULL,
    MODIFY COLUMN cantidad_kg DECIMAL(12,2) NOT NULL;

-- Restringir 1 ruta por transporte y fecha, 1 zona por recolector y fecha
-- Esta es una REGLA OPERATIVA adoptada, no una propiedad universal del 1:N.
ALTER TABLE PASA_POR ADD CONSTRAINT uq_pasa_transporte_fecha UNIQUE (idTransporte, fecha);
ALTER TABLE TRABAJA ADD CONSTRAINT uq_trabaja_recolector_fecha UNIQUE (idrecolector, fecha);

-- Indices para FK y reportes.
CREATE INDEX idx_recolecta_fecha_ruta ON RECOLECTA (fecha, idRuta);
CREATE INDEX idx_descarga_transporte_fecha ON DESCARGA_BOTADERO (idTransporte, fecha);
CREATE INDEX idx_historial_recolector_inicio ON HISTORIAL_ASIGNACION (idrecolector, fecha_inicio);


-- COMPRA_MATERIAL: 100 compras iniciales (una por material).
-- Compras anteriores a las entregas de 2026 y stock suficiente.
-- No representan facturas reales: simulacion academica.

INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (1, 'Proveedor de prueba 2', '2025-12-15', 31, 26.72, 828.32);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (2, 'Proveedor de prueba 3', '2025-12-15', 22, 30.26, 665.72);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (3, 'Proveedor de prueba 4', '2025-12-15', 32, 79.19, 2534.08);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (4, 'Proveedor de prueba 5', '2025-12-15', 24, 98.50, 2364.00);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (5, 'Proveedor de prueba 6', '2025-12-15', 28, 9.12, 255.36);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (6, 'Proveedor de prueba 7', '2025-12-15', 35, 38.99, 1364.65);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (7, 'Proveedor de prueba 8', '2025-12-15', 32, 77.70, 2486.40);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (8, 'Proveedor de prueba 1', '2025-12-15', 44, 301.44, 13263.36);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (9, 'Proveedor de prueba 2', '2025-12-15', 25, 50.45, 1261.25);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (10, 'Proveedor de prueba 3', '2025-12-15', 28, 9.79, 274.12);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (11, 'Proveedor de prueba 4', '2025-12-15', 26, 43.30, 1125.80);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (12, 'Proveedor de prueba 5', '2025-12-15', 31, 8.56, 265.36);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (13, 'Proveedor de prueba 6', '2025-12-15', 24, 46.35, 1112.40);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (14, 'Proveedor de prueba 7', '2025-12-15', 33, 34.92, 1152.36);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (15, 'Proveedor de prueba 8', '2025-12-15', 39, 50.98, 1988.22);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (16, 'Proveedor de prueba 1', '2025-12-15', 27, 227.54, 6143.58);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (17, 'Proveedor de prueba 2', '2025-12-15', 28, 135.75, 3801.00);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (18, 'Proveedor de prueba 3', '2025-12-15', 27, 51.57, 1392.39);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (19, 'Proveedor de prueba 4', '2025-12-15', 31, 27.65, 857.15);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (20, 'Proveedor de prueba 5', '2025-12-15', 27, 172.22, 4649.94);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (21, 'Proveedor de prueba 6', '2025-12-15', 23, 56.96, 1310.08);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (22, 'Proveedor de prueba 7', '2025-12-15', 26, 89.44, 2325.44);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (23, 'Proveedor de prueba 8', '2025-12-15', 32, 74.47, 2383.04);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (24, 'Proveedor de prueba 1', '2025-12-15', 26, 134.01, 3484.26);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (25, 'Proveedor de prueba 2', '2025-12-15', 28, 42.34, 1185.52);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (26, 'Proveedor de prueba 3', '2025-12-15', 28, 320.38, 8970.64);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (27, 'Proveedor de prueba 4', '2025-12-15', 31, 45.40, 1407.40);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (28, 'Proveedor de prueba 5', '2025-12-15', 21, 10.86, 228.06);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (29, 'Proveedor de prueba 6', '2025-12-15', 22, 67.41, 1483.02);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (30, 'Proveedor de prueba 7', '2025-12-15', 30, 76.07, 2282.10);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (31, 'Proveedor de prueba 8', '2025-12-15', 24, 19.62, 470.88);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (32, 'Proveedor de prueba 1', '2025-12-15', 25, 23.87, 596.75);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (33, 'Proveedor de prueba 2', '2025-12-15', 35, 218.74, 7655.90);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (34, 'Proveedor de prueba 3', '2025-12-15', 27, 51.46, 1389.42);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (35, 'Proveedor de prueba 4', '2025-12-15', 36, 25.11, 903.96);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (36, 'Proveedor de prueba 5', '2025-12-15', 20, 18.51, 370.20);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (37, 'Proveedor de prueba 6', '2025-12-15', 21, 45.48, 955.08);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (38, 'Proveedor de prueba 7', '2025-12-15', 28, 153.52, 4298.56);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (39, 'Proveedor de prueba 8', '2025-12-15', 27, 102.07, 2755.89);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (40, 'Proveedor de prueba 1', '2025-12-15', 27, 35.89, 969.03);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (41, 'Proveedor de prueba 2', '2025-12-15', 29, 9.87, 286.23);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (42, 'Proveedor de prueba 3', '2025-12-15', 30, 42.54, 1276.20);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (43, 'Proveedor de prueba 4', '2025-12-15', 32, 9.44, 302.08);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (44, 'Proveedor de prueba 5', '2025-12-15', 38, 30.72, 1167.36);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (45, 'Proveedor de prueba 6', '2025-12-15', 33, 87.50, 2887.50);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (46, 'Proveedor de prueba 7', '2025-12-15', 27, 125.64, 3392.28);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (47, 'Proveedor de prueba 8', '2025-12-15', 41, 440.06, 18042.46);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (48, 'Proveedor de prueba 1', '2025-12-15', 25, 43.07, 1076.75);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (49, 'Proveedor de prueba 2', '2025-12-15', 33, 38.70, 1277.10);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (50, 'Proveedor de prueba 3', '2025-12-15', 43, 69.96, 3008.28);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (51, 'Proveedor de prueba 4', '2025-12-15', 26, 226.85, 5898.10);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (52, 'Proveedor de prueba 5', '2025-12-15', 41, 164.03, 6725.23);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (53, 'Proveedor de prueba 6', '2025-12-15', 43, 180.55, 7763.65);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (54, 'Proveedor de prueba 7', '2025-12-15', 28, 257.60, 7212.80);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (55, 'Proveedor de prueba 8', '2025-12-15', 21, 87.99, 1847.79);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (56, 'Proveedor de prueba 1', '2025-12-15', 28, 63.52, 1778.56);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (57, 'Proveedor de prueba 2', '2025-12-15', 40, 215.77, 8630.80);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (58, 'Proveedor de prueba 3', '2025-12-15', 35, 28.60, 1001.00);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (59, 'Proveedor de prueba 4', '2025-12-15', 25, 88.95, 2223.75);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (60, 'Proveedor de prueba 5', '2025-12-15', 30, 29.95, 898.50);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (61, 'Proveedor de prueba 6', '2025-12-15', 34, 95.54, 3248.36);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (62, 'Proveedor de prueba 7', '2025-12-15', 35, 113.88, 3985.80);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (63, 'Proveedor de prueba 8', '2025-12-15', 33, 48.94, 1615.02);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (64, 'Proveedor de prueba 1', '2025-12-15', 23, 311.50, 7164.50);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (65, 'Proveedor de prueba 2', '2025-12-15', 39, 19.69, 767.91);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (66, 'Proveedor de prueba 3', '2025-12-15', 23, 35.60, 818.80);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (67, 'Proveedor de prueba 4', '2025-12-15', 24, 112.12, 2690.88);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (68, 'Proveedor de prueba 5', '2025-12-15', 37, 26.94, 996.78);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (69, 'Proveedor de prueba 6', '2025-12-15', 26, 40.55, 1054.30);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (70, 'Proveedor de prueba 7', '2025-12-15', 35, 36.87, 1290.45);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (71, 'Proveedor de prueba 8', '2025-12-15', 28, 73.94, 2070.32);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (72, 'Proveedor de prueba 1', '2025-12-15', 20, 65.68, 1313.60);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (73, 'Proveedor de prueba 2', '2025-12-15', 22, 24.53, 539.66);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (74, 'Proveedor de prueba 3', '2025-12-15', 29, 76.60, 2221.40);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (75, 'Proveedor de prueba 4', '2025-12-15', 23, 70.48, 1621.04);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (76, 'Proveedor de prueba 5', '2025-12-15', 24, 31.03, 744.72);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (77, 'Proveedor de prueba 6', '2025-12-15', 28, 95.55, 2675.40);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (78, 'Proveedor de prueba 7', '2025-12-15', 43, 78.68, 3383.24);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (79, 'Proveedor de prueba 8', '2025-12-15', 29, 151.22, 4385.38);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (80, 'Proveedor de prueba 1', '2025-12-15', 28, 37.93, 1062.04);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (81, 'Proveedor de prueba 2', '2025-12-15', 20, 14.70, 294.00);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (82, 'Proveedor de prueba 3', '2025-12-15', 21, 20.76, 435.96);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (83, 'Proveedor de prueba 4', '2025-12-15', 29, 87.58, 2539.82);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (84, 'Proveedor de prueba 5', '2025-12-15', 29, 46.46, 1347.34);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (85, 'Proveedor de prueba 6', '2025-12-15', 24, 157.29, 3774.96);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (86, 'Proveedor de prueba 7', '2025-12-15', 25, 70.07, 1751.75);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (87, 'Proveedor de prueba 8', '2025-12-15', 26, 21.28, 553.28);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (88, 'Proveedor de prueba 1', '2025-12-15', 31, 24.23, 751.13);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (89, 'Proveedor de prueba 2', '2025-12-15', 28, 225.32, 6308.96);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (90, 'Proveedor de prueba 3', '2025-12-15', 29, 129.53, 3756.37);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (91, 'Proveedor de prueba 4', '2025-12-15', 21, 48.73, 1023.33);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (92, 'Proveedor de prueba 5', '2025-12-15', 29, 79.85, 2315.65);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (93, 'Proveedor de prueba 6', '2025-12-15', 25, 77.55, 1938.75);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (94, 'Proveedor de prueba 7', '2025-12-15', 28, 97.91, 2741.48);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (95, 'Proveedor de prueba 8', '2025-12-15', 35, 42.96, 1503.60);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (96, 'Proveedor de prueba 1', '2025-12-15', 38, 123.83, 4705.54);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (97, 'Proveedor de prueba 2', '2025-12-15', 27, 16.60, 448.20);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (98, 'Proveedor de prueba 3', '2025-12-15', 44, 33.10, 1456.40);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (99, 'Proveedor de prueba 4', '2025-12-15', 20, 55.00, 1100.00);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (100, 'Proveedor de prueba 5', '2025-12-15', 24, 64.51, 1548.24);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (1, 'Proveedor de prueba 2', '2026-07-15', 6, 27.79, 166.74);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (2, 'Proveedor de prueba 3', '2026-07-15', 7, 31.47, 220.29);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (3, 'Proveedor de prueba 4', '2026-07-15', 8, 82.36, 658.88);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (4, 'Proveedor de prueba 5', '2026-07-15', 5, 102.44, 512.20);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (5, 'Proveedor de prueba 1', '2026-07-15', 6, 9.48, 56.88);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (6, 'Proveedor de prueba 2', '2026-07-15', 7, 40.55, 283.85);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (7, 'Proveedor de prueba 3', '2026-07-15', 8, 80.81, 646.48);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (8, 'Proveedor de prueba 4', '2026-07-15', 5, 313.50, 1567.50);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (9, 'Proveedor de prueba 5', '2026-07-15', 6, 52.47, 314.82);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (10, 'Proveedor de prueba 1', '2026-07-15', 7, 10.18, 71.26);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (11, 'Proveedor de prueba 2', '2026-07-15', 8, 45.03, 360.24);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (12, 'Proveedor de prueba 3', '2026-07-15', 5, 8.90, 44.50);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (13, 'Proveedor de prueba 4', '2026-07-15', 6, 48.20, 289.20);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (14, 'Proveedor de prueba 5', '2026-07-15', 7, 36.32, 254.24);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (15, 'Proveedor de prueba 1', '2026-07-15', 8, 53.02, 424.16);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (16, 'Proveedor de prueba 2', '2026-07-15', 5, 236.64, 1183.20);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (17, 'Proveedor de prueba 3', '2026-07-15', 6, 141.18, 847.08);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (18, 'Proveedor de prueba 4', '2026-07-15', 7, 53.63, 375.41);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (19, 'Proveedor de prueba 5', '2026-07-15', 8, 28.76, 230.08);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (20, 'Proveedor de prueba 1', '2026-07-15', 5, 179.11, 895.55);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (21, 'Proveedor de prueba 2', '2026-07-15', 6, 59.24, 355.44);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (22, 'Proveedor de prueba 3', '2026-07-15', 7, 93.02, 651.14);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (23, 'Proveedor de prueba 4', '2026-07-15', 8, 77.45, 619.60);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (24, 'Proveedor de prueba 5', '2026-07-15', 5, 139.37, 696.85);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (25, 'Proveedor de prueba 1', '2026-07-15', 6, 44.03, 264.18);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (26, 'Proveedor de prueba 2', '2026-07-15', 7, 333.20, 2332.40);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (27, 'Proveedor de prueba 3', '2026-07-15', 8, 47.22, 377.76);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (28, 'Proveedor de prueba 4', '2026-07-15', 5, 11.29, 56.45);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (29, 'Proveedor de prueba 5', '2026-07-15', 6, 70.11, 420.66);
INSERT INTO COMPRA_MATERIAL (idMaterial, proveedor, fecha, cantidad, precio_unitario, total) VALUES (30, 'Proveedor de prueba 1', '2026-07-15', 7, 79.11, 553.77);

-- Stock actual = compras totales - entregas (DISPONE).
UPDATE MATERIAL_TRABAJO AS m
LEFT JOIN (SELECT idMaterial, SUM(cantidad) AS qty FROM COMPRA_MATERIAL GROUP BY idMaterial) AS cmp
  ON cmp.idMaterial = m.idMaterial
LEFT JOIN (SELECT idMaterial, SUM(cantidad) AS qty FROM DISPONE GROUP BY idMaterial) AS disp
  ON disp.idMaterial = m.idMaterial
SET m.stock_actual = GREATEST(0, COALESCE(cmp.qty,0) - COALESCE(disp.qty,0));

-- DEVOLUCION_MATERIAL: varias asignaciones historicas con retornos.
-- Se reutiliza la FK compuesta de DISPONE (1:N).

INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (11, 43, '2026-01-05', '2026-01-15', 2, 1, 'Danado parcial');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (3, 41, '2026-01-24', '2026-02-05', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (53, 68, '2026-01-25', '2026-02-08', 4, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (171, 92, '2026-01-30', '2026-02-15', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (20, 96, '2026-02-06', '2026-02-24', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (75, 68, '2026-02-10', '2026-03-02', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (36, 47, '2026-02-21', '2026-03-15', 5, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (156, 90, '2026-02-26', '2026-03-08', 4, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (94, 63, '2026-03-01', '2026-03-13', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (179, 84, '2026-03-09', '2026-03-23', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (53, 58, '2026-03-11', '2026-03-27', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (190, 53, '2026-03-13', '2026-03-31', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (140, 98, '2026-03-19', '2026-04-08', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (174, 74, '2026-04-07', '2026-04-29', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (117, 45, '2026-04-13', '2026-04-23', 5, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (42, 11, '2026-04-15', '2026-04-27', 2, 1, 'Danado parcial');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (113, 94, '2026-04-19', '2026-05-03', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (27, 22, '2026-04-25', '2026-05-11', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (28, 79, '2026-05-06', '2026-05-24', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (67, 58, '2026-05-11', '2026-05-31', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (144, 52, '2026-05-15', '2026-06-06', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (199, 27, '2026-05-20', '2026-05-30', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (66, 6, '2026-05-27', '2026-06-08', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (79, 25, '2026-05-28', '2026-06-11', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (180, 78, '2026-06-01', '2026-06-17', 4, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (83, 19, '2026-06-05', '2026-06-23', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (79, 15, '2026-06-08', '2026-06-28', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (22, 93, '2026-06-29', '2026-07-21', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (108, 95, '2026-07-09', '2026-07-19', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (133, 96, '2026-07-12', '2026-07-24', 4, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (42, 35, '2026-07-16', '2026-07-30', 4, 1, 'Danado parcial');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (198, 46, '2026-07-18', '2026-08-03', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (88, 10, '2026-07-21', '2026-08-08', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (83, 95, '2026-07-24', '2026-08-13', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (72, 45, '2026-07-28', '2026-08-19', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (95, 12, '2026-07-29', '2026-08-08', 4, 1, 'Danado parcial');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (150, 20, '2026-08-02', '2026-08-14', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (16, 61, '2026-08-05', '2026-08-19', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (196, 20, '2026-08-09', '2026-08-25', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (88, 78, '2026-08-12', '2026-08-30', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (119, 65, '2026-08-15', '2026-09-04', 5, 1, 'Danado parcial');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (167, 30, '2026-08-17', '2026-09-08', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (116, 19, '2026-08-20', '2026-08-30', 3, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (157, 18, '2026-08-24', '2026-09-05', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (126, 78, '2026-08-26', '2026-09-09', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (92, 65, '2026-09-03', '2026-09-19', 3, 1, 'Danado parcial');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (120, 19, '2026-09-07', '2026-09-25', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (187, 60, '2026-09-09', '2026-09-29', 2, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (157, 77, '2026-09-13', '2026-10-05', 1, 0, 'Bueno');
INSERT INTO DEVOLUCION_MATERIAL (idPersona, idMaterial, fecha_asignacion, fecha_devolucion, cantidad_devuelta, cantidad_danada, estado_devolucion) VALUES (24, 15, '2026-09-22', '2026-10-02', 2, 0, 'Bueno');

-- Las devoluciones registran estado/recuperacion, pero NO incrementan
-- el stock automaticamente. Hace falta una recepcion y revision explicita
-- para reincorporar material devuelto al inventario utilizable.

-- HISTORIAL_ASIGNACION: 224 asignaciones asociadas a TRABAJA y PASA_POR.
-- Hora estimada y motivo son informacion de prueba.

INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (107, 7, 10, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (108, 8, 17, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (110, 10, 24, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (111, 11, 31, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (157, 7, 10, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (158, 8, 17, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (160, 10, 24, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (161, 11, 31, '2026-09-01 07:00:00', '2026-09-01 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (112, 12, 19, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (115, 15, 26, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (116, 16, 33, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (118, 18, 40, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (162, 12, 19, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (165, 15, 26, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (166, 16, 33, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (168, 18, 40, '2026-09-02 07:00:00', '2026-09-02 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (120, 20, 28, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (121, 21, 35, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (122, 22, 2, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (123, 23, 9, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (170, 20, 28, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (171, 21, 35, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (172, 22, 2, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (173, 23, 9, '2026-09-03 07:00:00', '2026-09-03 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (124, 24, 37, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (125, 25, 4, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (126, 26, 11, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (128, 28, 18, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (174, 24, 37, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (175, 25, 4, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (176, 26, 11, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (178, 28, 18, '2026-09-04 07:00:00', '2026-09-04 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (129, 29, 6, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (130, 30, 13, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (131, 31, 20, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (132, 32, 27, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (179, 29, 6, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (180, 30, 13, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (181, 31, 20, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (182, 32, 27, '2026-09-05 07:00:00', '2026-09-05 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (133, 33, 15, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (134, 34, 22, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (136, 36, 29, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (137, 37, 36, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (183, 33, 15, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (184, 34, 22, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (186, 36, 29, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (187, 37, 36, '2026-09-06 07:00:00', '2026-09-06 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (138, 38, 24, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (139, 39, 31, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (140, 40, 38, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (142, 42, 5, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (188, 38, 24, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (189, 39, 31, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (190, 40, 38, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (192, 42, 5, '2026-09-07 07:00:00', '2026-09-07 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (144, 44, 33, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (145, 45, 40, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (147, 47, 7, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (148, 48, 14, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (194, 44, 33, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (195, 45, 40, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (197, 47, 7, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (198, 48, 14, '2026-09-08 07:00:00', '2026-09-08 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (101, 1, 9, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (102, 2, 16, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (103, 3, 3, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (150, 50, 2, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (151, 1, 9, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (152, 2, 16, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (153, 3, 3, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (200, 50, 2, '2026-09-09 07:00:00', '2026-09-09 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (104, 4, 11, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (107, 7, 18, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (108, 8, 5, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (110, 10, 12, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (154, 4, 11, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (157, 7, 18, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (158, 8, 5, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (160, 10, 12, '2026-09-10 07:00:00', '2026-09-10 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (111, 11, 20, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (112, 12, 7, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (115, 15, 14, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (116, 16, 21, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (161, 11, 20, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (162, 12, 7, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (165, 15, 14, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (166, 16, 21, '2026-09-11 07:00:00', '2026-09-11 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (118, 18, 9, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (120, 20, 16, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (121, 21, 23, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (122, 22, 30, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (168, 18, 9, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (170, 20, 16, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (171, 21, 23, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (172, 22, 30, '2026-09-12 07:00:00', '2026-09-12 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (123, 23, 18, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (124, 24, 25, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (125, 25, 32, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (126, 26, 39, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (173, 23, 18, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (174, 24, 25, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (175, 25, 32, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (176, 26, 39, '2026-09-13 07:00:00', '2026-09-13 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (128, 28, 27, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (129, 29, 34, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (130, 30, 1, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (131, 31, 8, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (178, 28, 27, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (179, 29, 34, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (180, 30, 1, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (181, 31, 8, '2026-09-14 07:00:00', '2026-09-14 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (132, 32, 36, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (133, 33, 3, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (134, 34, 10, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (136, 36, 17, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (182, 32, 36, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (183, 33, 3, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (184, 34, 10, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (186, 36, 17, '2026-09-15 07:00:00', '2026-09-15 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (137, 37, 5, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (138, 38, 12, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (139, 39, 19, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (140, 40, 26, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (187, 37, 5, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (188, 38, 12, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (189, 39, 19, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (190, 40, 26, '2026-09-16 07:00:00', '2026-09-16 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (142, 42, 14, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (144, 44, 21, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (145, 45, 28, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (147, 47, 35, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (192, 42, 14, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (194, 44, 21, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (195, 45, 28, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (197, 47, 35, '2026-09-17 07:00:00', '2026-09-17 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (101, 1, 37, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (102, 2, 4, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (148, 48, 23, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (150, 50, 30, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (151, 1, 37, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (152, 2, 4, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (198, 48, 23, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (200, 50, 30, '2026-09-18 07:00:00', '2026-09-18 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (103, 3, 32, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (104, 4, 39, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (107, 7, 6, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (108, 8, 13, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (153, 3, 32, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (154, 4, 39, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (157, 7, 6, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (158, 8, 13, '2026-09-19 07:00:00', '2026-09-19 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (110, 10, 1, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (111, 11, 8, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (112, 12, 15, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (115, 15, 2, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (160, 10, 1, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (161, 11, 8, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (162, 12, 15, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (165, 15, 2, '2026-09-20 07:00:00', '2026-09-20 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (116, 16, 10, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (118, 18, 17, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (120, 20, 4, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (121, 21, 11, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (166, 16, 10, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (168, 18, 17, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (170, 20, 4, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (171, 21, 11, '2026-09-21 07:00:00', '2026-09-21 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (122, 22, 19, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (123, 23, 6, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (124, 24, 13, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (125, 25, 20, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (172, 22, 19, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (173, 23, 6, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (174, 24, 13, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (175, 25, 20, '2026-09-22 07:00:00', '2026-09-22 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (126, 26, 8, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (128, 28, 15, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (129, 29, 22, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (130, 30, 29, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (176, 26, 8, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (178, 28, 15, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (179, 29, 22, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (180, 30, 29, '2026-09-23 07:00:00', '2026-09-23 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (131, 31, 17, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (132, 32, 24, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (133, 33, 31, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (134, 34, 38, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (181, 31, 17, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (182, 32, 24, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (183, 33, 31, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (184, 34, 38, '2026-09-24 07:00:00', '2026-09-24 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (136, 36, 26, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (137, 37, 33, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (138, 38, 40, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (139, 39, 7, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (186, 36, 26, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (187, 37, 33, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (188, 38, 40, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (189, 39, 7, '2026-09-25 07:00:00', '2026-09-25 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (140, 40, 35, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (142, 42, 2, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (144, 44, 9, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (145, 45, 16, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (190, 40, 35, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (192, 42, 2, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (194, 44, 9, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (195, 45, 16, '2026-09-26 07:00:00', '2026-09-26 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (101, 1, 25, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (147, 47, 4, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (148, 48, 11, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (150, 50, 18, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (151, 1, 25, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (197, 47, 4, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (198, 48, 11, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (200, 50, 18, '2026-09-27 07:00:00', '2026-09-27 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (102, 2, 13, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (103, 3, 20, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (104, 4, 27, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (107, 7, 34, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (152, 2, 13, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (153, 3, 20, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (154, 4, 27, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');
INSERT INTO HISTORIAL_ASIGNACION (idrecolector, idTransporte, idZona, fecha_inicio, fecha_fin, motivo) VALUES (157, 7, 34, '2026-09-28 07:00:00', '2026-09-28 19:00:00', 'Asignacion historica de prueba');

-- DESCARGA_BOTADERO: 112 descargas, una por recorrido PASA_POR.
-- Cada descarga corresponde a los kg sinteticos de RECOLECTA
-- del transporte y fecha, en su botadero de referencia.
-- Capacidad del botadero se actualiza por suma de descargas confirmadas.

INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (7, 7, '2026-09-01 20:00:00', 255.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (8, 8, '2026-09-01 20:00:00', 158.40, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (10, 10, '2026-09-01 20:00:00', 610.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (11, 11, '2026-09-01 20:00:00', 32.64, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (12, 12, '2026-09-02 20:00:00', 490.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (15, 15, '2026-09-02 20:00:00', 396.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (16, 16, '2026-09-02 20:00:00', 384.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (18, 18, '2026-09-02 20:00:00', 145.20, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (20, 20, '2026-09-03 20:00:00', 136.40, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (21, 21, '2026-09-03 20:00:00', 800.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (22, 22, '2026-09-03 20:00:00', 26.88, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (23, 23, '2026-09-03 20:00:00', 49.20, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (24, 24, '2026-09-04 20:00:00', 73.92, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (25, 25, '2026-09-04 20:00:00', 85.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (26, 26, '2026-09-04 20:00:00', 90.92, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (28, 28, '2026-09-04 20:00:00', 230.88, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (29, 29, '2026-09-05 20:00:00', 233.64, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (30, 30, '2026-09-05 20:00:00', 282.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (31, 31, '2026-09-05 20:00:00', 626.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (32, 32, '2026-09-05 20:00:00', 408.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (33, 33, '2026-09-06 20:00:00', 256.40, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (34, 34, '2026-09-06 20:00:00', 312.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (36, 1, '2026-09-06 20:00:00', 384.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (37, 2, '2026-09-06 20:00:00', 800.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (38, 3, '2026-09-07 20:00:00', 660.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (39, 4, '2026-09-07 20:00:00', 36.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (40, 5, '2026-09-07 20:00:00', 76.56, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (42, 7, '2026-09-07 20:00:00', 48.12, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (44, 9, '2026-09-08 20:00:00', 336.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (45, 10, '2026-09-08 20:00:00', 158.40, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (47, 12, '2026-09-08 20:00:00', 48.24, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (48, 13, '2026-09-08 20:00:00', 53.52, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (1, 1, '2026-09-09 20:00:00', 67.08, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (2, 2, '2026-09-09 20:00:00', 48.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (3, 3, '2026-09-09 20:00:00', 305.60, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (50, 15, '2026-09-09 20:00:00', 346.72, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (4, 4, '2026-09-10 20:00:00', 107.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (7, 7, '2026-09-10 20:00:00', 38.88, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (8, 8, '2026-09-10 20:00:00', 24.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (10, 10, '2026-09-10 20:00:00', 420.16, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (11, 11, '2026-09-11 20:00:00', 562.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (12, 12, '2026-09-11 20:00:00', 43.56, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (15, 15, '2026-09-11 20:00:00', 405.64, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (16, 16, '2026-09-11 20:00:00', 408.84, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (18, 18, '2026-09-12 20:00:00', 62.52, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (20, 20, '2026-09-12 20:00:00', 376.24, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (21, 21, '2026-09-12 20:00:00', 81.84, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (22, 22, '2026-09-12 20:00:00', 95.04, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (23, 23, '2026-09-13 20:00:00', 198.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (24, 24, '2026-09-13 20:00:00', 50.76, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (25, 25, '2026-09-13 20:00:00', 800.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (26, 26, '2026-09-13 20:00:00', 384.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (28, 28, '2026-09-14 20:00:00', 37.44, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (29, 29, '2026-09-14 20:00:00', 132.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (30, 30, '2026-09-14 20:00:00', 124.08, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (31, 31, '2026-09-14 20:00:00', 313.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (32, 32, '2026-09-15 20:00:00', 700.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (33, 33, '2026-09-15 20:00:00', 354.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (34, 34, '2026-09-15 20:00:00', 175.44, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (36, 1, '2026-09-15 20:00:00', 140.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (37, 2, '2026-09-16 20:00:00', 44.16, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (38, 3, '2026-09-16 20:00:00', 369.20, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (39, 4, '2026-09-16 20:00:00', 416.32, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (40, 5, '2026-09-16 20:00:00', 408.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (42, 7, '2026-09-17 20:00:00', 370.16, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (44, 9, '2026-09-17 20:00:00', 391.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (45, 10, '2026-09-17 20:00:00', 176.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (47, 12, '2026-09-17 20:00:00', 87.12, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (1, 1, '2026-09-18 20:00:00', 97.68, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (2, 2, '2026-09-18 20:00:00', 88.44, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (48, 13, '2026-09-18 20:00:00', 89.76, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (50, 15, '2026-09-18 20:00:00', 84.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (3, 3, '2026-09-19 20:00:00', 680.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (4, 4, '2026-09-19 20:00:00', 408.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (7, 7, '2026-09-19 20:00:00', 454.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (8, 8, '2026-09-19 20:00:00', 24.72, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (10, 10, '2026-09-20 20:00:00', 131.12, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (11, 11, '2026-09-20 20:00:00', 281.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (12, 12, '2026-09-20 20:00:00', 366.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (15, 15, '2026-09-20 20:00:00', 25.68, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (16, 16, '2026-09-21 20:00:00', 64.08, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (18, 18, '2026-09-21 20:00:00', 107.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (20, 20, '2026-09-21 20:00:00', 291.48, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (21, 21, '2026-09-21 20:00:00', 61.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (22, 22, '2026-09-22 20:00:00', 405.84, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (23, 23, '2026-09-22 20:00:00', 454.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (24, 24, '2026-09-22 20:00:00', 24.72, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (25, 25, '2026-09-22 20:00:00', 640.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (26, 26, '2026-09-23 20:00:00', 272.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (28, 28, '2026-09-23 20:00:00', 300.20, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (29, 29, '2026-09-23 20:00:00', 250.20, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (30, 30, '2026-09-23 20:00:00', 408.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (31, 31, '2026-09-24 20:00:00', 154.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (32, 32, '2026-09-24 20:00:00', 634.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (33, 33, '2026-09-24 20:00:00', 30.72, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (34, 34, '2026-09-24 20:00:00', 102.96, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (36, 1, '2026-09-25 20:00:00', 13.92, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (37, 2, '2026-09-25 20:00:00', 167.20, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (38, 3, '2026-09-25 20:00:00', 127.60, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (39, 4, '2026-09-25 20:00:00', 357.52, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (40, 5, '2026-09-26 20:00:00', 89.76, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (42, 7, '2026-09-26 20:00:00', 22.08, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (44, 9, '2026-09-26 20:00:00', 128.04, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (45, 10, '2026-09-26 20:00:00', 308.40, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (1, 1, '2026-09-27 20:00:00', 60.96, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (47, 12, '2026-09-27 20:00:00', 254.88, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (48, 13, '2026-09-27 20:00:00', 52.80, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (50, 15, '2026-09-27 20:00:00', 34.08, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (2, 2, '2026-09-28 20:00:00', 324.40, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (3, 3, '2026-09-28 20:00:00', 530.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (4, 4, '2026-09-28 20:00:00', 360.00, 'Confirmada');
INSERT INTO DESCARGA_BOTADERO (idTransporte, idBotadero, fecha, cantidad_kg, estado) VALUES (7, 7, '2026-09-28 20:00:00', 660.00, 'Confirmada');

UPDATE BOTADERO AS b
LEFT JOIN (
    SELECT idBotadero, SUM(cantidad_kg) AS total
    FROM DESCARGA_BOTADERO
    WHERE estado = 'Confirmada'
    GROUP BY idBotadero
) AS x ON x.idBotadero = b.idBotadero
SET b.capacidad_utilizada = COALESCE(x.total, 0),
    b.estado_operativo = CASE
        WHEN COALESCE(x.total,0) >= b.capacidad_maxima_kg THEN 'Saturado'
        WHEN COALESCE(x.total,0) >= b.capacidad_maxima_kg * .90 THEN 'Critico'
        WHEN COALESCE(x.total,0) >= b.capacidad_maxima_kg * .70 THEN 'Advertencia'
        ELSE 'Disponible'
    END;

-- Restringir campos numericos y evitar saldos negativos.
ALTER TABLE CONTENEDOR
    ADD CONSTRAINT chk_contenedor_volumen CHECK (capacidad_litros > 0),
    ADD CONSTRAINT chk_contenedor_capacidadkg CHECK (capacidad_kg > 0);
ALTER TABLE TRANSPORTE
    ADD CONSTRAINT chk_transporte_kg CHECK (capacidad_kg > 0 AND carga_actual_kg BETWEEN 0 AND capacidad_kg);
ALTER TABLE BOTADERO
    ADD CONSTRAINT chk_botadero_kg CHECK (capacidad_maxima_kg > 0 AND capacidad_utilizada BETWEEN 0 AND capacidad_maxima_kg);
ALTER TABLE MATERIAL_TRABAJO
    ADD CONSTRAINT chk_stock_material CHECK (stock_actual >= 0 AND stock_minimo >= 0);
ALTER TABLE RECOLECTA
    ADD CONSTRAINT chk_recolecta_kg CHECK (cantidad_kg > 0);

-- Comprobar integridad de datos: deben devolver cero incoherencias.
SELECT 'Recolecciones sin ruta/zona coherentes' AS control, COUNT(*) AS errores
FROM RECOLECTA rc
JOIN RUTA ru ON ru.idRuta = rc.idRuta
JOIN CONTENEDOR co ON co.idContenedor = rc.idContenedor
JOIN VIA vi ON vi.idVia = co.idVia
LEFT JOIN INTEGRA i ON i.idRuta = rc.idRuta AND i.idVia = vi.idVia AND i.idContenedor = rc.idContenedor
LEFT JOIN PASA_POR pp ON pp.idTransporte = rc.idTransporte AND pp.idRuta = rc.idRuta AND pp.fecha = rc.fecha
LEFT JOIN TRABAJA tra ON tra.idrecolector = rc.idrecolector AND tra.idZona = ru.idZona AND tra.fecha = rc.fecha
WHERE ru.idZona <> vi.idZona OR i.idRuta IS NULL OR pp.idRuta IS NULL OR tra.idZona IS NULL;

SELECT 'Descarga supera capacidad de botadero' AS control, COUNT(*) AS errores
FROM BOTADERO WHERE capacidad_utilizada > capacidad_maxima_kg;

SELECT 'Compras/entregas contra stock' AS control, COUNT(*) AS errores
FROM MATERIAL_TRABAJO m
LEFT JOIN (SELECT idMaterial, SUM(cantidad) AS n FROM COMPRA_MATERIAL GROUP BY idMaterial) cmp ON cmp.idMaterial=m.idMaterial
LEFT JOIN (SELECT idMaterial, SUM(cantidad) AS n FROM DISPONE GROUP BY idMaterial) d ON d.idMaterial=m.idMaterial
WHERE m.stock_actual <> COALESCE(cmp.n,0)-COALESCE(d.n,0);

-- Resumen final para verificar el volumen de los datos.
SELECT 'ZONA' AS tabla, COUNT(*) AS registros FROM ZONA
UNION ALL SELECT 'VIA', COUNT(*) FROM VIA
UNION ALL SELECT 'RUTA', COUNT(*) FROM RUTA
UNION ALL SELECT 'CONTENEDOR', COUNT(*) FROM CONTENEDOR
UNION ALL SELECT 'RECOLECTA', COUNT(*) FROM RECOLECTA
UNION ALL SELECT 'COMPRA_MATERIAL', COUNT(*) FROM COMPRA_MATERIAL
UNION ALL SELECT 'DEVOLUCION_MATERIAL', COUNT(*) FROM DEVOLUCION_MATERIAL
UNION ALL SELECT 'DESCARGA_BOTADERO', COUNT(*) FROM DESCARGA_BOTADERO
UNION ALL SELECT 'HISTORIAL_ASIGNACION', COUNT(*) FROM HISTORIAL_ASIGNACION;


COMMIT;
