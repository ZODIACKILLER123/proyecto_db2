"""Catálogo explícito: 5 funciones, 7 procedimientos, 8 informes con cursores y 13 triggers."""
import re


def campo(name, label, tipo='text', requerido=True, tabla=None, opciones=None):
    v = dict(name=name, label=label, tipo=tipo, requerido=requerido)
    if tabla: v['tabla'] = tabla
    if opciones: v['opciones'] = opciones
    return v


def identificador(nombre, tabla, label=None):
    return campo(nombre, label or nombre.replace('p_', 'ID '), 'number', tabla=tabla)


def periodo():
    return [campo('p_desde', 'Desde', 'date'), campo('p_hasta', 'Hasta', 'date')]


FUNCIONES = {
 'zona': dict(routine='f_analisis_operativo_zona', titulo='Diagnóstico operativo por zona', descripcion='Cobertura, personal y peso recolectado durante un período.', params=[identificador('p_zona','ZONA','Zona'), *periodo()]),
 'botadero': dict(routine='f_analisis_capacidad_botadero', titulo='Capacidad del botadero', descripcion='Ocupación, descarga y capacidad disponible del destino.', params=[identificador('p_botadero','BOTADERO','Botadero')]),
 'personal': dict(routine='f_analisis_rendimiento_personal', titulo='Rendimiento del recolector', descripcion='Jornadas, operaciones y kilogramos recolectados.', params=[identificador('p_recolector','RECOLECTOR','Recolector'), *periodo()]),
 'materiales': dict(routine='f_analisis_costos_materiales', titulo='Costos de materiales', descripcion='Entregas, devoluciones, daños y costos por persona.', params=[identificador('p_persona','PERSONA','Persona'), *periodo()]),
 'rutas': dict(routine='f_analisis_eficiencia_rutas', titulo='Eficiencia de rutas', descripcion='Cobertura, salidas y kilogramos por kilómetro.', params=[identificador('p_ruta','RUTA','Ruta'), *periodo()]),
}

# Los nombres concuerdan con las cinco operaciones creadas en 03_procedimientos.sql.
PROCEDIMIENTOS = {
 'programar_ruta': dict(routine='p_programar_ruta', titulo='Programar ruta del transporte', descripcion='Registra el recorrido de un camión en una fecha; activa la validación al recolectar.', params=[identificador('p_transporte','TRANSPORTE','Transporte'), identificador('p_ruta','RUTA','Ruta'), campo('p_fecha','Fecha del recorrido','date')]),
 'registrar_recoleccion': dict(routine='p_registrar_recoleccion', titulo='Registrar una recolección', descripcion='Valida ruta, contenedor, jornada y capacidad del camión. Activa el trigger T1.', params=[identificador('p_recolector','RECOLECTOR','Recolector'), identificador('p_contenedor','CONTENEDOR','Contenedor'), identificador('p_ruta','RUTA','Ruta'), campo('p_fecha','Fecha','date'), campo('p_hora','Hora','time'), campo('p_kg','Cantidad recolectada (kg)','number')]),
 'asignar_material': dict(routine='p_asignar_material', titulo='Entregar material al personal', descripcion='Descuenta inventario y registra la asignación; activa el trigger T3.', params=[identificador('p_persona','PERSONA','Persona'), identificador('p_material','MATERIAL_TRABAJO','Material'), campo('p_fecha','Fecha de entrega','date'), campo('p_cantidad','Cantidad','number')]),
 'registrar_descarga': dict(routine='p_registrar_descarga', titulo='Registrar descarga en botadero', descripcion='Descarga el camión y aumenta la ocupación del botadero; activa el trigger T4.', params=[identificador('p_transporte','TRANSPORTE','Transporte'), identificador('p_botadero','BOTADERO','Botadero'), campo('p_fecha','Fecha y hora','datetime-local'), campo('p_kg','Peso descargado (kg)','number')]),
 'registrar_devolucion': dict(routine='p_registrar_devolucion', titulo='Registrar devolución de material', descripcion='Devuelve unidades disponibles al inventario; activa el trigger T5.', params=[identificador('p_persona','PERSONA','Persona'), identificador('p_material','MATERIAL_TRABAJO','Material'), campo('p_fecha_asignacion','Fecha de entrega original','date'), campo('p_fecha_devolucion','Fecha de devolución','date'), campo('p_cantidad','Cantidad devuelta','number'), campo('p_danada','Unidades dañadas','number')]),
 'definir_presupuesto': dict(routine='p_definir_presupuesto_material', titulo='Definir presupuesto de materiales', descripcion='Registra el monto del mes y calcula cuánto se gastó y cuánto queda. Las compras las vigilan los triggers de presupuesto.', params=[campo('p_anio','Año','number'), campo('p_mes','Mes (1-12)','number'), campo('p_monto','Presupuesto (Bs)','number')]),
 'reubicar_descarga': dict(routine='c_reubicar_descarga_botadero', titulo='Descargar con reubicación automática', descripcion='Si el botadero del camión está lleno, un cursor busca otro con espacio y descarga allí.', params=[identificador('p_idTransporte','TRANSPORTE','Transporte'), campo('p_kg','Peso a descargar (kg)','number')]),
}

CURSORES = {
 'zonas': dict(routine='c_reporte_zonas_vias_contenedores', titulo='Zonas, vías y contenedores', descripcion='Cobertura por zona y cantidad recolectada.', params=periodo()),
 'rutas': dict(routine='c_reporte_rutas_contenedores', titulo='Rutas y contenedores', descripcion='Recorridos y cobertura por ruta.', params=periodo()),
 'botaderos': dict(routine='c_reporte_botaderos_descargas', titulo='Botaderos y descargas', descripcion='Transporte, descargas y cantidades acumuladas.', params=periodo()),
 'personal': dict(routine='c_reporte_personal_jornadas', titulo='Personal y jornadas', descripcion='Asignaciones y actividad de recolectores.', params=periodo()),
 'materiales': dict(routine='c_reporte_materiales_movimientos', titulo='Materiales y movimientos', descripcion='Compras, entregas y devoluciones.', params=periodo()),
 'botaderos_riesgo': dict(routine='c_revisar_botaderos', titulo='Botaderos en riesgo', descripcion='Recorre los botaderos y lista los que están en advertencia, crítico o saturados.', params=[]),
 'camion': dict(routine='c_reporte_camion', titulo='Reporte de un camión', descripcion='Placa, conductor, ayudantes, material entregado y recorridos del camión.', params=[campo('p_placa','Placa del camión')]),
 'plan_compra': dict(routine='c_plan_compra_materiales', titulo='Plan de compra según presupuesto', descripcion='Compara lo gastado con el presupuesto del mes y sugiere qué comprar.', params=[campo('p_anio','Año','number'), campo('p_mes','Mes (1-12)','number')]),
}

TRIGGERS = ['trg_01_validar_recoleccion','trg_02_validar_integra','trg_03_validar_entrega_material','trg_04_validar_descarga','trg_05_validar_devolucion',
 'trg_validar_capacidad_botadero','trg_alerta_ocupacion_botadero','trg_control_presupuesto_material','trg_alerta_presupuesto_material',
 'trg_control_operativo_recoleccion','trg_bloquear_jornada_cerrada','trg_bloquear_jornada_cerrada_bu','trg_bloquear_jornada_cerrada_bd']
TABLAS = {
 'ZONA':'idZona', 'BOTADERO':'idBotadero','PERSONA':'idPersona', 'MATERIAL_TRABAJO':'idMaterial',
 'VIA':'idVia','CONTENEDOR':'idContenedor','CONDUCTOR':'idconductor','TRANSPORTE':'idTransporte',
 'RUTA':'idRuta','RECOLECTOR':'idrecolector','DISPONE':'fecha DESC, idPersona',
 'RECOLECTA':'fecha DESC, idRecoleccion DESC','PASA_POR':'fecha DESC, idTransporte',
 'INTEGRA':'idRuta, idVia','TRABAJA':'fecha DESC, idrecolector',
 'COMPRA_MATERIAL':'idCompra DESC','DEVOLUCION_MATERIAL':'idDEvolucion DESC',
 'DESCARGA_BOTADERO':'idDescarga DESC','HISTORIAL_ASIGNACION':'idHistorial DESC',
 'ALERTA_SISTEMA':'idAlerta DESC','PRESUPUESTO_MATERIAL':'anio DESC, mes DESC',
 'CIERRE_JORNADA':'idCierre DESC','AUDITORIA_RECOLECCION':'idAuditoria DESC'
}


def catalogo_publico():
    items=[]
    for kind, grupo, metodo, ruta in [
        ('procedimiento',PROCEDIMIENTOS,'POST','/procedimientos'),
        ('funcion',FUNCIONES,'GET','/funciones'),
        ('cursor',CURSORES,'GET','/cursores')]:
        for key,d in grupo.items():
            items.append(dict(key=key,kind=kind,metodo=metodo,ruta=f'{ruta}/{key}', **d))
    return items
