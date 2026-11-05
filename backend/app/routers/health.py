"""Pruebas de conexion y diagnostico de lo que ya existe en la BD."""
from fastapi import APIRouter

from .. import catalogo
from ..db import fetch_all, fetch_one
from ..instalacion import LAST_STATUS

router = APIRouter(tags=["Diagnostico BD"])


@router.get("/health")
def health():
    fila = fetch_one("SELECT VERSION() AS version, DATABASE() AS base, CURRENT_USER() AS usuario")
    return {"estado": "ok", **fila}


@router.get("/db/tables")
def tablas_existentes():
    existentes = {
        r["TABLE_NAME"].upper()
        for r in fetch_all(
            "SELECT TABLE_NAME FROM information_schema.TABLES "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'"
        )
    }
    resultado = []
    for nombre in catalogo.TABLAS:
        if nombre in existentes:
            filas = fetch_one(f"SELECT COUNT(*) AS n FROM `{nombre}`")["n"]
            resultado.append({"tabla": nombre, "existe": True, "filas": filas})
        else:
            resultado.append({"tabla": nombre, "existe": False, "filas": None})
    return resultado


@router.get("/db/routines")
def rutinas_existentes():
    rutinas = {
        r["ROUTINE_NAME"].lower()
        for r in fetch_all(
            "SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE()"
        )
    }
    triggers = {
        r["TRIGGER_NAME"].lower()
        for r in fetch_all(
            "SELECT TRIGGER_NAME FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE()"
        )
    }
    resultado = []
    for item in catalogo.catalogo_publico():
        if item["routine"]:
            resultado.append({"nombre": item["routine"], "tipo": item["kind"],
                              "existe": item["routine"].lower() in rutinas})
    for t in catalogo.TRIGGERS:
        resultado.append({"nombre": t, "tipo": "trigger", "existe": t.lower() in triggers})
    return resultado


@router.get("/db/test")
def prueba_bd():
    """Resumen rapido: conexion, tablas y logica que ya esta creada."""
    checks = []
    try:
        info = health()
        checks.append({"prueba": "Conexion a MySQL", "ok": True, "detalle": f"MySQL {info['version']}"})
    except Exception as e:  # noqa: BLE001
        return [{"prueba": "Conexion a MySQL", "ok": False, "detalle": str(e)}]

    tablas = tablas_existentes()
    faltan = [t["tabla"] for t in tablas if not t["existe"]]
    checks.append({"prueba": f"Tablas ({len(tablas) - len(faltan)}/{len(tablas)})",
                   "ok": not faltan, "detalle": "Todas existen" if not faltan else "Faltan: " + ", ".join(faltan)})
    vacias = [t["tabla"] for t in tablas if t["existe"] and t["filas"] == 0
              and not t["tabla"].startswith(("AUDITORIA", "HISTORIAL", "ALERTA", "CIERRE"))]
    checks.append({"prueba": "Datos cargados", "ok": not vacias,
                   "detalle": "Con filas" if not vacias else "Vacias: " + ", ".join(vacias)})

    rutinas = rutinas_existentes()
    for tipo, etiqueta in [("procedimiento", "Procedimientos"), ("funcion", "Funciones"),
                           ("cursor", "Cursores"), ("trigger", "Triggers")]:
        grupo = [r for r in rutinas if r["tipo"] == tipo]
        ok = [r["nombre"] for r in grupo if r["existe"]]
        falta = [r["nombre"] for r in grupo if not r["existe"]]
        checks.append({"prueba": f"{etiqueta} ({len(ok)}/{len(grupo)})", "ok": not falta,
                       "detalle": "Todos creados" if not falta else "Pendientes: " + ", ".join(falta)})
    return checks


@router.get("/db/instalacion")
def estado_instalacion():
    return LAST_STATUS

@router.get('/db/datos')
def diagnostico_datos():
    """El esquema puede existir aunque no haya sido cargado el INSERT inicial."""
    tablas = {x['tabla']: x for x in tablas_existentes()}
    fundamentales = ('ZONA', 'PERSONA', 'RECOLECTA', 'DESCARGA_BOTADERO')
    faltantes = [t for t in fundamentales if not tablas[t]['existe']]
    vacias = [t for t in fundamentales if tablas[t]['existe'] and tablas[t]['filas'] == 0]
    fechas = None
    if 'RECOLECTA' not in faltantes:
        fechas = fetch_one('SELECT MIN(fecha) AS desde, MAX(fecha) AS hasta FROM RECOLECTA')
    return {'tablas_base': {t: tablas[t]['filas'] for t in fundamentales},
            'faltantes': faltantes, 'vacias': vacias,
            'fechas_recoleccion': fechas,
            'nota': ('La inicialización de Docker se ejecuta solo si el volumen MySQL está vacío. '
                     'No borres el volumen si contiene información que quieras conservar.')}
