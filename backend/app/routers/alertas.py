"""Alertas generadas por triggers y procedimientos (tabla ALERTA_SISTEMA).

Un trigger no puede abrir una ventana: deja una fila en ALERTA_SISTEMA y el frontend
consulta este endpoint. Los rechazos (SIGNAL) no pasan por aqui: llegan como error 400.
"""
from fastapi import APIRouter, HTTPException, Query

from ..db import execute, fetch_all, fetch_one

router = APIRouter(prefix="/alertas", tags=["Alertas"])


@router.get("")
def listar_alertas(pendientes: bool = True, limit: int = Query(20, ge=1, le=200)):
    donde = "WHERE leida = 0" if pendientes else ""
    filas = fetch_all(
        "SELECT idAlerta, tipo, idReferencia, nivel, mensaje, leida, fecha_hora "
        f"FROM ALERTA_SISTEMA {donde} ORDER BY idAlerta DESC LIMIT %s",
        (limit,),
    )
    total = fetch_one("SELECT COUNT(*) AS n FROM ALERTA_SISTEMA WHERE leida = 0")["n"]
    return {"pendientes": total, "alertas": filas}


@router.post("/leer_todas")
def marcar_todas():
    return {"ok": True, "marcadas": execute("UPDATE ALERTA_SISTEMA SET leida = 1 WHERE leida = 0")}


@router.post("/{id_alerta}/leer")
def marcar_leida(id_alerta: int):
    if not fetch_one("SELECT 1 AS x FROM ALERTA_SISTEMA WHERE idAlerta = %s", (id_alerta,)):
        raise HTTPException(404, f"No existe la alerta {id_alerta}")
    execute("UPDATE ALERTA_SISTEMA SET leida = 1 WHERE idAlerta = %s", (id_alerta,))
    return {"ok": True, "idAlerta": id_alerta}
