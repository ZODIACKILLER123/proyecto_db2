Funciones, procedimientos, triggers, reportes con cursores y entidades añadidas

Versión de referencia: Ecogestion_Dashboard_SQL_Corregido.zip · MySQL 8.0 · React/Vite · FastAPI/PyMySQL

# 1. Objetivo y alcance

Este documento describe lo que realizan las rutinas y tablas encontradas en los archivos SQL del proyecto, así como su relación con los formularios del sistema. Se diferencia entre consultas de análisis (solo lectura), operaciones de escritura, validaciones automáticas y reportes.

Fuente principal: db/init/01_schema_y_datos.sql, 02_funciones.sql, 03_procedimientos.sql, 04_triggers_empresa_recolectora.sql y 05_cursores_empresa_recolectora.sql; catálogo de operaciones backend/app/catalogo.py.

# 2. Estructura de la base de datos

La versión revisada define 19 tablas: 15 del esquema base y cuatro tablas añadidas. El SQL 01 elimina y recrea las tablas cuando se importa desde cero; no debe ejecutarse indiscriminadamente sobre una base que contenga información propia.

| Tablas originales (15)         | Uso principal                                    |
|--------------------------------|--------------------------------------------------|
| ZONA, VIA, CONTENEDOR          | Organización territorial y puntos de recolección |
| RUTA, INTEGRA, PASA_POR        | Diseño de rutas y programación de camiones       |
| PERSONA, CONDUCTOR, RECOLECTOR | Personal y especializaciones                     |
| TRANSPORTE, BOTADERO           | Flota y destinos                                 |
| RECOLECTA, TRABAJA             | Operaciones ejecutadas y jornadas                |
| MATERIAL_TRABAJO, DISPONE      | Catálogo y entregas de materiales                |

## 2.1. Cuatro tablas añadidas

| Tabla                | Qué almacena                                                                 | Relaciones / utilidad                                                                                                          |
|----------------------|------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| COMPRA_MATERIAL      | Compra por material, proveedor, fecha, cantidad, precio unitario y total.    | FK idMaterial → MATERIAL_TRABAJO. Permite resumir adquisiciones y costos.                                                      |
| DEVOLUCION_MATERIAL  | Devoluciones asociadas a una entrega, unidades devueltas, dañadas y estado.  | FK compuesta (idPersona,idMaterial,fecha_asignacion) → DISPONE.                                                                |
| DESCARGA_BOTADERO    | Fecha/hora, transporte, botadero, peso descargado y estado.                  | FK → TRANSPORTE y BOTADERO. Permite medir ocupación y liberar carga del camión.                                                |
| HISTORIAL_ASIGNACION | Historial de asignación de recolector, vehículo, zona, inicio, fin y motivo. | FK → RECOLECTOR, TRANSPORTE y ZONA. Existe en el esquema, pero las cinco operaciones actuales no la alimentan automáticamente. |

## 2.2. Cambios importantes en tablas existentes

El esquema incorpora capacidad y carga numéricas en TRANSPORTE, capacidad y ocupación en BOTADERO, distancia_km en RUTA, capacidad_kg en CONTENEDOR, stock y tipo de uso en MATERIAL_TRABAJO, así como estado laboral y contratación en PERSONA. RECOLECTA tiene idRecoleccion autoincremental, peso, fecha, hora, ruta y vehículo; DISPONE registra el precio unitario al momento de asignación. Estos campos permiten los cálculos y validaciones nuevas.

# 3. Funciones almacenadas: análisis de solo lectura

Se implementan cinco funciones complejas que retornan objetos JSON; se apoyan en 14 funciones básicas (prefijo f_b\_) y 10 intermedias (prefijo f_i\_). Las funciones no registran movimientos ni actualizan las tablas.

## F1 · f_analisis_operativo_zona

Evalúa la cobertura de atención y la disponibilidad de personal de una zona en un período.

Parámetros: p_zona INT, p_desde DATE, p_hasta DATE.

Tablas relacionadas: ZONA, VIA, CONTENEDOR, RUTA, TRABAJA, RECOLECTA y relaciones de la zona.

Resultado / efecto: JSON con número de vías, rutas, contenedores, contenedores atendidos, recolectores distintos, cobertura porcentual, contenedores por recolector y diagnóstico.

Validaciones y observaciones: Verifica rango de fechas y existencia de zona; clasifica la cobertura como alta (≥90 %), media (≥60 %) o baja; también informa ausencia de contenedores o personal.

## F2 · f_analisis_capacidad_botadero

Determina la ocupación y margen de capacidad física de un botadero, junto con la flota asociada.

Parámetros: p_botadero INT.

Tablas relacionadas: BOTADERO, TRANSPORTE, DESCARGA_BOTADERO.

Resultado / efecto: JSON con capacidad máxima, utilizada y disponible (kg), porcentaje de ocupación, kilos descargados confirmados, cantidad de vehículos operativos y capacidad nominal agregada de flota.

Validaciones y observaciones: Categorías del código: SATURADO (≥100 %), CRITICO (≥90 %), ADVERTENCIA (≥70 %) o DISPONIBLE. La ocupación es el saldo almacenado, no necesariamente las descargas del período.

## F3 · f_analisis_rendimiento_personal

Resume la actividad de un recolector según sus jornadas y recolecciones registradas.

Parámetros: p_recolector INT, p_desde DATE, p_hasta DATE.

Tablas relacionadas: PERSONA, RECOLECTOR, TRABAJA, RECOLECTA.

Resultado / efecto: JSON con kg recolectados, días asignados, operaciones, kg por día asignado, operaciones por día y clasificación de presencia de actividad.

Validaciones y observaciones: No asigna calificaciones arbitrarias de productividad; diferencia SIN JORNADAS, SIN RECOLECCIONES o ACTIVIDAD REGISTRADA.

## F4 · f_analisis_costos_materiales

Calcula el costo de materiales entregados a una persona y su nivel de deterioro.

Parámetros: p_persona INT, p_desde DATE, p_hasta DATE.

Tablas relacionadas: PERSONA, DISPONE, MATERIAL_TRABAJO, DEVOLUCION_MATERIAL.

Resultado / efecto: JSON con unidades entregadas, devueltas, dañadas, costo de entregas en Bs, costo medio y porcentaje de desgaste sobre entregas.

Validaciones y observaciones: El costo se basa en precio_unitario_asignacion. Ojo: el total de devoluciones se filtra por fecha de asignación, no por fecha efectiva de devolución en esa consulta.

## F5 · f_analisis_eficiencia_rutas

Analiza el cumplimiento de contenedores planificados, las salidas y el peso atribuido a una ruta.

Parámetros: p_ruta INT, p_desde DATE, p_hasta DATE.

Tablas relacionadas: RUTA, INTEGRA, RECOLECTA, PASA_POR.

Resultado / efecto: JSON con km nominales, contenedores planificados/atendidos/pendientes, cobertura, kg, salidas y kg por km nominal.

Validaciones y observaciones: Kg por km usa distancia nominal de ruta, no kilómetros recorridos reales acumulados. Diagnóstico por cobertura alta/media/baja.

## 3.1. Funciones auxiliares

Básicas (14): f_b_total_contenedores_zona, f_b_contenedores_atendidos_zona, f_b_personal_zona, f_b_botadero_descargado, f_b_capacidad_flota_botadero, f_b_recolector_kg, f_b_recolector_dias, f_b_recolector_operaciones, f_b_material_costo_entregado, f_b_material_unidades_entregadas, f_b_material_unidades_danadas, f_b_contenedores_ruta, f_b_atendidos_ruta, f_b_kg_ruta.

Intermedias (10): f_i_cobertura_zona, f_i_carga_por_recolector_zona, f_i_ocupacion_botadero, f_i_margen_botadero, f_i_kg_por_dia_personal, f_i_operaciones_por_dia, f_i_desgaste_material, f_i_costo_por_unidad_entregada, f_i_cobertura_ruta, f_i_kg_por_km_ruta.

# 4. Procedimientos almacenados: operaciones de escritura

Estos cinco procedimientos fueron incluidos en 03_procedimientos.sql de la versión actualizada, porque ese archivo en el ZIP original recibido repetía funciones y no definía procedimientos. Usan transacciones, COMMIT al finalizar y ROLLBACK ante errores SQL. Son los invocados desde los formularios del frontend.

## P1 · p_programar_ruta

Programa un transporte en una ruta y fecha.

Parámetros: p_transporte, p_ruta, p_fecha.

Tablas relacionadas: TRANSPORTE, RUTA, PASA_POR.

Resultado / efecto: Inserta una fila en PASA_POR; devuelve mensaje de confirmación.

Validaciones y observaciones: El camión debe estar Operativo, la ruta Activa y la programación no debe existir en la misma combinación.

## P2 · p_registrar_recoleccion

Registra una operación de recolección y aumenta la carga del camión asignado al recolector.

Parámetros: p_recolector, p_contenedor, p_ruta, p_fecha, p_hora, p_kg.

Tablas relacionadas: RECOLECTOR, TRANSPORTE, RECOLECTA, además de verificaciones del trigger T1.

Resultado / efecto: Inserta en RECOLECTA; suma kg a TRANSPORTE.carga_actual_kg.

Validaciones y observaciones: Rechaza pesos no positivos o exceso de capacidad. El trigger T1 comprueba ruta, contenedor, trabajador, zona y programación de ese día.

## P3 · p_asignar_material

Entrega material a una persona y descuenta existencias.

Parámetros: p_persona, p_material, p_fecha, p_cantidad.

Tablas relacionadas: MATERIAL_TRABAJO, DISPONE, PERSONA mediante T3.

Resultado / efecto: Registra DISPONE con precio de asignación y resta unidades del stock_actual.

Validaciones y observaciones: Necesita stock suficiente; T3 exige persona activa, fecha válida respecto de contratación y valores consistentes.

## P4 · p_registrar_descarga

Registra la descarga de un camión en un botadero y actualiza ambos saldos.

Parámetros: p_transporte, p_botadero, p_fecha DATETIME, p_kg.

Tablas relacionadas: TRANSPORTE, BOTADERO, DESCARGA_BOTADERO.

Resultado / efecto: Inserta descarga confirmada; reduce carga del transporte y aumenta capacidad_utilizada del botadero.

Validaciones y observaciones: Exige carga suficiente, espacio disponible y validaciones operativas del trigger T4.

## P5 · p_registrar_devolucion

Recibe materiales reutilizables y reincorpora al stock las unidades no dañadas.

Parámetros: p_persona, p_material, p_fecha_asignacion, p_fecha_devolucion, p_cantidad, p_danada.

Tablas relacionadas: MATERIAL_TRABAJO, DISPONE, DEVOLUCION_MATERIAL.

Resultado / efecto: Inserta devolución; aumenta stock por cantidad_devuelta − cantidad_danada.

Validaciones y observaciones: T5 confirma entrega original, uso reutilizable, fechas válidas y que las devoluciones acumuladas no excedan la cantidad entregada.

# 5. Triggers: validación automática BEFORE INSERT

Los cinco triggers se disparan al insertar filas en sus respectivas tablas. No se ejecutan con CALL y no realizan ajustes de stock o carga, porque los movimientos ya los efectúan los procedimientos, evitando contabilización doble.

| Trigger                            | Evento                            | Validación principal                                                                                                                                          | Se activa con                       |
|------------------------------------|-----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| T1 trg_01_validar_recoleccion      | BEFORE INSERT RECOLECTA           | Peso positivo, capacidad del contenedor, personal activo, mismo transporte del recolector, contenedor integrado a ruta/zona, PASA_POR y TRABAJA en esa fecha. | P2 o INSERT directo en RECOLECTA.   |
| T2 trg_02_validar_integra          | BEFORE INSERT INTEGRA             | La ruta y la vía pertenecen a la misma zona; el contenedor pertenece a esa vía.                                                                               | INSERT en INTEGRA.                  |
| T3 trg_03_validar_entrega_material | BEFORE INSERT DISPONE             | Cantidad y precio válidos, empleado activo, entrega posterior a contratación e inventario no negativo.                                                        | P3 o INSERT en DISPONE.             |
| T4 trg_04_validar_descarga         | BEFORE INSERT DESCARGA_BOTADERO   | Vehículo operativo, botadero no saturado, peso positivo y dentro de carga y capacidad.                                                                        | P4 o INSERT en DESCARGA_BOTADERO.   |
| T5 trg_05_validar_devolucion       | BEFORE INSERT DEVOLUCION_MATERIAL | Entrega original existente, material reutilizable, daño válido y devolución total acumulada ≤ entrega.                                                        | P5 o INSERT en DEVOLUCION_MATERIAL. |

Las infracciones se informan mediante SIGNAL SQLSTATE 45000. IMPORTANTE: por ser BEFORE INSERT, estas rutinas no supervisan cambios realizados directamente mediante UPDATE; las operaciones manuales que evitan procedimientos pueden no mantener sincronizados carga y stock.

# 6. Reportes con cursores (cinco procedimientos de lectura)

Cada reporte recibe p_desde y p_hasta; declara cursores anidados, recorre registros fila a fila, construye una tabla TEMPORARY de uso de sesión, entrega un SELECT de resultados y finalmente elimina la tabla temporal. Las tablas temporales NO incrementan las 19 entidades persistentes del modelo.

| Reporte / cursor                     | Recorrido y relaciones                                              | Columnas clave del resultado                                                    |
|--------------------------------------|---------------------------------------------------------------------|---------------------------------------------------------------------------------|
| C1 c_reporte_zonas_vias_contenedores | ZONA → VIA → CONTENEDOR y RECOLECTA.                                | Vías, contenedores, atendidos, kg, cobertura por zona.                          |
| C2 c_reporte_rutas_contenedores      | RUTA → INTEGRA → RECOLECTA; contenedores únicos.                    | Planificados, atendidos, kg, kg/km nominal, cobertura.                          |
| C3 c_reporte_botaderos_descargas     | BOTADERO → DESCARGA_BOTADERO → TRANSPORTE.                          | Descargas, transportes distintos, kg del período, capacidad y ocupación actual. |
| C4 c_reporte_personal_jornadas       | RECOLECTOR → TRABAJA → RECOLECTA, enlazada con RUTA por zona.       | Jornadas, zonas, operaciones, kg, kg/jornada.                                   |
| C5 c_reporte_materiales_movimientos  | MATERIAL_TRABAJO → DISPONE → DEVOLUCION_MATERIAL y COMPRA_MATERIAL. | Compras y costo, entregas, devoluciones, daño, stock, tasa de daño.             |

Consideraciones: C3 combina kg descargados durante el intervalo con ocupación actual, que es un saldo acumulado. C5 toma devoluciones dentro del rango solamente si la entrega original también está dentro del rango. Estos matices deben explicarse al defender el proyecto.

# 7. Flujo integrado de las operaciones

| Paso desde interfaz       | Rutina backend/SQL      | Trigger | Tablas afectadas                         |
|---------------------------|-------------------------|---------|------------------------------------------|
| Programar ruta            | p_programar_ruta        | —       | PASA_POR                                 |
| Registrar recolección     | p_registrar_recoleccion | T1      | RECOLECTA y TRANSPORTE                   |
| Asignar material          | p_asignar_material      | T3      | DISPONE y MATERIAL_TRABAJO               |
| Registrar descarga        | p_registrar_descarga    | T4      | DESCARGA_BOTADERO, TRANSPORTE y BOTADERO |
| Registrar devolución      | p_registrar_devolucion  | T5      | DEVOLUCION_MATERIAL y MATERIAL_TRABAJO   |
| Asociar contenedor a ruta | INSERT en INTEGRA       | T2      | INTEGRA                                  |

La interfaz usa backend/app/catalogo.py para definir formularios y endpoints. Las funciones se consultan en /funciones/{clave}, los procedimientos se ejecutan por /procedimientos/{clave} y los reportes se consultan por /cursores/{clave}. Los triggers son responsabilidad del motor MySQL, no del frontend.

# 8. Ejemplos de uso desde MySQL

SELECT JSON_PRETTY(f_analisis_operativo_zona(1,'2026-09-01','2026-09-30'));

SELECT JSON_PRETTY(f_analisis_capacidad_botadero(1));

CALL p_programar_ruta(1,1,'2026-09-15');

CALL p_registrar_recoleccion(101,1,1,'2026-09-15','08:30:00',45.50);

CALL c_reporte_personal_jornadas('2026-09-01','2026-09-30');

Los IDs y fechas son ilustrativos: cada operación INSERT debe cumplir con las claves foráneas, los datos reales y las validaciones de los triggers. Una recolección no será aceptada si falta PASA_POR o TRABAJA de la fecha.

# 9. Cómo comprobar que todo quedó instalado

SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='empresa_recolectora';

SELECT ROUTINE_TYPE, ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='empresa_recolectora' ORDER BY ROUTINE_TYPE, ROUTINE_NAME;

SELECT TRIGGER_NAME, EVENT_OBJECT_TABLE FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='empresa_recolectora';

SELECT COUNT(\*) AS zonas FROM ZONA; SELECT COUNT(\*) AS recolecciones FROM RECOLECTA;

Cantidad esperada en el código: 19 tablas persistentes, 29 funciones (14 básicas + 10 intermedias + 5 complejas), 10 procedimientos (5 operativos + 5 reportes con cursores) y 5 triggers. Estos son objetos definidos en los archivos, no una afirmación de que ya estén instalados en tu instancia de MySQL.

# 10. Observaciones y límites para la exposición

- El archivo 03_procedimientos.sql de la versión actualizada corresponde a procedimientos agregados después de revisar el ZIP original; conviene identificarlos como parte de la implementación del sistema.

- COMPRA_MATERIAL registra compras y C5 las contabiliza; en los cinco procedimientos disponibles NO aparece un procedimiento de registrar compra ni un trigger que actualice stock al comprar. Si se utiliza ingreso manual, es necesario considerar cómo actualizar stock.

- HISTORIAL_ASIGNACION está creada y relacionada, pero las operaciones actuales no generan su historial automáticamente.

- Las funciones de análisis leen datos; los cursores construyen reportes; los procedimientos efectúan movimientos; los triggers validan los INSERT antes de permitirlos.

- En la versión actual, las validaciones mediante triggers se realizan al insertar; no cubren todos los UPDATE o DELETE directos desde el gestor de BD.

- El instalador de rutinas puede reconstruir objetos SQL sin recargar los datos. Las tablas creadas no implican necesariamente registros cargados.

Fin del documento. Redactado a partir de los archivos de la versión de proyecto disponible en la conversación.

# 11. Solución de problemas: registrar descarga en botadero

## Mensaje: `Carga insuficiente o capacidad disponible del botadero agotada`

**Origen exacto:** `db/init/03_procedimientos.sql`, procedimiento `p_registrar_descarga`.

Antes de insertar en `DESCARGA_BOTADERO` se obtienen y bloquean los saldos actuales del transporte y del botadero:

```sql
SELECT carga_actual_kg INTO v_carga
FROM TRANSPORTE
WHERE idTransporte = p_transporte FOR UPDATE;

SELECT capacidad_maxima_kg - capacidad_utilizada INTO v_libre
FROM BOTADERO
WHERE idBotadero = p_botadero FOR UPDATE;
```

Se rechaza la operación si el peso solicitado es mayor que `v_carga` **o** mayor que `v_libre`. El mismo error también puede indicar que no existe uno de los IDs, porque el procedimiento recibe valores `NULL`. El trigger `trg_04_validar_descarga` realiza controles adicionales: transporte operativo, botadero no saturado, descarga positiva y confirmada.

### Diagnóstico con los IDs del formulario

Sustituye `1`, `1` y `500` por el ID del transporte, el ID del botadero y los kilogramos de descarga que hayas seleccionado:

```sql
SET @id_transporte = 1;
SET @id_botadero = 1;
SET @kg = 500;

SELECT idTransporte, placa, estado, capacidad_kg, carga_actual_kg,
       @kg AS kg_solicitados,
       (carga_actual_kg >= @kg) AS alcanza_carga
FROM TRANSPORTE WHERE idTransporte = @id_transporte;

SELECT idBotadero, nombre, estado_operativo, capacidad_maxima_kg,
       capacidad_utilizada,
       capacidad_maxima_kg - capacidad_utilizada AS espacio_libre_kg,
       (capacidad_maxima_kg - capacidad_utilizada >= @kg) AS alcanza_espacio
FROM BOTADERO WHERE idBotadero = @id_botadero;
```

- Si `alcanza_carga` es `0`, registra antes una recolección válida mediante `p_registrar_recoleccion`.
- Si `alcanza_espacio` es `0`, elige otro botadero que tenga espacio real disponible.
- Si alguna consulta no devuelve fila, verifica que el ID sea correcto y que estés conectado a `empresa_recolectora`.
- Si el procedimiento pasa sus primeras verificaciones pero falla con un mensaje `T4: ...`, revisa `estado` del transporte y `estado_operativo` del botadero.

**Dato clave del script de prueba:** en `01_schema_y_datos.sql` se ejecuta `UPDATE TRANSPORTE SET carga_actual_kg = 0;`, por lo que un camión puede estar vacío al finalizar la carga inicial, aunque haya registros históricos. No inventes ni cargues manualmente residuos para saltarte la regla: genera una recolección operativa real.

**Nota sobre capacidad:** el script inicial deriva `BOTADERO.capacidad_maxima_kg` multiplicando las hectáreas por `500000`. Esto es una **suposición para datos de prueba**, no una equivalencia física universal de superficie a masa; en un entorno real debe sustituirse por la capacidad técnica conocida del botadero.

### Secuencia habitual del sistema

1. Programar transporte y ruta (`p_programar_ruta`).
2. Verificar que el recolector tiene `TRABAJA` para la zona y fecha, y que el contenedor está en `INTEGRA`.
3. Registrar peso recolectado (`p_registrar_recoleccion`) para incrementar la carga del transporte.
4. Registrar descarga (`p_registrar_descarga`) con peso menor o igual a la carga del transporte y al espacio restante del botadero.

El procedimiento guarda la descarga confirmada y actualiza ambos saldos en **una transacción**. Si una verificación falla, ejecuta `ROLLBACK` y no registra una descarga parcial.
