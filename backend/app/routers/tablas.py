"""Lectura generica de tablas (solo las del catalogo)."""
from fastapi import APIRouter, HTTPException, Query

from .. import catalogo
from ..db import fetch_all, fetch_one

router = APIRouter(prefix="/tablas", tags=["Tablas"])


@router.get("")
def listar_tablas():
    return list(catalogo.TABLAS)


@router.get("/{nombre}")
def leer_tabla(nombre: str, limit: int = Query(50, ge=1, le=500), offset: int = Query(0, ge=0)):
    tabla = nombre.upper()
    if tabla not in catalogo.TABLAS:  # lista blanca: evita inyeccion por nombre de tabla
        raise HTTPException(404, f"Tabla '{nombre}' no permitida")
    orden = catalogo.TABLAS[tabla]
    total = fetch_one(f"SELECT COUNT(*) AS n FROM `{tabla}`")["n"]
    filas = fetch_all(f"SELECT * FROM `{tabla}` ORDER BY {orden} LIMIT %s OFFSET %s", (limit, offset))
    return {"tabla": tabla, "total": total, "limit": limit, "offset": offset, "filas": filas}
