"""Puente hacia procedimientos, funciones y cursores que viven en MySQL."""
from datetime import date

from fastapi import APIRouter, HTTPException, Request

from .. import catalogo
from ..db import call_function, call_procedure, execute, fetch_one

router = APIRouter(tags=["Logica en la BD"])


def _definicion(grupo: dict, key: str) -> dict:
    if key not in grupo:
        raise HTTPException(404, f"'{key}' no esta en app/catalogo.py")
    return grupo[key]


def _valores(definicion: dict, datos: dict) -> list:
    """Ordena y valida los parametros segun el catalogo."""
    valores = []
    for prm in definicion["params"]:
        v = datos.get(prm["name"])
        if v is None or v == "":
            if prm["requerido"]:
                raise HTTPException(422, f"Falta el parametro '{prm['label']}'")
            valores.append(None)
            continue
        try:
            if prm["tipo"] == "number":
                v = float(v) if "." in str(v) else int(v)
            elif prm["tipo"] == "date":
                v = date.fromisoformat(str(v)).isoformat()
        except ValueError:
            raise HTTPException(422, f"'{prm['label']}' tiene un formato invalido") from None
        valores.append(v)
    return valores


@router.get("/logica/catalogo")
def ver_catalogo():
    return catalogo.catalogo_publico()


@router.post("/procedimientos/{key}")
async def ejecutar_procedimiento(key: str, request: Request):
    d = _definicion(catalogo.PROCEDIMIENTOS, key)
    datos = await request.json()
    conjuntos = call_procedure(d["routine"], _valores(d, datos))
    return {"routine": d["routine"], "resultados": conjuntos}


@router.get("/funciones/{key}")
def ejecutar_funcion(key: str, request: Request):
    d = _definicion(catalogo.FUNCIONES, key)
    resultado = call_function(d["routine"], _valores(d, dict(request.query_params)))
    return {"routine": d["routine"], "resultado": resultado}


@router.get("/cursores/{key}")
def ejecutar_cursor(key: str):
    d = _definicion(catalogo.CURSORES, key)
    return {"routine": d["routine"], "resultados": call_procedure(d["routine"], [])}


@router.post("/dml/{key}")
async def ejecutar_dml(key: str, request: Request):
    d = _definicion(catalogo.DML, key)
    datos = await request.json()
    id_material, precio = _valores(d, datos)
    if not fetch_one("SELECT 1 AS x FROM MATERIAL_TRABAJO WHERE idMaterial = %s", (id_material,)):
        raise HTTPException(404, f"No existe el material {id_material}")
    execute("UPDATE MATERIAL_TRABAJO SET precio = %s WHERE idMaterial = %s", (precio, id_material))
    return {"ok": True, "idMaterial": id_material, "precio": precio}
