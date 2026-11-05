# DOCUMENTACION-SQL

#### Documentacion sobre las funciones, procedimientos, triggers y cursores

### FUNCIONES

- Funciones Basicas

  ***
  1. **f_persona_por_LugarTrabajo:** Seleccionar que personas trabajan en los distintos departamentos (LP, SC, ...) segun el carnet de identidad.

  2. **f_persona_edad:** Calcular la edad de cada empleado,

- Funciones Complejas
  ***
  1. **f_est_personaltrabaja:** Mostrara datos estadisticos como por ejemplo si el usuario selecciona LP entonces se mostrara si hubo un incremento o decremento de personal ademas de clasificarloigualmente por sexo y un rango de edad si se desea saber, tambien el tipo de trabajo que se hace de cada empleado.

  2. f_datos_zona: Calcular la cantidad de vias y rutas, tipo de contenedores y recolectores que hay en estos en porcentajes de todas las zonas

  3. f_logistica: Datos estadisticos de compras de materiales hechos segun un rango de fechas tambien calcular el promedio de lo gastado por empleado.

  4. f_desgaste_material: Sacar el porcentaje de mayor o menor desgaste en los materiales de trabajo de cada empleado y mostrar alertas de si este lo desgasta mas rapido o tambien si el material sigue en un muy buen estado.

### PROCEDIMIENTOS

- Procedimientos_Basicos

  ***

- Procedimientos Compkejos
  ***
  1. p_reasignar_personal: Segun la edad y el tipo de personal se podra reasignar tareas ademas de verificar si este esta disponible. Ver si esta con buena edad para ser recolector o Cargador.

  2. p_compra_materiales: Al hacer las compras y designar los materiales, verificar si el empleado hace mas desgaste de estos o no, segun eso mostrar o no una alerta antes de asignarle nuevos materiales de trabajo.

  3. p_asignar_transporte_botadero: al asignar el transporte al botadero primero verificar si el botadero puede aceptar mas cantidad de basura. Esto sacar segun las hectareas del botadero y calcular cuantos transportes pueden depositar la basura teniendo en cuenta cuanto soporta cada transporte en si.
