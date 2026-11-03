"""
Catalogo de la logica que vive en la BD (capa 2 del modelo navegacional).

>>> Si tu procedimiento/funcion tiene otros parametros, EDITA SOLO ESTE ARCHIVO.
    El frontend arma los formularios leyendo este catalogo (GET /logica/catalogo).

tipo de parametro: "text" | "number" | "date"
"""

import re

def p(name: str, label: str, tipo: str = "text", requerido: bool = True) -> dict:
    return {"name": name, "label": label, "tipo": tipo, "requerido": requerido}


# ---- Procedimientos (escritura) -> POST /procedimientos/{key} -------------
PROCEDIMIENTOS = {
    "registrar_persona": {
        "routine": "p_registrar_persona",
        "titulo": "Registrar persona",
        "descripcion": "SAVEPOINT, valida edad, sexo, turno y CI unico.",
        "params": [
            p("p_ci", "CI"), p("p_nombre", "Nombre"), p("p_paterno", "Apellido paterno"),
            p("p_materno", "Apellido materno"), p("p_sexo", "Sexo (M/F)"),
            p("p_fecha_nacimiento", "Fecha de nacimiento", "date"),
            p("p_telefono", "Telefono"), p("p_direccion", "Direccion"),
            p("p_turno", "Turno (Manana/Tarde/Noche)"),
        ],
    },
    "registrar_conductor": {
        "routine": "p_registrar_conductor",
        "titulo": "Registrar conductor",
        "descripcion": "La persona ya debe existir (se busca por CI). Valida licencia.",
        "params": [
            p("p_ci", "CI de la persona"),
            p("p_nro_licencia", "Nro. de licencia"),
            p("p_categoria_licencia", "Categoria de licencia (A/B/C)"),
        ],
    },
    "registrar_zona": {
        "routine": "p_registrar_zona",
        "titulo": "Registrar zona",
        "descripcion": "Valida nombre unico, ubicacion y cantidad de calles.",
        "params": [
            p("p_nombre", "Nombre de la zona"),
            p("p_ubicacion", "Ubicacion"),
            p("p_cantidad_calles", "Cantidad de calles", "number"),
        ],
    },
    "registrar_via": {
        "routine": "p_registrar_via",
        "titulo": "Registrar via",
        "descripcion": "La zona debe existir. Tipo: Calle o Avenida.",
        "params": [
            p("p_descripcion", "Descripcion"),
            p("p_calle_avenida", "Tipo (Calle/Avenida)"),
            p("p_idZona", "ID zona", "number"),
        ],
    },
    "registrar_contenedor": {
        "routine": "p_registrar_contenedor",
        "titulo": "Registrar contenedor",
        "descripcion": "La via debe existir. Tamanio: Pequeno, Mediano o Grande.",
        "params": [
            p("p_tipo", "Tipo (ej. Organico (verde))"),
            p("p_capacidad", "Capacidad (ej. 240 L)"),
            p("p_tamanio", "Tamanio (Pequeno/Mediano/Grande)"),
            p("p_idVia", "ID via", "number"),
        ],
    },
    "eliminar_zona_segura": {
        "routine": "p_eliminar_zona_segura",
        "titulo": "Eliminar zona (segura)",
        "descripcion": "Solo elimina la zona si no tiene vias, rutas, trabajos, contenedores ni recolectas.",
        "params": [p("p_idZona", "ID zona", "number")],
    },
    "registrar_recolector": {
        "routine": "p_registrar_recolector",
        "titulo": "Registrar recolector",
        "descripcion": "La persona ya debe existir (se busca por CI). El transporte debe estar operativo.",
        "params": [
            p("p_ci", "CI de la persona"),
            p("p_tipo_empleado", "Tipo (Recolector/Cargador/Ayudante de recoleccion)"),
            p("p_sueldo", "Sueldo", "number"),
            p("p_idTransporte", "ID transporte", "number"),
        ],
    },
    "asignar_transporte_ruta": {
        "routine": "p_asignar_transporte_ruta",
        "titulo": "Asignar transporte a ruta",
        "descripcion": "Maximo 3 rutas por dia. Modo ASIGNAR o REASIGNAR.",
        "params": [
            p("p_idTransporte", "ID transporte", "number"), p("p_idRuta", "ID ruta", "number"),
            p("p_fecha", "Fecha", "date"), p("p_modo", "Modo (ASIGNAR / REASIGNAR)"),
        ],
    },
    "registrar_recoleccion": {
        "routine": "p_registrar_recoleccion",
        "titulo": "Registrar recoleccion",
        "descripcion": "Valida TRABAJA y transporte activo; devuelve el total del dia.",
        "params": [
            p("p_idrecolector", "ID recolector", "number"), p("p_idContenedor", "ID contenedor", "number"),
            p("p_fecha", "Fecha", "date"), p("p_modo", "Modo (REGISTRAR / REASIGNAR)"),
        ],
    },
    "reasignar_recolector_transporte": {
        "routine": "p_reasignar_recolector_transporte",
        "titulo": "Reasignar recolector a otro transporte",
        "descripcion": "Valida transporte activo y capacidad. Graba HISTORIAL_ASIGNACION_RECOLECTOR.",
        "params": [
            p("p_idrecolector", "ID recolector", "number"),
            p("p_idTransporte_nuevo", "ID transporte nuevo", "number"),
            p("p_motivo", "Motivo", "text", False),
        ],
    },
    "eliminar_zona_segura": {
        "routine": "p_eliminar_zona_segura",
        "titulo": "Eliminar zona (segura)",
        "descripcion": "SQL dinamico: revisa VIA, RUTA, TRABAJA, CONTENEDOR y RECOLECTA antes de borrar.",
        "params": [p("p_idZona", "ID zona", "number")],
    },
}

# ---- Funciones (solo lectura) -> GET /funciones/{key}?param=valor ----------
FUNCIONES = {
    "capacidad_total_botadero": {
        "routine": "f_capacidad_total_botadero",
        "titulo": "Capacidad total de un botadero",
        "descripcion": "Solo transportes activos y rutas del dia.",
        "params": [p("p_idBotadero", "ID botadero", "number")],
    },
    "recolectas_por_recolector": {
        "routine": "f_recolectas_por_recolector",
        "titulo": "Recolectas por recolector",
        "descripcion": "Rango de fechas opcional.",
        "params": [
            p("p_idrecolector", "ID recolector", "number"),
            p("p_desde", "Desde", "date", False), p("p_hasta", "Hasta", "date", False),
        ],
    },
    "costo_materiales_persona": {
        "routine": "f_costo_materiales_persona",
        "titulo": "Costo de materiales de una persona",
        "descripcion": "Precio vigente, cruza HISTORIAL_PRECIO_MATERIAL.",
        "params": [p("p_idPersona", "ID persona", "number")],
    },
    "estado_operativo_transporte": {
        "routine": "f_estado_operativo_transporte",
        "titulo": "Estado operativo de un transporte",
        "descripcion": "Diagnostico: estado, conductor, licencia, recolectores, rutas.",
        "params": [p("p_idTransporte", "ID transporte", "number")],
    },
    "cobertura_zona": {
        "routine": "f_cobertura_zona",
        "titulo": "Cobertura de una zona",
        "descripcion": "% de contenedores recolectados. NULL si no hay contenedores.",
        "params": [
            p("p_idZona", "ID zona", "number"),
            p("p_desde", "Desde", "date", False), p("p_hasta", "Hasta", "date", False),
        ],
    },
}

# ---- Cursores anidados (reporting) -> GET /cursores/{key} ------------------
# En MySQL un cursor vive dentro de un procedimiento: aqui se espera un
# procedimiento sin parametros que termine devolviendo uno o varios SELECT.
CURSORES = {
    "zonas_y_sus_vias": {
        "routine": "c_zonas_y_sus_vias",
        "titulo": "Zonas y sus vias",
        "descripcion": "Zona -> vias.",
        "params": [],
    },
    "rutas_y_sus_contenedores": {
        "routine": "c_rutas_y_sus_contenedores",
        "titulo": "Rutas y sus contenedores",
        "descripcion": "Ruta -> contenedores (INTEGRA).",
        "params": [],
    },
    "botaderos_y_sus_transportes": {
        "routine": "c_botaderos_y_sus_transportes",
        "titulo": "Botaderos y sus transportes",
        "descripcion": "Botadero -> transportes.",
        "params": [],
    },
    "recolectores_y_sus_trabajos": {
        "routine": "c_recolectores_y_sus_trabajos",
        "titulo": "Recolectores y sus trabajos",
        "descripcion": "Recolector -> zona/fecha (TRABAJA) -> contenedores, cobertura, f_recolectas.",
        "params": [],
    },
}

# ---- DML directo (dispara triggers) -> POST /dml/{key} --------------------
DML = {
    "actualizar_precio_material": {
        "titulo": "Cambiar precio de un material",
        "descripcion": "UPDATE directo: dispara trg_validar_precio_material (historial y limite de subida).",
        "params": [p("idMaterial", "ID material", "number"), p("precio", "Nuevo precio", "number")],
    },
}

# ---- Triggers que se espera encontrar (solo para el diagnostico) ----------
TRIGGERS = [
    "trg_validar_transporte_activo",
    "trg_auditar_recoleccion",
    "trg_validar_precio_material",
    "trg_validar_contenedor",
    "trg_control_horario_ruta",
]

# ---- Tablas ya con su orden por defecto ------------------------------------
TABLAS = {
    "PERSONA": "idPersona", "CONDUCTOR": "idconductor", "RECOLECTOR": "idrecolector",
    "TRANSPORTE": "idTransporte", "BOTADERO": "idBotadero", "ZONA": "idZona",
    "VIA": "idVia", "RUTA": "idRuta", "CONTENEDOR": "idContenedor",
    "MATERIAL_TRABAJO": "idMaterial",
    "DISPONE": "fecha DESC, idPersona", "RECOLECTA": "fecha DESC, idrecolector",
    "PASA_POR": "fecha DESC, idTransporte", "INTEGRA": "idRuta, idVia, idContenedor",
    "TRABAJA": "fecha DESC, idrecolector",
    "AUDITORIA_RECOLECCION": "idAuditoria DESC",
    "HISTORIAL_PRECIO_MATERIAL": "idHistorial DESC",
    "HISTORIAL_ASIGNACION_RECOLECTOR": "idHistorial DESC",
}


_TIPOS_NUMERICOS = {"int", "bigint", "smallint", "tinyint", "mediumint", "decimal", "float", "double"}
 
 
def _etiqueta(nombre: str) -> str:
    """p_idZona -> 'ID zona'; p_idrecolector -> 'ID recolector'; p_fecha_inicio -> 'Fecha inicio'."""
    n = re.sub(r"^p_", "", nombre)
    n = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", n).replace("_", " ").lower()
    if n.startswith("id "):
        return "ID " + n[3:]
    if re.match(r"^id[a-z]", n):
        return "ID " + n[2:]
    return n.capitalize()
 
 
def _firmas_en_bd(rutina: str | None = None) -> dict[str, list[dict]]:
    """{nombre_rutina: [{'nombre':..., 'tipo':...}, ...]} leido de information_schema."""
    from .db import fetch_all  # import local: este modulo se carga antes que la BD
 
    sql = (
        "SELECT SPECIFIC_NAME AS rutina, PARAMETER_NAME AS nombre, DATA_TYPE AS tipo "
        "FROM information_schema.PARAMETERS "
        "WHERE SPECIFIC_SCHEMA = DATABASE() AND ORDINAL_POSITION > 0 "
        "AND (PARAMETER_MODE IS NULL OR PARAMETER_MODE = 'IN')"
    )
    args: tuple = ()
    if rutina:
        sql += " AND SPECIFIC_NAME = %s"
        args = (rutina,)
    firmas: dict[str, list[dict]] = {}
    for f in fetch_all(sql + " ORDER BY SPECIFIC_NAME, ORDINAL_POSITION", args):
        firmas.setdefault(f["rutina"].lower(), []).append({"nombre": f["nombre"], "tipo": f["tipo"]})
    return firmas
 
 
def sincronizar_params(d: dict, firmas: dict | None = None) -> None:
    """Deja d['params'] igual a la firma real de la rutina en MySQL (si ya existe)."""
    rutina = d.get("routine")
    if not rutina:
        return
    try:
        if firmas is None:
            firmas = _firmas_en_bd(rutina)
    except Exception:  # noqa: BLE001  (BD caida: se queda lo escrito a mano)
        return
    reales = firmas.get(rutina.lower())
    if not reales:  # la rutina aun no existe en la BD, o no tiene parametros
        return
    previos = {x["name"].lower(): x for x in d["params"]}
    d["params"] = [
        {
            "name": r["nombre"],
            "label": previos[r["nombre"].lower()]["label"] if r["nombre"].lower() in previos else _etiqueta(r["nombre"]),
            "tipo": "number" if r["tipo"] in _TIPOS_NUMERICOS else "date" if r["tipo"] == "date" else "text",
            "requerido": previos[r["nombre"].lower()]["requerido"] if r["nombre"].lower() in previos else True,
        }
        for r in reales
    ]
 
 
def catalogo_publico() -> list[dict]:
    """Lista plana que consume el frontend (con los parametros reales de la BD)."""
    try:
        firmas = _firmas_en_bd()
    except Exception:  # noqa: BLE001
        firmas = {}
    items = []
    for kind, grupo, metodo, base in [
        ("procedimiento", PROCEDIMIENTOS, "POST", "/procedimientos"),
        ("funcion", FUNCIONES, "GET", "/funciones"),
        ("cursor", CURSORES, "GET", "/cursores"),
        ("dml", DML, "POST", "/dml"),
    ]:
        for key, d in grupo.items():
            sincronizar_params(d, firmas)  # tambien actualiza d, que usa logica.py al ejecutar
            items.append({
                "key": key, "kind": kind, "metodo": metodo, "ruta": f"{base}/{key}",
                "routine": d.get("routine"), "titulo": d["titulo"],
                "descripcion": d["descripcion"], "params": d["params"],
            })
    return items
